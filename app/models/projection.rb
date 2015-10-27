class Projection < ActiveRecord::Base
  belongs_to :player, foreign_key: "player_id"

  def self.refresh_data(platform="fanduel", week=nil)
    Projection.populate_data(platform, week) if Projection.any_refresh?(platform, week)
  end

  def self.freshness
    max = Projection.maximum("updated_at")
    max ? max  : nil
  end

  def self.optimal_lineup(platform, week=nil)
    #Setup
    league_info = FFNerd.daily_fantasy_league_info(platform)
    week = league_info.current_week unless week
    players = Player.joins(:projections).
                     where(projections: {week: week, platform: platform}).
                     select("projections.*,players.*").
                     order(:position, :id)
    return [] if players.empty? #abort if no data

    #Init solver
    lp_solver = init_solver(league_info)
    lp_solver = Projection.create_is_in_lineup_variables(players, lp_solver)

    #Setup objective function (max projections)
    objective_coefs = []
    players.each {|player| objective_coefs.push(player.average) }
    lp_solver.obj.coefs = objective_coefs

    #Put all constraint coefficients into solver
    matrix = Projection.construct_constraint_coefs(players, league_info)
    lp_solver.set_matrix(matrix)

    #Solve!
    lp_solver.simplex
    lp_solver.mip
    lineup_ids = []
    lp_solver.cols.each { |col| lineup_ids.push(col.name.to_i) if col.mip_val == 1 }
    lineup_ids
  end

  def refresh?
    updated_at && updated_at > 60.minutes.ago ? false : true
  end

  private
  def self.populate_data(platform, week=nil)
    week = FFNerd.daily_fantasy_league_info(platform).current_week unless week

    ActiveRecord::Base.transaction do
      Projection.delete_all("platform = '#{platform}' AND week = '#{week}'")
      FFNerd.daily_fantasy_projections(platform).each do |proj|
        avg = proj.projections["consensus"]["projected_points"]
        max = proj.projections["aggressive"]["projected_points"]
        min = proj.projections["conservative"]["projected_points"]

        Projection.create(average: avg, week: week, platform: platform, salary: proj.salary,
                          player_id: proj.player_id, average: avg, min: min, max: max)
      end
    end
  end

  def self.any_refresh?(platform, week=nil)
    week = FFNerd.daily_fantasy_league_info(platform).current_week unless week
    records = Projection.where("platform = '#{platform}' AND week = '#{week}'")
    records.each do |proj|
      return true if proj.refresh?
    end

    #refresh if no records
    records.any? ? false : true
  end

  #Setup cost/position constraint coefficients (lhs)
  def self.construct_constraint_coefs(players, league_info)
    position_coefs = Hash.new
    position_flex_coefs = Hash.new
    cost_coefs = []
    all_flex_coefs = []

    players.each_with_index do |player, j|
      cost_coefs.push(player.salary)
      league_info.roster_requirements.each_with_index do |roster, i|
        if roster.second > 0
          #First for min constraint
          position_coefs[roster.first] = [] if j == 0
          position_coefs[roster.first].push(player.position == roster.first ? 1 : 0)

          #Second for max constraint (flex possibility)
          position_flex_coefs[roster.first] = [] if j == 0
          position_flex_coefs[roster.first].push(player.position == roster.first ? 1 : 0)
        end
      end
      all_flex_coefs.push(["RB","WR","TE"].include?(player.position) ? 1 : 0)
    end

    constraint_matrix = [cost_coefs]
    position_coefs.zip position_flex_coefs do |position, flex_position|
      constraint_matrix = [constraint_matrix, position.second]
      constraint_matrix = [constraint_matrix, flex_position.second]
    end
    constraint_matrix = [constraint_matrix, all_flex_coefs]
    constraint_matrix.flatten

  end

  #Setup the constraint functions (rhs)
  def self.init_solver(league_info)
    lp_solver = Rglpk::Problem.new
    lp_solver.obj.dir = Rglpk::GLP_MAX
    is_flex = !!league_info.roster_requirements["FLEX"]
    num_flex = league_info.roster_requirements["FLEX"]
    total_flexable_slots = num_flex

    #Cost row
    row = lp_solver.add_row
    row.name = "cost_constraint"
    row.set_bounds(Rglpk::GLP_UP, 0, league_info.cap)

    league_info.roster_requirements.each do |roster|
      if roster.second > 0 && roster.first != "FLEX"
        #Add position minimum constraints rows
        row = lp_solver.add_row
        row.set_bounds(Rglpk::GLP_LO, roster.second, nil)
        row.name = roster.first.to_s + "_constraint"

        #Add position maximum constraints - adding in flex possibilities for RB, WR, and TE
        row = lp_solver.add_row
        flex_add = is_flex && ["RB","WR","TE"].include?(roster.first) ? num_flex : 0
        row.set_bounds(Rglpk::GLP_UP, nil, roster.second + flex_add)
        row.name = roster.first.to_s + "_constraint_flex"

        #Keep count of number of total slots to fill
        total_flexable_slots += roster.second if ["RB","WR","TE"].include?(roster.first)
      end
    end

    #Add total position requirements
    row = lp_solver.add_row
    row.name = "num_flexable_constraint"
    row.set_bounds(Rglpk::GLP_FX, total_flexable_slots, total_flexable_slots)

    lp_solver
  end

  #Create a binary 0 or 1 variable for each player,
  # indicating if they are in the lineup or not
  def self.create_is_in_lineup_variables(players, lp_solver)
    cols = lp_solver.add_cols(players.length)
    players.each_with_index do |player, i|
      if player.projections.any?
        cols[i].name = player.id.to_s
        cols[i].kind = Rglpk::GLP_BV
      end
    end
    lp_solver
  end
end

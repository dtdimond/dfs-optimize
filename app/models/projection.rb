class Projection < ActiveRecord::Base
  belongs_to :player, foreign_key: "player_id"

  def self.refresh_data(platform="fanduel")
    Projection.populate_data(platform) if Projection.any_refresh?(platform)
  end

  def self.freshness
    max = Projection.maximum("updated_at")
    max ? max  : nil
  end

  def self.optimal_lineup(platform)
    #Setup
    league_info = FFNerd.daily_fantasy_league_info("fanduel")
    lp_solver = init_solver(league_info)

    #Get all players for the appropriate week/dfs site
    players = Player.joins(:projections).
                     where(projections: {week: league_info.current_week, platform: platform}).
                     select("projections.*,players.*").
                     order(:position, :id)
    return [] if players.empty? #abort if no data

    #Create a binary 0 or 1 variable for each player,
    # indicating if they are in the lineup or not
    cols = lp_solver.add_cols(players.length)
    players.each_with_index do |player, i|
      if player.projections.any?
        cols[i].name = player.id.to_s
        cols[i].set_bounds(Rglpk::GLP_DB, 0, 1)
        cols[i].kind = Rglpk::GLP_BV
      end
    end

    #Setup objective function (max projections)
    objective_coefs = []
    players.each do |player|
       objective_coefs.push(player.average)
    end
    lp_solver.obj.coefs = objective_coefs

    #Put all constraint coefficients into solver
    lp_solver.set_matrix(Projection.construct_constraint_coefs(players, league_info))

    #Solve!
    lp_solver.simplex
    lp_solver.mip
    proj_score = lp_solver.obj.get

    lineup_ids = []
    lp_solver.cols.each do |col|
      lineup_ids.push(col.name.to_i) if col.mip_val == 1
    end

    lineup_ids
  end

  def refresh?
    updated_at && updated_at > 60.minutes.ago ? false : true
  end

  private
  def self.populate_data(platform)
    week = FFNerd.daily_fantasy_league_info(platform).current_week

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

  def self.any_refresh?(platform)
    records = Projection.where("platform = '#{platform}'")
    records.each do |proj|
      return true if proj.refresh?
    end

    #refresh if no records
    records.any? ? false : true
  end

  def self.construct_constraint_coefs(players, league_info)
    position_coefs = Hash.new
    cost_coef = []

    #Setup cost/position constraint coefficients
    players.each_with_index do |player, j|
      cost_coef.push(player.salary)
      league_info.roster_requirements.each_with_index do |roster, i|
        if roster.second > 0
          position_coefs[roster.first] = [] if j == 0
          position_coefs[roster.first].push(player.position == roster.first ? 1 : 0)
        end
      end
    end

    constraint_matrix = [cost_coef]
    position_coefs.each do |position|
      constraint_matrix = [constraint_matrix, position.second]
    end
    constraint_matrix.flatten

  end

  def self.init_solver(league_info)
    lp_solver = Rglpk::Problem.new
    lp_solver.obj.dir = Rglpk::GLP_MAX

    #Setup the constraint functions (rhs)
    # Cost constraint (salary_cap)
    # Num qbs, rbs, wrs, tes, ks, defs constraint (depending on platform)
    rows_length = 1 #start with cost constraint row
    league_info.roster_requirements.each do |roster|
      rows_length += 1 if roster.second > 0
    end

    rows = lp_solver.add_rows(rows_length)
    rows[0].set_bounds(Rglpk::GLP_UP, 0, league_info.cap)
    rows[0].name = "cost_constraint"

    league_info.roster_requirements.each_with_index do |roster, i|
      if roster.second > 0
        rows[i+1].set_bounds(Rglpk::GLP_DB, 0, roster.second)
        rows[i+1].name = roster.first.to_s + "_constraint"
      end
    end
    lp_solver
  end
end

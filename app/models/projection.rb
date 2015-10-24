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
    best = Rglpk::Problem.new
    best.obj.dir = Rglpk::GLP_MAX
    salary_cap = 60000
    num_qbs = 1; num_rbs = 2; num_wrs = 3; num_tes = 1; num_ks = 1; num_defs = 1

    #Setup the constraint functions (rhs)
    # Cost constraint (salary_cap)
    # Num qbs, rbs, wrs, tes, ks, defs constraint
    rows = best.add_rows(7)
    rows[0].name = "cost_constraint"
    rows[0].set_bounds(Rglpk::GLP_UP, 0, salary_cap)
    rows[1].name = "qb_constraint"
    rows[1].set_bounds(Rglpk::GLP_DB, 0, num_qbs)
    rows[2].name = "rb_constraint"
    rows[2].set_bounds(Rglpk::GLP_DB, 0, num_rbs)
    rows[3].name = "wr_constraint"
    rows[3].set_bounds(Rglpk::GLP_DB, 0, num_wrs)
    rows[4].name = "te_constraint"
    rows[4].set_bounds(Rglpk::GLP_DB, 0, num_tes)
    rows[5].name = "k_constraint"
    rows[5].set_bounds(Rglpk::GLP_DB, 0, num_ks)
    rows[6].name = "def_constraint"
    rows[6].set_bounds(Rglpk::GLP_DB, 0, num_defs)

    #Get all players for the appropriate week/dfs site
    players = Player.joins(:projections).
                     where(projections: { week: FFNerd.current_week, platform: platform }).
                     select("projections.*,players.*").
                     order(:position, :id)

    #Create a binary 0 or 1 variable for each player,
    # indicating if they are in the lineup or not
    cols = best.add_cols(Player.count)
    players.each_with_index do |player, i|
      cols[i].name = player.id.to_s
      cols[i].set_bounds(Rglpk::GLP_DB, 0, 1)
      cols[i].kind = Rglpk::GLP_BV
    end

    #Setup objective function (max projections)
    objective_coefs = []
    players.each do |player|
       objective_coefs.push(player.average)
    end
    best.obj.coefs = objective_coefs

    ####### CONSTRAINT COEFS #########
    cost_coef = []; qb_coef = []; rb_coef = [];
    wr_coef = []; te_coef = []; k_coef = []; def_coef = [];

    #Setup cost constraint coefficients
    players.each do |player|
      cost_coef.push(player.salary)
      qb_coef.push(player.position == "QB" ? 1 : 0)
      rb_coef.push(player.position == "RB" ? 1 : 0)
      wr_coef.push(player.position == "WR" ? 1 : 0)
      te_coef.push(player.position == "TE" ? 1 : 0)
      k_coef.push(player.position == "K" ? 1 : 0)
      def_coef.push(player.position == "DEF" ? 1 : 0)
    end

    constraint_matrix = [cost_coef, qb_coef, rb_coef, wr_coef, te_coef, k_coef, def_coef].zip.flatten

    #Put all constraint coefficients into solver
    best.set_matrix(constraint_matrix)

    #Solve!
    best.simplex
    best.mip
    proj_score = best.obj.get

    lineup_ids = []
    best.cols.each do |col|
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
      Projection.delete_all("platform = '#{platform}'")
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
end

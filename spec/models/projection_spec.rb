require 'spec_helper'

describe Projection do
  it { should belong_to(:player) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new proj data if an existing proj record is too old' do
      VCR.use_cassette 'projection/refresh_data' do
        Fabricate(:projection, platform: "fanduel",
                  week: FFNerd.daily_fantasy_league_info("fanduel").current_week,
                  updated_at: not_too_new)
        Fabricate(:projection, platform: "fanduel",
                  week: FFNerd.daily_fantasy_league_info("fanduel").current_week,
                  updated_at: too_new)
        Projection.refresh_data
      end

      expect(Projection.first.salary).to eq(8000)
      expect(Projection.first.week).to eq(4)
      expect(Projection.first.platform).to eq("fanduel")
      expect(Projection.first.player_id).to eq(35)
      expect(Projection.first.average).to eq(16.5)
    end

    it 'gets all new proj data if there are no records' do
      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data
      end

      expect(Projection.first.salary).to eq(8000)
      expect(Projection.first.week).to eq(4)
      expect(Projection.first.platform).to eq("fanduel")
      expect(Projection.first.player_id).to eq(35)
      expect(Projection.first.average).to eq(16.5)
    end

    it 'gets no new proj data if all existing proj records are too recent' do
      proj = Fabricate(:projection, platform: "fanduel", updated_at: too_new)
      Fabricate(:projection, platform: "fanduel", updated_at: too_new)

      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data(proj.platform, proj.week)
      end

      expect(Projection.first.average).to eq(proj.average)
      expect(Projection.third).to be_nil
    end

    it 'gets new proj data if a record is old enough, but for wrong platform' do
      Fabricate(:projection, platform: "draftkings", updated_at: not_too_new)

      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data
      end

      expect(Projection.second.average).to eq(16.5)
    end


    it 'only deletes records for the given platform on refresh' do
      Fabricate(:projection, platform: "draftkings", updated_at: too_new)

      VCR.use_cassette 'projection/refresh_data' do
        proj_fd = Fabricate(:projection, platform: "fanduel", updated_at: not_too_new,
                            week: FFNerd.daily_fantasy_league_info("fanduel").current_week)
        Projection.refresh_data("fanduel")

        expect(Projection.first.platform).to eq("draftkings")
        expect(Projection.second.updated_at).not_to be_near_to_time(proj_fd.updated_at, 30.seconds)
      end
    end
  end

  describe '.freshness' do

  end

  describe '.optimal_lineup' do
    it 'sets a lineup with the appropriate number of slots filled' do
      platform = "fanduel"
      VCR.use_cassette 'projection/optimal_lineup' do
        info = FFNerd.daily_fantasy_league_info(platform)
        create_players("QB" , rand(5) + 4, platform)
        create_players("RB" , rand(5) + 4, platform)
        create_players("WR" , rand(5) + 4, platform)
        create_players("TE" , rand(5) + 4, platform)
        create_players("K"  , rand(5) + 4, platform)
        create_players("DEF", rand(5) + 4, platform)
        lineup = Player.find(Projection.optimal_lineup(platform))

        info.roster_requirements.each do |requirements|
          position = requirements.first
          required_slots = requirements.second
          expect(lineup.select{|player| player.position == position}.count).to eq(required_slots)
        end
      end
    end

    it 'creates the optimal lineup for fanduel' do
      qb1 = create_player("QB", "fanduel", 16.5, 9000)
      qb2 = create_player("QB", "fanduel", 15.5, 5000)
      rb1 = create_player("RB", "fanduel", 10.5, 1000)
      rb2 = create_player("RB", "fanduel", 25.5, 9000)
      rb3 = create_player("RB", "fanduel", 15.5, 5000)
      wr1 = create_player("WR", "fanduel", 16.5, 9000)
      wr2 = create_player("WR", "fanduel", 10.5, 5000)
      wr3 = create_player("WR", "fanduel", 2.5, 2000)
      wr4 = create_player("WR", "fanduel", 12.5, 5000)
      te1 = create_player("TE", "fanduel", 16.5, 9000)
      te2 = create_player("TE", "fanduel", 0.5, 5000)
      k1 = create_player("K", "fanduel", 16.1, 5200)
      k2 = create_player("K", "fanduel", 16.1, 5000)
      def1 = create_player("DEF", "fanduel", 10.5, 5000)
      def2 = create_player("DEF", "fanduel", 10.4, 5000)

      VCR.use_cassette 'projection/optimal_lineup' do
        lineup = Player.find(Projection.optimal_lineup("fanduel"))
        should_be = [qb2, rb2, rb3, wr1, wr2, wr4, te1, k1, def1]
        expect(lineup).to eq(should_be)
      end
    end

#    it 'creates the optimal lineup for draftkings' do
#      qb1 = create_player("QB", "draftkings", 16.5, 9000)
#      qb2 = create_player("QB", "draftkings", 15.5, 5000)
#      rb1 = create_player("RB", "draftkings", 10.5, 1000)
#      rb2 = create_player("RB", "draftkings", 25.5, 9000)
#      rb3 = create_player("RB", "draftkings", 15.5, 5000)
#      wr1 = create_player("WR", "draftkings", 16.5, 9000)
#      wr2 = create_player("WR", "draftkings", 10.5, 5000)
#      wr3 = create_player("WR", "draftkings", 2.5, 2000)
#      wr4 = create_player("WR", "draftkings", 12.5, 5000)
#      te1 = create_player("TE", "draftkings", 16.5, 9000)
#      te2 = create_player("TE", "draftkings", 0.5, 5000)
#      def1 = create_player("DEF", "draftkings", 10.5, 5000)
#      def2 = create_player("DEF", "draftkings", 10.4, 5000)
#
#      VCR.use_cassette 'projection/optimal_lineup' do
#        lineup = Player.find(Projection.optimal_lineup("draftkings"))
#        should_be = [qb2, rb2, rb3, wr1, wr2, wr4, te1, k1, def1]
#        expect(lineup).to eq(should_be)
#      end
#    end

    it 'returns [] if there is no data' do
      VCR.use_cassette 'projection/optimal_lineup' do
        lineup = Player.find(Projection.optimal_lineup("fanduel"))
        expect(lineup).to eq([])
      end
    end
  end

  describe '.populate_data' do
    it 'populates the proj database' do
      VCR.use_cassette 'projection/populate_data' do
        Projection.populate_data("fanduel")
      end

      expect(Projection.first.average).to eq(16.5)
      expect(Projection.first.updated_at).to be_near_to_time(Time.now, 30.seconds)
    end
  end

  describe ".cache_refresh?" do
    it 'returns false if updated_at is less than 60mins old' do
      proj = Fabricate(:projection, updated_at: too_new)
      expect(proj.refresh?).to be false
    end

    it 'returns true if updated_at is greater than 60mins old' do
      proj = Fabricate(:projection, updated_at: not_too_new)
      expect(proj.refresh?).to be true
    end
  end

  describe ".construct_constraint_coefs" do
    #This gets a bit ugly. Basically we have an additional row for each position
    # constraint. This allows us to give a lower bound of num_players for that position
    # and an upper bound of num_players + num_flex to give the option of a flex player.
    it 'makes the appropriate constraint coefficients matrix' do
      VCR.use_cassette 'projection/constraint_coefs' do
        league_info = FFNerd.daily_fantasy_league_info("fanduel")
        qb1 = create_player("QB", "fanduel", 16.5, 9000)
        rb1 = create_player("RB", "fanduel", 15.5, 5000)
        players = Player.joins(:projections).
                     where(projections: { platform: "fanduel" }).
                     select("projections.*,players.*").
                     order(:position, :id)

        coefs_matrix = Projection.construct_constraint_coefs(players, league_info)
        salaries = [9000, 5000]; qbs = [1, 0]; rbs = [0, 1]; wrs = tes = ks = defs = [0, 0]
        qbs_flex = qbs; rbs_flex = rbs; wrs_flex = tes_flex = ks_flex = defs_flex = [0, 0]
        all_flex = [0, 1]
        expect(coefs_matrix).to eq(salaries + qbs + qbs_flex + rbs + rbs_flex + wrs +
                                   wrs_flex + tes + tes_flex + ks + ks_flex + defs +
                                   defs_flex + all_flex)
      end
    end
  end

  describe ".init_solver" do
    it 'initializes the solver and its rows for 0 flex positions (fanduel)' do
      VCR.use_cassette 'projection/constraint_coefs' do
        league_info = FFNerd.daily_fantasy_league_info("fanduel")
        lp_solver = Projection.init_solver(league_info)
        expect(lp_solver.rows.count).to eq(14)
        expect(lp_solver.rows.first.name).to eq("cost_constraint")
        expect(lp_solver.rows.first.bounds).to eq([Rglpk::GLP_UP, nil, 60000])
        expect(lp_solver.rows[5].name).to eq("WR_constraint")
        expect(lp_solver.rows[5].bounds).to eq([Rglpk::GLP_LO, 3, nil])
        expect(lp_solver.rows[6].name).to eq("WR_constraint_flex")
        expect(lp_solver.rows[6].bounds).to eq([Rglpk::GLP_UP, nil, 3])
        expect(lp_solver.rows[13].name).to eq("num_flexable_constraint")
        expect(lp_solver.rows[13].bounds).to eq([Rglpk::GLP_FX, 6, 6])
      end
    end

    it 'initializes the solver and its rows for 1 flex positions (draftkings)' do
      VCR.use_cassette 'projection/draftkings_league_info' do
        league_info = FFNerd.daily_fantasy_league_info("draftkings")
        lp_solver = Projection.init_solver(league_info)
        expect(lp_solver.rows.count).to eq(12)
        expect(lp_solver.rows.first.name).to eq("cost_constraint")
        expect(lp_solver.rows.first.bounds).to eq([Rglpk::GLP_UP, nil, 50000])
        expect(lp_solver.rows[5].name).to eq("WR_constraint")
        expect(lp_solver.rows[5].bounds).to eq([Rglpk::GLP_LO, 3, nil])
        expect(lp_solver.rows[6].name).to eq("WR_constraint_flex")
        expect(lp_solver.rows[6].bounds).to eq([Rglpk::GLP_UP, nil, 4])
        expect(lp_solver.rows[11].name).to eq("num_flexable_constraint")
        expect(lp_solver.rows[11].bounds).to eq([Rglpk::GLP_FX, 7, 7])
      end
    end
  end

  describe ".create_is_in_lineup_variables" do
    it 'creates the appropriate columns' do
      VCR.use_cassette 'projection/constraint_coefs' do
        league_info = FFNerd.daily_fantasy_league_info("fanduel")
        qb1 = create_player("QB", "fanduel", 16.5, 9000)
        rb1 = create_player("RB", "fanduel", 15.5, 5000)
        players = Player.joins(:projections).
                     where(projections: { platform: "fanduel" }).
                     select("projections.*,players.*").
                     order(:position, :id)
        solver = Projection.init_solver(league_info)
        solver = Projection.create_is_in_lineup_variables(players, solver)
        expect(solver.cols.count).to eq(2)

       end
    end
  end
end

def create_players(position, number, platform)
  for i in 0..number
    create_player(position, platform)
  end
end

def create_player(position, platform, average=nil, salary=nil)
  player = Fabricate(:player, position: position)

  VCR.use_cassette 'projection/current_week' do
    week = FFNerd.daily_fantasy_league_info(platform).current_week

    if salary && average
      Fabricate(:projection, player: player, week: week, platform: platform,
                salary: salary, average: average)
    else
      Fabricate(:projection, player: player, week: week, platform: platform)
    end
  end
  player
end

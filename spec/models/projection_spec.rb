require 'spec_helper'

describe Projection do
  it { should belong_to(:player) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new proj data if an existing proj record is too old' do
      Fabricate(:projection, platform: "fanduel", updated_at: not_too_new)
      Fabricate(:projection, platform: "fanduel", updated_at: too_new)

      VCR.use_cassette 'projection/refresh_data' do
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
        Projection.refresh_data
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
      proj_fd = Fabricate(:projection, platform: "fanduel", updated_at: not_too_new)

      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data("fanduel")
      end

      expect(Projection.first.platform).to eq("draftkings")
      expect(Projection.second.updated_at).not_to be_near_to_time(proj_fd.updated_at, 30.seconds)
    end
  end

  describe '.freshness' do

  end

  describe 'optimal_lineup' do
    it 'sets a lineup with the appropriate number of slots filled' do
      create_players("QB", rand(5) + 4, "fanduel")
      create_players("RB", rand(5) + 4, "fanduel")
      create_players("WR", rand(5) + 4, "fanduel")
      create_players("TE", rand(5) + 4, "fanduel")
      create_players("K", rand(5) + 4, "fanduel")
      create_players("DEF", rand(5) + 4, "fanduel")

      lineup = Player.find(Projection.optimal_lineup)
      expect(lineup.select{ |player| player.position == "QB" }.count).to eq(1)
      expect(lineup.select{ |player| player.position == "RB" }.count).to eq(2)
      expect(lineup.select{ |player| player.position == "WR" }.count).to eq(3)
      expect(lineup.select{ |player| player.position == "TE" }.count).to eq(1)
      expect(lineup.select{ |player| player.position == "K" }.count).to eq(1)
      expect(lineup.select{ |player| player.position == "DEF" }.count).to eq(1)
    end

    it 'creates the optimal lineup' do
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

      should_be = [qb2, rb1, rb2, wr1, wr2, wr3, te1, k2, def1]
      lineup = Player.find(Projection.optimal_lineup)
      binding.pry

      #qb  rb  rb  wr  wr  wr  te  k  def
      #5 , 1 , 9 , 9 , 5 , 5 , 9 , 5 , 5 = 53
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
end

def create_players(position, number, platform)
  for i in 0..number
    create_player(position, platform)
  end
end

def create_player(position, platform, average=nil, salary=nil)
  player = Fabricate(:player, position: position)
  if salary && average
    Fabricate(:projection, player: player, week: 1, platform: platform,
              salary: salary, average: average)
  else
    Fabricate(:projection, player: player, week: 1, platform: platform)
  end
  player
end

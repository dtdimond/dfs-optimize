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
    it 'tests' do
      create_players("QB", 3, "fanduel")
      create_players("RB", 3, "fanduel")
      create_players("WR", 3, "fanduel")
      create_players("TE", 3, "fanduel")
      create_players("K", 3, "fanduel")
      create_players("DEF", 3, "fanduel")

      Projection.optimal_lineup
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
    player = Fabricate(:player, position: position)
    Fabricate(:projection, player: player, week: 1, platform: platform)
  end
end

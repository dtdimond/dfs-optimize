require 'spec_helper'

describe Game do
  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".games_this_week" do
    it 'returns all the games for the current week' do
      VCR.use_cassette 'game/returns_games_for_current_week' do
        current_week = FFNerd.current_week
        g1 = Fabricate(:game, week: current_week, date: "Nov-5-2015")
        g2 = Fabricate(:game, week: current_week, date: "Nov-8-2015")
        g3 = Fabricate(:game, week: current_week, date: "Nov-8-2015")
        g4 = Fabricate(:game, week: current_week, date: "Nov-9-2015")
        should_be = {"Thursday" => ["#{g1.away_team} @ #{g1.home_team}"],
                     "Sunday" => ["#{g2.away_team} @ #{g2.home_team}",
                     "#{g3.away_team} @ #{g3.home_team}"],
                     "Monday" => ["#{g4.away_team} @ #{g4.home_team}"]}
        expect(Game.games_this_week).to eq(should_be)
      end
    end
  end

  describe ".refresh_data" do
    it 'gets all new game data if an existing game record is too old' do
      game = Fabricate(:game, updated_at: not_too_new)
      Fabricate(:game, updated_at: too_new)

      VCR.use_cassette 'game/refresh_data' do
        Game.refresh_data
      end

      #Initial two game fabrications are wiped away
      expect(Game.first.week).to eq(1)
      expect(Game.first.date).to eq("2013-09-05")
      expect(Game.first.away_team).to eq("BAL")
      expect(Game.first.home_team).to eq("DEN")
    end

    it 'gets all new game data if there are no records' do
      VCR.use_cassette 'game/refresh_data' do
        Game.refresh_data
      end

      expect(Game.first.away_team).to eq("BAL")
    end

    it 'gets no new game data if all existing game records are too recent' do
      game = Fabricate(:game, updated_at: too_new)
      Fabricate(:game, updated_at: too_new)

      VCR.use_cassette 'game/refresh_data' do
        Game.refresh_data
      end

      expect(Game.third).to be_nil
      expect(Game.first.updated_at).to be_near_to_time(game.updated_at, 0.seconds)
    end

    it 'gets no new game data (on second call) if it is called twice in a row' do
      VCR.use_cassette 'game/refresh_data' do
        Game.refresh_data
      end
      game = Game.first
      expect(game.away_team).to eq("BAL")

      VCR.use_cassette 'game/refresh_data' do
        Game.refresh_data
      end
      expect(Game.first.updated_at).to eq(game.updated_at)
    end
  end

  describe ".populate_data" do
    it 'populates the game database and updates the cached timestamp' do
      VCR.use_cassette 'game/populate_data' do
        Game.populate_data
      end

      expect(Game.first.away_team).to eq("BAL")
      expect(Game.first.updated_at).to be_near_to_time(Time.now, 10.seconds)
    end
  end

  describe ".cache_refresh?" do
    it 'returns false if updated_at is less than 60mins old' do
      game = Fabricate(:game)
      expect(game.refresh?).to be false
    end

    it 'returns true if updated_at is greater than 60mins old' do
      game = Fabricate(:game, updated_at: not_too_new)
      expect(game.refresh?).to be true
    end
  end
end

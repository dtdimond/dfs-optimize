require 'spec_helper'

describe Player do
  it { should have_many(:projections) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new player data if an existing player record is too old' do
      player = Fabricate(:player, updated_at: not_too_new)
      Fabricate(:player, updated_at: too_new)

      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end

      #Initial two player fabrications are wiped away
      expect(Player.first.name).to eq("Derek Anderson")
      expect(Player.first.player_id).to eq(2)
      expect(Player.first.position).to eq("QB")
      expect(Player.first.team).to eq("CAR")
    end

    it 'gets all new player data if there are no records' do
      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end

      expect(Player.first.name).to eq("Derek Anderson")
    end

    it 'gets no new player data if all existing player records are too recent' do
      player = Fabricate(:player, updated_at: too_new)
      Fabricate(:player, updated_at: too_new)

      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end

      expect(Player.third).to be_nil
      expect(Player.first.updated_at).to be_near_to_time(player.updated_at, 0.seconds)
    end

    it 'gets no new player data (on second call) if it is called twice in a row' do
      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end
      player = Player.first
      expect(player.name).to eq("Derek Anderson")

      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end
      expect(Player.first.updated_at).to eq(player.updated_at)
    end

    it 'gets new player data (on second call) if it is called twice, spread out in time' do
      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end
      player = Player.first
      expect(player.name).to eq("Derek Anderson")

      #mimic calling refresh_data 63 minutes later
      Player.first.update_attributes!(updated_at: not_too_new)
      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end
      expect(Player.first.updated_at).not_to eq(player.updated_at)
    end
  end

  describe ".populate_data" do
    it 'populates the player database and updates the cached timestamp' do
      VCR.use_cassette 'player/populate_data' do
        Player.populate_data
      end

      expect(Player.first.name).to eq("Derek Anderson")
      expect(Player.first.updated_at).to be_near_to_time(Time.now, 10.seconds)
    end
  end

  describe ".cache_refresh?" do
    it 'returns false if updated_at is less than 60mins old' do
      player = Fabricate(:player)
      expect(player.refresh?).to be false
    end

    it 'returns true if updated_at is greater than 60mins old' do
      player = Fabricate(:player, updated_at: not_too_new)
      expect(player.refresh?).to be true
    end
  end
end

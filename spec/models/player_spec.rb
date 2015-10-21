require 'spec_helper'

describe Player do
  it { should have_many(:projections) }
  it { should have_many(:salaries) }
  it { should have_many(:caches) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new player data if record is too old and updates the cached timestamp' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: 62.minutes.ago)

      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end

      expect(Player.second.name).to eq("Derek Anderson")
    end

    it 'gets all new player data if there are no records' do
      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end

      expect(Player.first.name).to eq("Derek Anderson")
    end

    it 'gets no new player data if cached record is too recent' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: 57.minutes.ago)

      VCR.use_cassette 'player/refresh_data' do
        Player.refresh_data
      end

      expect(Player.second).to be_nil
    end
  end

  describe ".populate_data" do
    it 'populates the player database and updates the cached timestamp' do
      VCR.use_cassette 'player/populate_data' do
        Player.populate_data
      end

      expect(Player.first.name).to eq("Derek Anderson")
      expect(Cache.last_updated(Player.first)).to be_near_to_time(Time.now, 30.seconds)
    end
  end

  describe ".cache_refresh?" do
    it 'returns false if last cached_time is less than 60mins old' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: Time.now)
      expect(Player.cache_refresh?(player)).to be false
    end

    it 'returns true if last cached_time is greater than 60mins old' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: 62.minutes.ago)
      expect(Player.cache_refresh?(player)).to be true
    end

    it 'returns true if there are no caches for the record' do
      player = Fabricate(:player)
      expect(Player.cache_refresh?(player)).to be true
    end
  end
end

require 'spec_helper'

describe Player do
  it { should have_many(:projections) }
  it { should have_many(:salaries) }
  it { should have_many(:caches) }

  describe "#refresh_data" do
    it 'gets all new player data if cached record is too old' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: 62.minutes.ago)

      VCR.use_cassette 'player/refresh_data' do
        player.refresh_data
      end

      expect(Player.second.name).to eq("Derek Anderson")
    end

    it 'updates the player data updated timestamp'
  end

  describe "#cache_refresh?" do
    it 'returns false if last cached_time is less than 60mins old' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: Time.now)
      expect(player.cache_refresh?).to be false
    end

    it 'returns true if last cached_time is greater than 60mins old' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: 62.minutes.ago)
      expect(player.cache_refresh?).to be true
    end

    it 'returns true if there are no caches for the record' do
      player = Fabricate(:player)
      expect(player.cache_refresh?).to be true
    end
  end
end

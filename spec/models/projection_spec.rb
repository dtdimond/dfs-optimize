require 'spec_helper'

describe Projection do
  it { should belong_to(:player) }
  it { should have_many(:caches) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new proj data if record is too old and updates the cached timestamp' do
      proj = Fabricate(:projection)
      cache = Fabricate(:cache, cacheable: proj, cached_time: 62.minutes.ago)

      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data
      end

      expect(Projection.second.average).to eq(16.5)
    end

    it 'gets all new proj data if there are no records' do
      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data
      end

      expect(Projection.first.average).to eq(16.5)
    end

    it 'gets no new proj data if cached record is too recent' do
      proj = Fabricate(:projection, platform: "fanduel")
      cache = Fabricate(:cache, cacheable: proj, cached_time: 57.minutes.ago)

      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data
      end

      expect(Projection.second).to be_nil
    end

    it 'gets new proj data if a cached record is too old, but for wrong platform' do
      proj = Fabricate(:projection, platform: "draftkings")
      cache = Fabricate(:cache, cacheable: proj, cached_time: 67.minutes.ago)

      VCR.use_cassette 'projection/refresh_data' do
        Projection.refresh_data
      end

      expect(Projection.second.average).to eq(16.5)
    end
  end

  describe ".populate_data" do
    it 'populates the proj database and updates the cached timestamp' do
      VCR.use_cassette 'projection/populate_data' do
        Projection.populate_data("fanduel")
      end

      expect(Projection.first.average).to eq(16.5)
      expect(Cache.last_updated(Projection.first)).to be_near_to_time(Time.now, 30.seconds)
    end
  end

  describe ".cache_refresh?" do
    it 'returns false if last cached_time is less than 60mins old' do
      proj = Fabricate(:projection)
      cache = Fabricate(:cache, cacheable: proj, cached_time: Time.now)
      expect(Projection.cache_refresh?(proj)).to be false
    end

    it 'returns true if last cached_time is greater than 60mins old' do
      proj = Fabricate(:projection)
      cache = Fabricate(:cache, cacheable: proj, cached_time: 62.minutes.ago)
      expect(Projection.cache_refresh?(proj)).to be true
    end

    it 'returns true if there are no caches for the record' do
      proj = Fabricate(:projection)
      expect(Projection.cache_refresh?(proj)).to be true
    end
  end
end

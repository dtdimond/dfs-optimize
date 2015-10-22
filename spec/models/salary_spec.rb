require 'spec_helper'

describe Salary do
  it { should belong_to(:player) }
  it { should have_many(:caches) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new salary data if record is too old and updates the cached timestamp' do
      salary = Fabricate(:salary)
      cache = Fabricate(:cache, cacheable: salary, cached_time: 62.minutes.ago)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.second.value).to eq(8000)
    end

    it 'gets all new salary data if there are no records' do
      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.first.value).to eq(8000)
    end

    it 'gets no new salary data if cached record is too recent' do
      salary = Fabricate(:salary, platform: "fanduel")
      cache = Fabricate(:cache, cacheable: salary, cached_time: 57.minutes.ago)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.second).to be_nil
    end

    it 'gets new salary data if a cached record is too old, but for wrong platform' do
      salary = Fabricate(:salary, platform: "draftkings")
      cache = Fabricate(:cache, cacheable: salary, cached_time: 67.minutes.ago)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.second.value).to eq(8000)
    end
  end

  describe ".populate_data" do
    it 'populates the salary database and updates the cached timestamp' do
      VCR.use_cassette 'salary/populate_data' do
        Salary.populate_data("fanduel")
      end

      expect(Salary.first.value).to eq(8000)
      expect(Cache.last_updated(Salary.first)).to be_near_to_time(Time.now, 30.seconds)
    end
  end

  describe ".cache_refresh?" do
    it 'returns false if last cached_time is less than 60mins old' do
      salary = Fabricate(:salary)
      cache = Fabricate(:cache, cacheable: salary, cached_time: Time.now)
      expect(Salary.cache_refresh?(salary)).to be false
    end

    it 'returns true if last cached_time is greater than 60mins old' do
      salary = Fabricate(:salary)
      cache = Fabricate(:cache, cacheable: salary, cached_time: 62.minutes.ago)
      expect(Salary.cache_refresh?(salary)).to be true
    end

    it 'returns true if there are no caches for the record' do
      salary = Fabricate(:salary)
      expect(Salary.cache_refresh?(salary)).to be true
    end
  end
end

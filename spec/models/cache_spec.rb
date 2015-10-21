require 'spec_helper'

RSpec::Matchers.define :be_equal_to_time do |another_date|
  match do |a_date|
    a_date.to_i.should == another_date.to_i
  end
end

describe Cache do
  it { should belong_to(:cacheable) }

  describe ".last_updated" do
    it 'returns the last updated time for the player cacheable type' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: Time.now)
      expect(Cache.last_updated("Player")).to be_equal_to_time cache.cached_time
    end

    it 'returns the last updated time for the salary cacheable type' do
      salary = Fabricate(:salary)
      cache1 = Fabricate(:cache, cacheable: salary, cached_time: 2.minutes.ago)
      cache2 = Fabricate(:cache, cacheable: salary, cached_time: Time.now)
      expect(Cache.last_updated("Salary")).to be_equal_to_time cache2.cached_time
    end

    it 'returns the last updated time for the projection cacheable type' do
      projection = Fabricate(:projection)
      cache1 = Cache.create(cacheable: projection, cached_time: Time.now)
      cache2 = Cache.create(cacheable: projection, cached_time: 2.minutes.ago)
      expect(Cache.last_updated("Projection")).to be_equal_to_time cache1.cached_time
    end

    it 'returns nil if there are no updates for the type' do
      expect(Cache.last_updated("Player")).to be_nil
    end

    it 'returns nil if the cacheable type is bad' do
      expect(Cache.last_updated("bad_input")).to be_nil
    end
  end
end

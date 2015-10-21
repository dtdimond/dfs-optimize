require 'spec_helper'

RSpec::Matchers.define :be_equal_to_time do |another_date|
  match do |a_date|
    a_date.to_i.should == another_date.to_i
  end
end

describe Cache do
  it { should belong_to(:cacheable) }

  describe ".last_updated" do
    it 'returns the last updated time for the player record' do
      player = Fabricate(:player)
      cache = Fabricate(:cache, cacheable: player, cached_time: Time.now)
      expect(Cache.last_updated(player)).to be_equal_to_time cache.cached_time
    end

    it 'returns the last updated time for the salary record' do
      salary = Fabricate(:salary)
      cache1 = Fabricate(:cache, cacheable: salary, cached_time: 2.minutes.ago)
      cache2 = Fabricate(:cache, cacheable: salary, cached_time: Time.now)
      expect(Cache.last_updated(salary)).to be_equal_to_time cache2.cached_time
    end

    it 'returns the last updated time for the projection record' do
      projection = Fabricate(:projection)
      cache1 = Cache.create(cacheable: projection, cached_time: Time.now)
      cache2 = Cache.create(cacheable: projection, cached_time: 2.minutes.ago)
      expect(Cache.last_updated(projection)).to be_equal_to_time cache1.cached_time
    end

    it 'returns nil if there are no updates for the record' do
      player = Fabricate(:player)
      expect(Cache.last_updated(player)).to be_nil
    end
  end
end

class Projection < ActiveRecord::Base
  belongs_to :player

  def self.refresh_data
    Salary.populate_data if Salary.any_cache_refresh?
  end

  private
  def self.populate_data(platform)
    week = FFNerd.daily_fantasy_league_info(platform).current_week

    ActiveRecord::Base.transaction do
      FFNerd.daily_fantasy_projections(platform).each do |salary|
        salary = Salary.create(value: salary.salary, week: week,
                               platform: platform, player_id: salary.player_id)
        Cache.create(cacheable: salary, cached_time: Time.now)
      end
    end
  end

  def self.any_cache_refresh?
    Salary.all.each do |salary|
      return true if Salary.cache_refresh?(salary)
    end
    false
  end

  def self.cache_refresh?(salary)
    last = Cache.last_updated(salary)
    last && last > 60.minutes.ago ? false : true
  end
end

class Projection < ActiveRecord::Base
  belongs_to :player
  has_many :caches, as: :cacheable

  def self.refresh_data(platform="fanduel")
    Projection.populate_data(platform) if Projection.any_cache_refresh?(platform)
  end

  private
  def self.populate_data(platform)
    week = FFNerd.daily_fantasy_league_info(platform).current_week

    ActiveRecord::Base.transaction do
      FFNerd.daily_fantasy_projections(platform).each do |proj|
        avg = proj.projections["consensus"]["projected_points"]
        max = proj.projections["aggressive"]["projected_points"]
        min = proj.projections["conservative"]["projected_points"]

        p = Projection.create(average: avg, week: week, platform: platform,
                              player_id: proj.player_id, average: avg, min: min, max: max)
        Cache.create(cacheable: p, cached_time: Time.now)
      end
    end
  end

  def self.any_cache_refresh?(platform)
    records = Projection.where("platform = '#{platform}'")
    records.each do |proj|
      return true if Projection.cache_refresh?(proj)
    end

    #refresh if no records
    records.any? ? false : true
  end

  def self.cache_refresh?(proj)
    last = Cache.last_updated(proj)
    last && last > 60.minutes.ago ? false : true
  end
end

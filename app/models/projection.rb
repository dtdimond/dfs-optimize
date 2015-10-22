class Projection < ActiveRecord::Base
  belongs_to :player

  def self.refresh_data(platform="fanduel")
    Projection.populate_data(platform) if Projection.any_refresh?(platform)
  end

  def self.freshness
    max = Projection.maximum("updated_at")
    max ? max  : nil
  end

  def refresh?
    updated_at && updated_at > 60.minutes.ago ? false : true
  end

  private
  def self.populate_data(platform)
    week = FFNerd.daily_fantasy_league_info(platform).current_week

    ActiveRecord::Base.transaction do
      Projection.delete_all("platform = '#{platform}'")
      FFNerd.daily_fantasy_projections(platform).each do |proj|
        avg = proj.projections["consensus"]["projected_points"]
        max = proj.projections["aggressive"]["projected_points"]
        min = proj.projections["conservative"]["projected_points"]

        p = Projection.create(average: avg, week: week, platform: platform, salary: proj.salary,
                              player_id: proj.player_id, average: avg, min: min, max: max)
      end
    end
  end

  def self.any_refresh?(platform)
    records = Projection.where("platform = '#{platform}'")
    records.each do |proj|
      return true if proj.refresh?
    end

    #refresh if no records
    records.any? ? false : true
  end
end

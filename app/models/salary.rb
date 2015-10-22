class Salary < ActiveRecord::Base
  belongs_to :player

  def self.refresh_data(platform="fanduel")
    Salary.populate_data(platform) if Salary.any_refresh?(platform)
  end

  def refresh?
    updated_at && updated_at > 60.minutes.ago ? false : true
  end

  private
  def self.populate_data(platform)
    week = FFNerd.daily_fantasy_league_info(platform).current_week

    ActiveRecord::Base.transaction do
      Salary.delete_all("platform = '#{platform}'")
      FFNerd.daily_fantasy_projections(platform).each do |salary|
        Salary.create(value: salary.salary, week: week,
                      platform: platform, player_id: salary.player_id)
      end
    end
  end

  def self.any_refresh?(platform)
    records = Salary.where("platform = ?", platform)
    records.each do |salary|
      return true if salary.refresh?
    end
    records.any? ? false : true #refresh if no records
  end
end

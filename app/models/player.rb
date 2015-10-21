class Player < ActiveRecord::Base
  has_many :projections
  has_many :salaries
  has_many :caches, as: :cacheable

  def self.populate_data
    FFNerd.players.each do |player|
      player = Player.create(name: player.display_name,
                             position: player.position, team: player.team)
      Cache.create(cacheable: player, cached_time: Time.now)
    end
  end

  def refresh_data
    Player.populate_data if cache_refresh?
  end

  def cache_refresh?
    last = Cache.last_updated(self)
    last && last > 60.minutes.ago ? false : true
  end
end

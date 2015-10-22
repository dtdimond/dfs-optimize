class Player < ActiveRecord::Base
  has_many :projections
  has_many :salaries
  has_many :caches, as: :cacheable

  def self.refresh_data
    Player.populate_data if Player.any_cache_refresh?
  end

  private
  def self.populate_data
    ActiveRecord::Base.transaction do
      FFNerd.players.each do |player|
        player = Player.create(name: player.display_name, player_id: player.player_id,
                               position: player.position, team: player.team)
        Cache.create(cacheable: player, cached_time: Time.now)
      end
    end
  end

  def self.any_cache_refresh?
    Player.all.each do |player|
      return true if Player.cache_refresh?(player)
    end
    Player.any? ? false : true #refresh if no records
  end

  def self.cache_refresh?(player)
    last = Cache.last_updated(player)
    last && last > 60.minutes.ago ? false : true
  end
end

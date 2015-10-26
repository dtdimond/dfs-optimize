class Player < ActiveRecord::Base
  has_many :projections, foreign_key: "player_id"

  def self.refresh_data
    Player.populate_data if Player.any_refresh?
  end

  def refresh?
    updated_at && updated_at > 60.minutes.ago ? false : true
  end

  private
  def self.populate_data
    ActiveRecord::Base.transaction do
      Player.delete_all #reset all
      FFNerd.players.each do |player|
        Player.create(name: player.display_name, player_id: player.player_id,
                      id: player.player_id, position: player.position, team: player.team)
      end
    end
  end

  def self.any_refresh?
    Player.all.each do |player|
      return true if player.refresh?
    end
    Player.any? ? false : true #refresh if no records
  end
end

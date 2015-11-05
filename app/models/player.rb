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

      inserts = []
      FFNerd.players.each do |player|
        inserts.push "('#{player.display_name.gsub("'","`")}','#{player.player_id}',
                       '#{player.player_id}','#{player.position}','#{player.team}',
                       '#{Time.now.utc}','#{Time.now.utc}')"
      end

      conn = ActiveRecord::Base.connection
      sql = "INSERT INTO players (name, player_id, id, position,
            team, created_at, updated_at) VALUES #{inserts.join(",")}"
      conn.execute sql
    end
  end

  def self.any_refresh?
    Player.all.each do |player|
      return true if player.refresh?
    end
    Player.any? ? false : true #refresh if no records
  end
end

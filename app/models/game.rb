class Game < ActiveRecord::Base
  def self.refresh_data
    Game.populate_data if Game.any_refresh?
  end

  def self.games_this_week
    formatted_games = Hash.new
    Game.where(week: FFNerd.current_week).each do |game|
      day_of_week = game.date.strftime('%A')
      formatted_games[day_of_week] = [] unless formatted_games[day_of_week]
      formatted_games[day_of_week].push("#{game.away_team} @ #{game.home_team}")
    end
    formatted_games.sort.reverse.to_h
  end

  def refresh?
    updated_at && updated_at > 60.minutes.ago ? false : true
  end

  private
  def self.populate_data
    ActiveRecord::Base.transaction do
      Game.delete_all #reset all

      inserts = []
      FFNerd.schedule.each do |game|
        inserts.push "('#{game.game_id}','#{game.game_week}','#{game.game_date}',
                       '#{game.home_team}','#{game.away_team}',
                       '#{Time.now.utc}','#{Time.now.utc}')"
      end

      conn = ActiveRecord::Base.connection
      sql = "INSERT INTO games (id, week, date, home_team, away_team,
            created_at, updated_at) VALUES #{inserts.join(",")}"
      conn.execute sql
    end
  end

  def self.any_refresh?
    Game.all.each do |game|
      return true if game.refresh?
    end
    Game.any? ? false : true #refresh if no records
  end
end

class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :week
      t.timestamp :date
      t.string :away_team
      t.string :home_team
      t.timestamps
    end
  end
end

class CreateProjections < ActiveRecord::Migration
  def change
    create_table :projections do |t|
      t.integer :week
      t.decimal :average
      t.decimal :min
      t.decimal :max
      t.string :platform
      t.integer :player_id
      t.timestamps
    end
  end
end

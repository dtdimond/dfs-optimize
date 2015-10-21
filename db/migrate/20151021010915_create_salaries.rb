class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.integer :value
      t.string :platform
      t.integer :player_id
      t.timestamps
    end
  end
end

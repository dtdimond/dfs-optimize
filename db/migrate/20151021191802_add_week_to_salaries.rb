class AddWeekToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :week, :integer
  end
end

class AddSalaryToProjections < ActiveRecord::Migration
  def change
    add_column :projections, :salary, :integer
  end
end

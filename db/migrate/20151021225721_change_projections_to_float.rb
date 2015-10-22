class ChangeProjectionsToFloat < ActiveRecord::Migration
  change_table :projections do |t|
    t.change :average, :float
    t.change :min, :float
    t.change :max, :float
  end
end

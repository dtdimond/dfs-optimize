class CreateCache < ActiveRecord::Migration
  def change
    create_table :caches do |t|
      t.integer :cacheable_id
      t.string :cacheable_type
      t.timestamp :cached_time
      t.timestamps
    end
  end
end

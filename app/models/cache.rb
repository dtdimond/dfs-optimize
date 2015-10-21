class Cache < ActiveRecord::Base
  belongs_to :cacheable, polymorphic: true

  def self.last_updated(record)
    Cache.where("cacheable_id = ? AND cacheable_type = ?", record,
                record.class.to_s).maximum("cached_time")
  end
end

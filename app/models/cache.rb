class Cache < ActiveRecord::Base
  belongs_to :cacheable, polymorphic: true

  def self.last_updated(record)
    all = Cache.where("cacheable_id = ? AND cacheable_type = ?", record, record.class.to_s)
    all.maximum("cached_time")
  end
end

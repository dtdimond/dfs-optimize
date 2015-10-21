class Cache < ActiveRecord::Base
  belongs_to :cacheable, polymorphic: true

  VALID_CACHEABLE_TYPES = ["Player","Salary","Projection"]

  def self.last_updated(cacheable_type)
    return nil unless VALID_CACHEABLE_TYPES.include?(cacheable_type)
    Cache.where("cacheable_type = ?", cacheable_type).maximum("cached_time")
  end
end

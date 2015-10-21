class Player < ActiveRecord::Base
  has_many :projections
  has_many :salaries
  has_many :caches, as: :cacheable

#  def self.get_data
#    if self.caches.last
#      get_data_from_cache (or database)
#    else
#      get_data_from_gem
#      set_cache_timer
#    end
#
#
#
#
#    FFNerd.api_key = "test"
#    qb_data = FFNerd.weekly_rankings("QB")
#    FFNerd.players
#    binding.pry
#
#  end
end

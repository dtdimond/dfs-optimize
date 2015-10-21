Fabricator(:cache) do
  cached_time { Faker::Time.between(DateTime.now - 1, DateTime.now) }
  cacheable { Fabricator(:player) }
end
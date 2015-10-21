Fabricator(:salary) do
  value { Faker::Number.number(4) }
  platform { ["FanDuel","DraftKings","Yahoo"].sample }
  player
end
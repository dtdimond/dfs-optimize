Fabricator(:salary) do
  value { Faker::Number.number(4) }
  platform { ["fanduel","draftkings","yahoo"].sample }
  player
end
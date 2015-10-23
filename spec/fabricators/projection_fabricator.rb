Fabricator(:projection) do
  week { rand(1..17) }
  average { Faker::Number.decimal(2,2).to_f }
  min { |attrs| attrs[:average] - (attrs[:average] / 4) }
  max { |attrs| attrs[:average] + (attrs[:average] / 4) }
  platform { ["fanduel","draftkings","yahoo"].sample }
  salary { Faker::Number.number(4) }
  player
end
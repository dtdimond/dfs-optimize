Fabricator(:projection) do
  week { rand(1..17) }
  avg = Faker::Number.decimal(2,2).to_f
  average { avg }
  min { avg - (avg / 4) }
  max { avg + (avg / 4) }
  platform { ["fanduel","draftkings","yahoo"].sample }
  salary { Faker::Number.number(4) }
  player
end
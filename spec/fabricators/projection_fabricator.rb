Fabricator(:projection) do
  week { [1..17].sample }
  avg = Faker::Number.decimal(2,2).to_f
  average { avg }
  min { avg - (avg / 4) }
  max { avg + (avg / 4) }
  platform { ["fanduel","draftkings","yahoo"].sample }
  player
end
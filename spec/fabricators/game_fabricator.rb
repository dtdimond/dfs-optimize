Fabricator(:game) do
  week { rand(16) + 1 }
  date { Faker::Date.backward(14) }
  home_team { ["BAL","DEN","SEA","DET","KC","CAR"].sample }
  away_team { ["BAL","DEN","SEA","DET","KC","CAR"].sample }
end
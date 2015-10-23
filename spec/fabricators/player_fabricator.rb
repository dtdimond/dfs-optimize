Fabricator(:player) do
  name { Faker::Name.name }
  position { ["QB","RB","WR","TE","K","DEF"].sample }
  team { ["BAL","DEN","SEA","DET","KC","CAR"].sample }
  player_id { Fabricate.sequence }
end
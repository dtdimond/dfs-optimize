# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

flacco = Player.create(name: "Joe Flacco", position: "QB", team: "BAL", player_id: 1)
Projection.create(player: flacco, salary: 6000, week: 1, average: 15.5,
                  min: 10.0, max: 20.0, platform: "fanduel")

peyton = Player.create(name: "Peyton Manning", position: "QB", team: "DEN", player_id: 2)
Projection.create(player: peyton, salary: 6300, week: 1, average: 17.5,
                  min: 11.2, max: 23.0, platform: "fanduel")

bell = Player.create(name: "Leveon Bell", position: "RB", team: "PIT", player_id: 3)
Projection.create(player: bell, salary: 8300, week: 1, average: 18.5,
                  min: 13.3, max: 21.0, platform: "fanduel")

charles = Player.create(name: "Jamaal Charles", position: "RB", team: "KC", player_id: 4)
Projection.create(player: charles, salary: 7900, week: 1, average: 16.5,
                  min: 12.3, max: 19.2, platform: "fanduel")


require "csv"
require 'ruby_native_statistics'
require_relative "team4_shuffle"

if $0 == __FILE__
  captains_csv = ARGV[0] || "captains2.csv"
  players_csv = ARGV[1] || "players2.csv"

  captains = Player.load_players(captains_csv)
  players = Player.load_players(players_csv)

  team_size = 2
  best_formation = TeamFormation.new(captains, players, team_size)

  10000.times do
    formation = TeamFormation.new(captains, players, team_size)
    if formation.stdevp < best_formation.stdevp
      best_formation = formation
    end
  end

  best_formation.print
  best_formation.print_csv

  print "Pressez une touche pour continuer..."; gets
end

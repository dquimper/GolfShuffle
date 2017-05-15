require "csv"
require 'ruby_native_statistics'

class Player
  attr_accessor :name, :handicap

  def initialize(name, handicap)
    @name = name
    @handicap = handicap.gsub(",",".").to_f
  end

  def self.load_players(csv_file)
    players = []
    File.open(csv_file) do |f|
      CSV.parse(f.read, col_sep: ";").each do |row|
        players << Player.new(row[0], row[1])
      end
    end
    players
  end

  def print
    "%-30s  (%.1f)" % [name, handicap]
  end
end

class Team
  attr_accessor :captain
  attr_accessor :players

  def initialize(captain)
    @captain = captain
    @players = []
  end

  def add_player(player)
    if players.size < 3
      players << player
    end
  end

  def mean
    @_mean ||= ([@captain] + @players).map(&:handicap).mean
  end

  def print
    puts "Capitaine : #{@captain.print}"
    @players.each_with_index do |p, i|
      puts "Joueur #{i+1}  : #{p.print}"
    end
    puts "Moyenne : #{mean}"
  end
end

class TeamFormation
  attr_accessor :teams

  def initialize(captains, players)
    @teams = []
    captains.each do |cap|
      @teams << Team.new(cap)
    end
    players.each do |p|
      @teams.shuffle.each do |t|
        assigned = t.add_player(p)
        break if assigned
      end
    end
  end

  def stdevp
    @_stdevp ||= @teams.map(&:mean).stdevp
  end

  def print
    @teams.each_with_index do |t, i|
      puts "Équipe #{i+1}"
      t.print
      puts ""
    end
    puts "Formation stdevp : #{stdevp}"
  end
end


captains_csv = ARGV[0] || "captains.csv"
players_csv = ARGV[1] || "players.csv"

captains = Player.load_players(captains_csv)
players = Player.load_players(players_csv)

best_formation = TeamFormation.new(captains, players)

1000.times do
  formation = TeamFormation.new(captains, players)
  if formation.stdevp < best_formation.stdevp
    best_formation = formation
  end
end

best_formation.print

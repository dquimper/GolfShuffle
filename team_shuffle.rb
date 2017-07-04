require "csv"
require 'ruby_native_statistics'

class Player
  attr_accessor :name, :handicap

  def initialize(name, handicap)
    @name = name
    @handicap = handicap.gsub(",",".").to_f
  end

  def self.load_players(csv_file)
    col_seps = [";", ",", "\t"]
    players = []
    File.open(csv_file) do |f|
      csv_data = f.read
      col_seps.each_with_index do |col_sep, idx|
        begin
          CSV.parse(csv_data, col_sep: col_sep).each do |row|
            players << Player.new(row[0], row[1])
          end
          break
        rescue CSV::MalformedCSVError => e
          if idx >= col_seps.size - 1
            $stderr.puts "Problème de chargement de '#{csv_file}'"
            raise e
          end
        end
      end
    end
    players
  end

  def print
    "%-30s  (%.1f)" % [name, handicap]
  end

  def <=>(o)
    self.handicap <=> o.handicap
  end

  def to_csv
    [name, handicap.to_s.gsub(".", ",")]
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

  def sum
    @_sum ||= ([@captain] + @players).map(&:handicap).inject(0){|sum,x| sum + x }
  end

  def print
    puts "Capitaine : #{@captain.print}"
    @players.sort.each_with_index do |p, i|
      puts "Joueur #{i+1}  : #{p.print}"
    end
    puts "Moyenne : #{mean}"
  end

  def to_csv
    list = []
    list << captain.to_csv
    @players.sort.each do |p|
      list << p.to_csv
    end
    list << sum.to_s.gsub(".", ",")
    list << mean.to_s.gsub(".", ",")
    list.flatten
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

  def print_csv
    CSV.open("team_shuffle.csv", "wb", col_sep: ";") do |csv|
      csv << ["Capitaine 1", "Eval", "Joueur 2", "Eval", "Joueur 3", "Eval", "Joueur 4", "Eval", "Somme", "Moyenne"]
      @teams.each_with_index do |t, i|
        csv << t.to_csv
      end
      csv << ["Formation stdevp", stdevp.to_s.gsub(".", ",")]
    end
  end
end


captains_csv = ARGV[0]
players_csv = ARGV[1]

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
best_formation.print_csv

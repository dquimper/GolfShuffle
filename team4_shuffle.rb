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

  def to_csv(options)
    [name, handicap.to_s.gsub(".", options[:digit_sep])]
  end
end

class Team
  attr_accessor :captain
  attr_accessor :players

  def initialize(captain, team_size)
    @captain = captain
    @players = []
    @team_size = team_size
  end

  def add_player(player)
    if players.size < (@team_size - 1)
      players << player
    end
  end

  def mean
    @_mean ||= ([@captain] + @players).map(&:handicap).mean
  end

  def sum
    @_sum ||= ([@captain] + @players).map(&:handicap).inject(0){|sum,x| sum + x }
  end

  def print_txt(f)
    f.puts "Capitaine : #{@captain.print}"
    @players.sort.each_with_index do |p, i|
      f.puts "Joueur #{i+1}  : #{p.print}"
    end
    f.puts "Moyenne : #{mean}"
  end

  def to_csv(options)
    list = []
    list << captain.to_csv(options)
    @players.sort.each do |p|
      list << p.to_csv(options)
    end
    list << sum.to_s.gsub(".", options[:digit_sep])
    list << mean.to_s.gsub(".", options[:digit_sep])
    list.flatten
  end
end

class TeamFormation
  attr_accessor :teams

  def initialize(captains, players, team_size)
    @team_size = team_size
    @teams = []
    captains.each do |cap|
      @teams << Team.new(cap, @team_size)
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

  def print_txt
    File.open("team#{@team_size}_shuffle.txt", "w") do |f|
      @teams.each_with_index do |t, i|
        f.puts "Équipe #{i+1}"
        t.print_txt(f)
        f.puts ""
      end
      f.puts "Formation stdevp : #{stdevp}"
    end
  end

  def print_csv(options = {})
    CSV.open("team#{@team_size}_shuffle.csv", "wb", options.except(:digit_sep)) do |csv|
      csv_header = []
      csv_header << ["Capitaine", "Eval"]
      (@team_size - 1).times do |i|
        csv_header << ["Joueur #{i+1}", "Eval"]
      end
      csv_header << ["Somme", "Moyenne"]
      csv << csv_header.flatten
      @teams.each_with_index do |t, i|
        csv << t.to_csv(options)
      end
      csv << ["Formation stdevp", stdevp.to_s.gsub(".", options[:digit_sep])]
    end
  end
end

class Hash
  def except(*keys)
    self.reject {|k,v| keys.include?(k)}
  end
end

if $0 == __FILE__
  captains_csv = ARGV[0] || "captains4.csv"
  players_csv = ARGV[1] || "players4.csv"

  captains = Player.load_players(captains_csv)
  players = Player.load_players(players_csv)

  team_size = 4
  best_formation = TeamFormation.new(captains, players, team_size)

  10000.times do
    formation = TeamFormation.new(captains, players, team_size)
    if formation.stdevp < best_formation.stdevp
      best_formation = formation
    end
  end

  best_formation.print_txt
  best_formation.print_csv(col_sep: ";", digit_sep: ",")

  print "Pressez une touche pour continuer..."; gets
end

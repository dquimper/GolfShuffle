class Array
  def randomize
    self.sort_by { rand }
  end
end

def pick_match(week)
  flatten_week = week.flatten
  return nil if flatten_week.uniq.size != flatten_week.size
  if week.size == @weekly_matches
    return week
  end
  @matches.each do |match|
    w = pick_match(week + [match])
    return w if w
  end
  return nil
end


@number_of_teams = 18

20.times do
teams = (1..@number_of_teams).to_a.randomize
@weekly_matches = @number_of_teams/2


@matches = []
teams.each do |a|
  teams.each do |b|
    next if a == b
    match = [a,b].sort
    if not @matches.include?(match)
      @matches << match
    end
  end
end


week_number = 1
while @matches.size > 0
  week = pick_match([])
  if week
    puts "Semaine #{"%2d" % week_number}: #{(week.randomize).inspect}"
    week_number += 1
    @matches -= week
  else
    puts "\e[32m" + "@matches=#{(@matches).inspect}" + "\e[39m"
    break
  end
end
puts "\n"
end

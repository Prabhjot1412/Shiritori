def get_game_mode
  game_mode = nil

  loop do
    puts 'Game modes: single (s) , Against Computer (a)'
    print 'select a game mode (s or a) >> '

    input = gets.chomp
    case input
    when 's'
      game_mode = Game::SINGLE
    when 'a'
      game_mode = Game::AI
    else
      puts 'incorrect game mode: chosen game mode is invalid'
    end

    break unless game_mode.nil?
  end

  game_mode
end

def check_chance(chance_percentage)
  return true if rand(1..100) <= chance_percentage

  false
end

def remove_extra_spaces(word) # ' abc def ' => 'abc def'
  word[0] = '' if word[0] == ' '
  word[-1] = '' if word[-1] == ' '

  word
end
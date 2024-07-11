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

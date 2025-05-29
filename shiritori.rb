require_relative 'file_handler'
require_relative 'romanji'
require_relative 'game'
require_relative 'helper'

require 'debug'

Config = {
           game_mode: Game::AI,
           type: :NounOnly # :all, :NounOnly
         }

file_path = 'goi/kotoba.txt'

case Config[:type]
when :NounOnly
  file_path = "goi/kotoba_noun_only.txt"
end

file_handler = FileHandler.new(file_path)

game = Game.new(file_handler,game_mode: Config[:game_mode])#, game_mode: get_game_mode)

ai_first_turn = check_chance(50) if game.game_mode == Game::AI

print 'First Word >> ' if ai_first_turn.nil? || !ai_first_turn
print game.ai_first_turn if ai_first_turn

loop do
  input = gets.chomp
  output = ''

  if input == 'q'
    break
  elsif input == ''
    print 'word? >>'
    next
  else
    output = game.handle_input(input)
  end
  break if output == "$GAME_OVER$"

  if output.include?('$win$')
    output.gsub!('$win$', '')
    print "#{output.chomp} "
    break
  end
  print output + ' >> '
end

file_handler.close

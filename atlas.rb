require_relative 'file_handler'
require_relative 'helper'
require_relative 'atlas/game'

require 'debug'

file_path = 'atlas/places.txt'
file_handler = FileHandler.new(file_path)

game = Game.new(file_handler)
ai_first_turn = check_chance(50)
print "First place >> " unless ai_first_turn
print game.ai_first_turn if ai_first_turn

loop do
  input = gets.chomp
  output = ''

  if input == 'q'
    break
  elsif input == ''
    print 'place? >>'
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

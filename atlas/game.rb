class Game
  def initialize(file_handler)
    @file_handler = file_handler
    @places_already_occoured = []
    @recorder = true
    @valid_places = @file_handler.lines.map {|line| line.split(',')[1]}
    @add_places = true # allow adding places during game. format: place -m meaning of place
    @require_meaning_to_add_place = true
  end

  def handle_input(input, ai: false)
    inputs = input.split('-m').map  { |word| remove_extra_spaces(word) }
    place = inputs[0]&.downcase

    return game_over("you have exited the game") if place == 'exit'
    return "$win$ Victory is yours, there are no words that I can think of that starts with #{@places_already_occoured.last.split('').last}" if place.nil? && ai
    return "incorrect format - empty string" if place.nil? || place == ''
    return "incorrect format - string can't contain commas ','" if input.include?(',')
    return game_over("The place '#{place}' have already been occoured") if @places_already_occoured.include?(place)
    return "incorrect place - '#{place}' doesn't starts with #{@places_already_occoured.last.split('').last}" unless @places_already_occoured.empty? || starts_with_correct_letter(place)

    meaning = @file_handler.word_in_file?(place, return_meaning: true)
    msg = ", it is a #{meaning}" if meaning.is_a?(String) && meaning != ''

    if @recorder && !meaning && !ai
      add_file = add_to_file(inputs)
      return add_file if add_file&.include?('place not added')
      return add_file.gsub('$error$', '') if add_file&.include?('$error')
      print add_file
    end

    @places_already_occoured << place

    return handle_input(ai_response, ai: true) if !ai
    return "I will go with #{place.capitalize}#{msg}" if ai

    "previous place was #{place.capitalize}#{msg}"
  end

  def add_to_file(inputs)
    place = inputs[0].downcase
    place_in_file = @file_handler.word_in_file?(place, increase_count_if_exists: true)

    return "$error$No such place" unless @add_places

    meaning = inputs[1]
    return "$error$Meaning is required for adding new places" if meaning.nil? && @require_meaning_to_add_place == true

    @file_handler.add_word(name: place, meaning: meaning)
    "Added a new place to atlas #{place}: #{meaning}\n"
  end

  def game_over(msg)
    puts msg
    "$GAME_OVER$"
  end

  def ai_response
    return '' unless possible_responses.any?

    places = {}
    possible_responses.each do |place|
      places[place] = @file_handler.word_in_file?(place)
    end

    return places.max(4).sample[0]
  end

  def possible_responses
    @valid_places.delete_if { |place| @places_already_occoured.include?(place)}
    possible_responses = @valid_places.select do |place|
      starts_with_correct_letter(place)
    end

    possible_responses
  end

  def starts_with_correct_letter(place)
    last_word = @places_already_occoured.last
    return true if place.downcase.split('').first == last_word.downcase.split('').last

    false
  end

  def ai_first_turn
    places = @valid_places
    places.shift # shift will remove id,word,meaning from the list
    place = places.sample
    msg = "I will go first with #{place}, it's a #{@file_handler.word_in_file?(place, return_meaning: true)}, your turn >> "

    @places_already_occoured << place 
    @valid_places.delete(place)
    msg
  end
end
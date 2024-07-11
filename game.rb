class Game
  attr_accessor :words_already_occoured
  attr_reader :game_mode

  UnsupportedGameModeError = Class.new(StandardError)

  SINGLE = 'single'
  AI = 'ai'
  GAME_MODES = [SINGLE, AI]
  
  def initialize(file_handler, game_mode: SINGLE)
    raise UnsupportedGameModeError, "#{game_mode} is not a valid game mode" unless GAME_MODES.include?(game_mode)

    @file_handler = file_handler
    @words_already_occoured = []
    @recorder = true
    @override_meaning = false
    @game_mode = game_mode
    @valid_words = @file_handler.lines.map {|line| line.split(',')[1]}
    @require_meaning_to_add_word = true
  end

  def handle_input(input, ai: false)
    inputs = input.split(' ')
    word = inputs[0]

    return game_over("the word #{word} ends with n") if !ai && ending_romanji(word) == 'n'
    return game_over("you have exited the game") if word == 'exit'
    return "$win$ Victory is yours, there are no words that I can think of that starts with #{ending_romanji(@words_already_occoured.last)}" if word.nil? && ai
    return "incorrect format - empty string" if word.nil? || word == ''
    return "incorrect format - string can't contain commas ','" if input.include?(',')
    return "incorrect format - '#{word}' doesn't end in Romanji" unless ends_in_romanji?(word)
    return game_over("The word '#{word}' have already been occoured") if @words_already_occoured.include?(word)
    return "incorrect word - '#{word}' doesn't starts with #{ending_romanji(@words_already_occoured.last)}" unless @words_already_occoured.empty? || ending_romanji(@words_already_occoured.last) == starting_romanji(word) 

    meaning = @file_handler.word_in_file?(word, return_meaning: true)
    msg = ", it means #{meaning.split(';').join(' or ')}" if meaning.is_a?(String) && meaning != ''

    if recorder_on? && !ai
      add_file = add_to_file(inputs)
      return add_file.gsub('$error$', '') if add_file&.include?('$error')
      print add_file
    end

    @words_already_occoured << word

    return handle_input(ai_response, ai: true) if @game_mode == AI && !ai
    return "I will go with #{word}#{msg}" if ai

    "previous word was #{word}#{msg}"
  end

  def recorder_on?
    @recorder
  end

  def toggle_recorder
    @recorder = !@recorder
  end

  def ai_first_turn
    words = @valid_words
    words.shift # shift will remove id,word,meaning from the list
    word = words.sample
    msg = "I will go first with #{word}, it means #{@file_handler.word_in_file?(word, return_meaning: true)}, your word >> "

    @words_already_occoured << word 
    @valid_words.delete(word)
    msg
  end

  private

  def ends_in_romanji?(input)
    ROMANJI.include?(input.split('').last(3).join) || ROMANJI.include?(input.split('').last(2).join) || ROMANJI.include?(input.split('').last)
  end

  def ending_romanji(word)
    return word.split('').last(3).join if ROMANJI.include?(word.split('').last(3).join)
    return word.split('').last(2).join if ROMANJI.include?(word.split('').last(2).join)
    word.split('').last
  end

  def starting_romanji(word)
    return word.split('').first(3).join if ROMANJI.include?(word.split('').first(3).join)
    return word.split('').first(2).join if ROMANJI.include?(word.split('').first(2).join)
    word.split('').first
  end

  def game_over(msg)
    puts msg
    "$GAME_OVER$"
  end

  def add_to_file(inputs)
    word = inputs[0].downcase
    return update_meaning(inputs) if @file_handler.word_in_file?(word, increase_count_if_exists: true)

    meaning = extract_meaning(inputs)
    return "$error$Meaning is required for adding new words" if meaning.nil? && @require_meaning_to_add_word == true

    @file_handler.add_word(name: word, meaning: meaning)
    "Added a new word to vocabulary #{word}: #{meaning}\n"
  end

  def extract_meaning(inputs)
    message_tag_index = inputs.index('-m')
    return if message_tag_index.nil?

    meaning_index = message_tag_index + 1
    meaning = ''
    (inputs.count - meaning_index).times do |i|
      meaning += inputs[meaning_index + i] + ' '
    end
    meaning[-1] = '' # removes extra space
    meaning
  end

  def update_meaning(inputs)
    word = inputs[0]
    new_meaning = extract_meaning(inputs)

    return unless new_meaning && @override_meaning
    @file_handler.update_meaning(word, new_meaning, override: !!@override_meaning)
  end

  def ai_response
    responses = []

    possible_responses.each do |word|
      use_count = @file_handler.word_in_file?(word)
      use_count.times do
        responses << word
      end
    end

    return '' unless responses.any?

    responses.sample
  end

  def possible_responses
    @valid_words.delete_if { |word| @words_already_occoured.include?(word)}
    previous_words_ending_romanji = ending_romanji(@words_already_occoured.last)
    possible_responses = @valid_words.select do |word|
      starting_romanji(word) == previous_words_ending_romanji
    end

    possible_responses
  end
end

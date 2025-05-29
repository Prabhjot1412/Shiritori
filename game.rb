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
    @skip_vowels = true # when this is present, shiyou can followed up by both 'u' and 'yo'
    @add_words = true # allow adding words during game. format: word -m meaning of word
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
    return "incorrect word - '#{word}' doesn't starts with #{ending_romanji(@words_already_occoured.last)}" unless @words_already_occoured.empty? || starts_with_correct_romanji(word)

    meaning = @file_handler.word_in_file?(word, return_meaning: true)
    msg = ", it means #{meaning.split(';').join(' or ')}" if meaning.is_a?(String) && meaning != ''

    if recorder_on? && !ai
      add_file = add_to_file(inputs)
      return add_file if add_file&.include?('word not added')
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

  def starts_with_correct_romanji(word)
    last_word = @words_already_occoured.last
    last_word_ending_romanji = ending_romanji(last_word)
    return true if last_word_ending_romanji == starting_romanji(word)
    if @skip_vowels && VOWELS.include?(last_word_ending_romanji)
      last_word = last_word.slice(0, last_word.length() -1) # removes last letter of the word, 'goi' becomes 'go'

      if ends_in_romanji?(last_word) && ending_romanji(last_word) == starting_romanji(word)
        return true
      end
    end

    false
  end

  def ending_romanji(word)
    return word.split('').last(4).join if ROMANJI.include?(word.split('').last(4).join)
    return word.split('').last(3).join if ROMANJI.include?(word.split('').last(3).join)
    return word.split('').last(2).join if ROMANJI.include?(word.split('').last(2).join)
    word.split('').last
  end

  def starting_romanji(word)
    return word.split('').first(4).join if ROMANJI.include?(word.split('').first(4).join)
    return word.split('').first(3).join if ROMANJI.include?(word.split('').first(3).join)
    return word.split('').first(2).join if ROMANJI.include?(word.split('').first(2).join)
    word.split('').first
  end

  def game_over(msg)
    puts msg
    "$GAME_OVER$"
  end

  def add_to_file(inputs)
    return 'word not added' if meaning_already_exists?(extract_meaning(inputs))

    word = inputs[0].downcase
    word_in_file = @file_handler.word_in_file?(word, increase_count_if_exists: true)

    return update_meaning(inputs) if word_in_file
    return "$error$No such word" unless @add_words

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

    return unless new_meaning
    if @override_meaning
      @file_handler.update_meaning(word, new_meaning, override: !!@override_meaning)
    else
      "word not added: already exists!"
    end
  end

  def ai_response
    return '' unless possible_responses.any?

    words = {}
    possible_responses.each do |word|
      words[word] = @file_handler.word_in_file?(word)
    end

    return words.invert.max(3).sample[1]
  end

  def possible_responses
    @valid_words.delete_if { |word| @words_already_occoured.include?(word)}
    possible_responses = @valid_words.select do |word|
      starts_with_correct_romanji(word)
    end

    possible_responses
  end

  def meaning_already_exists?(meaning)
    words_with_meaning = @file_handler.lines.select {|line| line.split(',')[2].split(';').include?(meaning) }
    return false if words_with_meaning.empty?

    unless words_with_meaning.empty?
      words = words_with_meaning.map { |line| line.split(',')[1] }
      permission = false

      puts "this meaning already exists with #{words.join(', ')}. do you still wish to add it? y/yes or n/no"
      print ' >>'
      loop do
        input = gets.chomp

        if input == 'y' || input == 'yes'
          permission = true
          break
        elsif input == 'n' || input == 'no'
          permission = false
          break
        end

        puts "options are 'y' or 'yes' and 'n' or 'no'"
        print 'choice? >>'
      end

      !permission
    end
  end
end

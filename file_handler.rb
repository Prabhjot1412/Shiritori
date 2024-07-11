class FileHandler
  attr_reader :lines

  def initialize(path, columns = nil)
    @path_of_file = path
    @file_handler = File.open(path, 'a+')
    @lines = readlines
    @columns = columns || ['id', 'word', 'meaning', 'use_count']

    add_columns if @lines.empty?
  end

  def write(text)
    @file_handler.syswrite(text + "\n")
    @lines = @lines << text + "\n"
  end

  def add_word(**word_inputs) # example of word_inputs:- { name: kuro, meaning: black }
    new_id = @lines.last.split(',').first.to_i + 1
    text = word_text(
      id: new_id,
      name: word_inputs[:name].downcase,
      meaning: word_inputs[:meaning],
      use_count: 1
    )

    write(text)
  end

  def update_meaning(word, meaning, override: false)
    @lines.map! do |line|
      line = line.split(',')
      line[2] = meaning if line[1] == word && (line[2] == '' || override)
      line = line.join(',')
      line = line + "\n" unless line[-1] == "\n"
      line
    end
  end

  def word_in_file?(word, increase_count_if_exists: false, return_meaning: false)
    word = word.downcase
    line = @lines.select {|line| line.split(',')[1] == word}.first
    return false unless line
    line = line.split(',')
    current_use_count = line[3].gsub("\n",'').to_i

    increase_use_count(word) if increase_count_if_exists

    return line[2] if return_meaning
    current_use_count
  end

  def ascending_id
    (@lines.last.split(',')[0].to_i + 1).to_s
  end

  def increase_use_count(word)
    line_words = @lines.map {|line| line.split(',')[1]}
    index = line_words.index(word)
    line = @lines[index].split(',')
    line[3] = (line[3].to_i + 1).to_s
    @lines[index] = line.join(',')
  end

  def delete_word(word)
    file_overwriter = open_file('w')
    @lines.delete(word + "\n")
    file_overwriter.syswrite(@lines.join(''))
    file_overwriter.close()
  end

  def close
    file_overwriter = open_file('w')

    @lines.map! do |line|
      line += "\n" unless line[-1] == "\n"
      line
    end

    file_overwriter.syswrite(@lines.join(''))
    file_overwriter.close()

    @file_handler.close
  end

  private

  def readlines
    file_reader = open_file('r')
    lines = file_reader.readlines
    file_reader.close()

    lines
  end

  def open_file(mode)
    File.open(@path_of_file, mode)
  end

  def add_columns
    @columns.each do |column|
      @file_handler.syswrite(column + ',') unless column == @columns.last
    end
    
    @file_handler.syswrite(@columns.last + "\n")
    @lines = readlines
  end

  def word_text(**args)
    "#{args[:id]},#{args[:name]},#{args[:meaning]},#{args[:use_count]}"
  end
end

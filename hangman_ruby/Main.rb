$LOAD_PATH << '.'

require 'HangmanGame'
require 'MyGuessingStrategy'
require 'set'

MAX_WRONG_GUESSES = ENV['hangman_guesses'] || 5
DICT_FILE = ENV['hangman_dict'] || 'words.txt'
DEBUG = ENV['hangman_debug']

dict = Set.new
begin
  File.open(DICT_FILE, 'rb') do |f|
    f.each_line do |line|
      word = line.chomp
      dict << word.upcase if word.size > 0
    end
  end
rescue SystemCallError
  $stderr << "Cannot open dictionary file '%s' for reading!\n" % DICT_FILE
  exit(false)
end

strategy = MyGuessingStrategy.new(dict)
totalScore = 0
total = 0
isatty = $stdin.isatty
while true do
  begin
    $stderr << "Enter a word:\n" if isatty
    word = $stdin.readline.strip.upcase
    if word.size == 0 then
      raise EOFError
    elsif !dict.include?(word) then
      $stderr << "Word '%s' is not in dicitionary!\n" % word
      next
    end

    $stderr << "New Game [%s]\n" % word if DEBUG
    game = HangmanGame.new(word, MAX_WRONG_GUESSES)
    score = game.run(strategy, DEBUG)
    totalScore += score
    total += 1
    $stdout << "%s = %d\n" % [word, score]

  rescue EOFError
    break
  end
end

$stdout << "-----------------------------\nAVG: %g\nNUM: %d\nTOTAL: %d\n" % \
  [1.0 * totalScore / total, total, totalScore] if total > 0

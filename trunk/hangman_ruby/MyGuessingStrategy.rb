require 'HangmanGame'
require 'GuessingStrategy'
require 'GuessLetter'
require 'GuessWord'
require 'set'

def assert(cond)
  raise if !cond
end

class String
  # If a string has any characters in set chars, return true, otherwise false.
  def has_any(chars)
    self.each_char do |ch|
      return true if chars.include?(ch)
    end
    false
  end
end

class MyGuessingStrategy < GuessingStrategy

  # A WordSet is a set of words all having the same pattern.
  # e.g. Given a pattern "AB-", the words may be {"ABC", "ABD", "ABX"}
  # A WordSet also contains statistical info about the words in it, such as
  # letter occurrence times.
  class WordSet

    class LetterStat
      attr_accessor :frequency, :wordCount

      @frequency
      @wordCount

      def initialize
        @frequency = 0
        @wordCount = 0
      end

    end

    # Words in the set.
    @words

    # A map of letters to LetterStats.
    @stat

    # Letters in descendent order on frequency
    @order

    def initialize
      @words = []
      @stat = Hash.new {|h, k| h[k] = LetterStat.new }
    end

    # Insert a new word to the word set, and update the letter statistical info.
    # Letters in the excluded set are not counted for the statistical info.
    def update(word, excluded = nil)
      parsed = Set.new
      word.each_char do |ch|
        if !excluded || !excluded.include?(ch) then
          stat = @stat[ch]
          stat.frequency += 1
          if parsed.add?(ch) then
            stat.wordCount += 1
          end
        end
      end
      @words << word
      self
    end

    def wordCount
      @words.size
    end

    def words
      @words
    end

    # Give a suggest of the most probable letter not in the excluded letter set.
    # When given a pos, start searching @order from it.
    def suggest(excluded, pos = 0)
      if !@order then
        makeOrder
      end
      i = pos
      while i < @order.size do
        if !excluded.include?(@order[i]) then
          return @order[i], i + 1
        end
        i += 1
      end
      assert(false)
    end


    private

    # Sort letters in a word set on their frquencies in descending order.
    def makeOrder
      order = @stat.sort do |l, r|
        l, r = l[1], r[1]
        if l.frequency > r.frequency then
          -1
        elsif l.frequency == r.frequency then
          l.wordCount <=> r.wordCount
        else
          1
        end
      end

      @order = order.map {|e| e[0]}
      self.freeze
    end

  end

  # An array of maps of patterns to their WordSets.
  # Given a pattern P, its WordSet can be retrieved by patternMapGroup[P.length - 1][P]
  @patternMapGroup

  # Initialize with a dictionary of words.
  def initialize(dict)
    @patternMapGroup = []
    patterns = []

    dict.each do |word|
      word = word.upcase
      len = word.length
      pattern = patterns[len]
      if !pattern then
        pattern = patterns[len] = HangmanGame::MYSTERY_LETTER * len
      end

      words = @patternMapGroup[len - 1]
      if !words then
        words = @patternMapGroup[len - 1] = Hash.new {|h, k| h[k] = WordSet.new}
      end
      words[pattern].update(word)
    end
  end

  def nextGuess(game)
    pattern = game.getGuessedSoFar # This line clearly explains what a "pattern" is.
    wordset = wordSet(pattern)
    guess = suggest(pattern, wordset, game)
    guess.length == 1 ? GuessLetter.new(guess) : GuessWord.new(guess)
  end

  private

  def wordSet(pattern)
    set = @patternMapGroup[pattern.length() - 1][pattern]
    set.wordCount > 0 ? set : newWordSet(pattern)
  end

  # Make a new WordSet to the pattern.
  def newWordSet(pattern)
    len = pattern.length
    map = @patternMapGroup[len - 1]

    # Find the smallest "parent" pattern collection
    i = 0
    parentWordSet = nil
    parentPattern = nil
    patternChars = Set.new # e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
    while i < len do
      ch = pattern[i]
      if ch != HangmanGame::MYSTERY_LETTER && patternChars.add?(ch) then
        copy = String.new(pattern)
        copy[i] = HangmanGame::MYSTERY_LETTER
        j = i + 1
        while j < len do
          if copy[j] == ch then
            copy[j] = HangmanGame::MYSTERY_LETTER
          end
          j += 1
        end

        wordset = map.fetch(copy, nil) # [] may return a default value
        if wordset && (!parentWordSet || parentWordSet.wordCount > wordset.wordCount) then
          parentWordSet = wordset
          parentPattern = copy
        end
      end

      i += 1
    end

    assert(parentPattern)

    # Draw the new pattern collection and info through filtering the parent
    newSet = map[pattern]
    parentWordSet.words.each do |word|
      if self.class.match(pattern, word, patternChars) then
        newSet.update(word, patternChars)
      end
    end

    newSet
  end

  # Suggest a letter or word.
  def suggest(pattern, wordset, game)
    # If the pattern collection has only one word, that's it!
    if wordset.wordCount == 1 then
      return wordset.words.first
    end

    # Make a guess, according to letter frequency of a pattern.
    word = nil
    wrongLetters = game.getIncorrectlyGuessedLetters
    wrongWords = game.getIncorrectlyGuessedWords
    patternBlanks = pattern.count(HangmanGame::MYSTERY_LETTER) # Number of '-' characters in a pattern.

    if patternBlanks > 1 then
      if game.numWrongGuessesRemaining == 0 then
        word = finalBlow(pattern, wordset, wrongLetters)
      else
        word, _ = wordset.suggest(wrongLetters)
      end
    else
      i = 0
      while true do
        ch, i = wordset.suggest(wrongLetters, i)
        word = pattern.sub(HangmanGame::MYSTERY_LETTER, ch)
        if !wrongWords.include?(word) then
          break
        else
          wrongLetters.add(ch)
        end
      end
    end

    assert(word)
    word
  end

  # When we have a last chance to make a guess and there're more than one blanks
  # in a pattern, we do the final blow! The basic idea is to select a word, which
  # dosn't contain those wrong guessed letters while having the most probable
  # letter given by a WordSet#suggets.
  def finalBlow(pattern, wordset, wrongLetters)
    candidates = []
    i = 0
    ch, i = wordset.suggest(wrongLetters, i)

    wordset.words.each do |word|
      if !word.has_any(wrongLetters) then
        candidates << word
        if word.index(ch) then
          return word
        end
      end
    end

    guess = nil
    while !guess do
      ch, i = wordset.suggest(wrongLetters, i)
      candidates.each do |word|
        if word.index(ch) then
          guess = word
          break
        end
      end
    end

    guess
  end

  # Return true only when str matches pattern EXACTLY(a pattern is a string returned
  # by HangmanGame#getGuessedSoFar). e.g. given pattern "AB-", string "ABC" and
  # "ABD" match it, while "ABA" "ABB" and "XYZ" DON'T. In the same example,
  # the patternChars argument must be {'A', 'B'}
  def self.match(pattern, str, patternChars)
    size = pattern.size
    assert(size == str.size)

    ret = true
    i = 0
    while i < size do
      if pattern[i] != HangmanGame::MYSTERY_LETTER then
        if pattern[i] != str[i] then
          ret = false
          break
        end
      else
        if patternChars.include?(str[i]) then
          ret = false
          break
        end
      end
      i += 1
    end

    ret
  end

end

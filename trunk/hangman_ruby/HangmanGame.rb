require 'set'

class HangmanGame
  # A marker for the letters in the secret words that have not been guessed yet.
  MYSTERY_LETTER = '-'

  # The word that needs to be guessed (e.g. 'FACTUAL')
  @secretWord

  # The maximum number of wrong letter/word guesses that are allowed (e.g. 6, and if you exceed 6 then you lose)
  @maxWrongGuesses

  # The letters guessed so far (unknown letters will be marked by the MYSTERY_LETTER constant). For example, 'F-CTU-L'
  @guessedSoFar

  # Set of all correct letter guesses so far (e.g. 'C', 'F', 'L', 'T', 'U')
  @correctlyGuessedLetters

  # Set of all incorrect letter guesses so far (e.g. 'R', 'S')
  @incorrectlyGuessedLetters

  # Set of all incorrect word guesses so far (e.g. 'FACTORS')
  @incorrectlyGuessedWords

  def initialize(secretWord, maxWrongGuesses)
    @secretWord = secretWord.upcase
    @guessedSoFar = MYSTERY_LETTER * secretWord.length
    @maxWrongGuesses = maxWrongGuesses
    @correctlyGuessedLetters = Set.new
    @incorrectlyGuessedLetters = Set.new
    @incorrectlyGuessedWords = Set.new
  end

  # Guess the specified letter and update the game state accordingly
  # @return The string representation of the current game state
  # (which will contain MYSTERY_LETTER in place of unknown letters)
  def guessLetter(ch)
    assertCanKeepGuessing
    ch = ch.upcase

    # update the guessedSoFar buffer with the new character
    goodGuess = false
    i = 0
    while i < @secretWord.size do
      if @secretWord[i] == ch then
        @guessedSoFar[i] = ch
        goodGuess = true
      end
      i += 1
    end

    # update the proper set of guessed letters
    if goodGuess then
      @correctlyGuessedLetters.add(ch)
    else
      @incorrectlyGuessedLetters.add(ch)
    end

    getGuessedSoFar
  end

  # Guess the specified word and update the game state accordingly
  # @return The string representation of the current game state
  # (which will contain MYSTERY_LETTER in place of unknown letters)
  def guessWord(guess)
    assertCanKeepGuessing
    guess = guess.upcase

    if guess == @secretWord then
      # if the guess is correct, then set guessedSoFar to the secret word
      @guessedSoFar = @secretWord
    else
      @incorrectlyGuessedWords.add(guess)
    end

    getGuessedSoFar
  end

  # @return The score for the current game state
  def currentScore
    gameStatus == :GAME_LOST ? 25 : numWrongGuessesMade + @correctlyGuessedLetters.size
  end

  def assertCanKeepGuessing
    if gameStatus != :KEEP_GUESSING then
      raise "Cannot keep guessing in current game state: %s" % gameStatus
    end
  end
  private :assertCanKeepGuessing

  # @return The current game status
  def gameStatus
    if @secretWord == @guessedSoFar then
      :GAME_WON
    elsif numWrongGuessesMade > @maxWrongGuesses then
      :GAME_LOST
    else
      :KEEP_GUESSING
    end
  end

  # @return Number of wrong guesses made so far
  def numWrongGuessesMade
    @incorrectlyGuessedLetters.size + @incorrectlyGuessedWords.size
  end

  # @return Number of wrong guesses still allowed
  def numWrongGuessesRemaining
    @maxWrongGuesses - numWrongGuessesMade
  end

  # @return Number of total wrong guesses allowed
  def getMaxWrongGuesses
    @maxWrongGuesses
  end

  # @return The string representation of the current game state
  # (which will contain MYSTERY_LETTER in place of unknown letters)
  def getGuessedSoFar
    String.new(@guessedSoFar)
  end

  # @return Set of all correctly guessed letters so far
  def getCorrectlyGuessedLetters
    Set.new(@correctlyGuessedLetters)
  end

  # @return Set of all incorrectly guessed letters so far
  def getIncorrectlyGuessedLetters
    Set.new(@incorrectlyGuessedLetters)
  end

  # @return Set of all guessed letters so far
  def getAllGuessedLetters
    guessed = Set.new
    guessed.merge(@correctlyGuessedLetters)
    guessed.merge(@incorrectlyGuessedLetters)
  end

  # @return Set of all incorrectly guessed words so far
  def getIncorrectlyGuessedWords
    Set.new(@incorrectlyGuessedWords)
  end

  # @return The length of the secret word
  def getSecretWordLength
    @secretWord.length
  end

  def to_s
    "%s; score=%d; status=%s" % [@guessedSoFar, currentScore, gameStatus]
  end

  def run(strategy, debugOut)
    while gameStatus == :KEEP_GUESSING do
      $stderr << "%s\n" % self if debugOut
      guess = strategy.nextGuess(self)
      $stderr << "%s\n" % self if debugOut
      guess.makeGuess(self)
    end

    $stderr << "%s\n" % self if debugOut
    currentScore
  end

end


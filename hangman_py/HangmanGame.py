import sys

class HangmanGame:
  # A marker for the letters in the secret words that have not been guessed yet.
  MYSTERY_LETTER = '-'

  def __init__(self, secretWord, maxWrongGuesses):
    # The word that needs to be guessed (e.g. 'FACTUAL')
    self.__secretWord = secretWord.upper()

    # The letters guessed so far (unknown letters will be marked by the MYSTERY_LETTER constant). For example, 'F-CTU-L'
    self.__guessedSoFar = HangmanGame.MYSTERY_LETTER * len(secretWord)

    # The maximum number of wrong letter/word guesses that are allowed (e.g. 6, and if you exceed 6 then you lose)
    self.__maxWrongGuesses = maxWrongGuesses

    # Set of all correct letter guesses so far (e.g. 'C', 'F', 'L', 'T', 'U')
    self.__correctlyGuessedLetters = set()

    # Set of all incorrect letter guesses so far (e.g. 'R', 'S')
    self.__incorrectlyGuessedLetters = set()

    # Set of all incorrect word guesses so far (e.g. 'FACTORS')
    self.__incorrectlyGuessedWords = set()

  # Guess the specified letter and update the game state accordingly
  # @return The string representation of the current game state
  # (which will contain MYSTERY_LETTER in place of unknown letters)
  def guessLetter(self, ch):
    self.__assertCanKeepGuessing()
    ch = ch.upper()

    # update the guessedSoFar buffer with the new character
    goodGuess = False
    guessedSoFar = list(self.__guessedSoFar)
    i = 0
    while i < len(self.__secretWord):
      if self.__secretWord[i] == ch:
        guessedSoFar[i] = ch
        goodGuess = True
      i += 1
    self.__guessedSoFar = ''.join(guessedSoFar)

    # update the proper set of guessed letters
    if goodGuess:
      self.__correctlyGuessedLetters.add(ch)
    else:
      self.__incorrectlyGuessedLetters.add(ch)

    return self.getGuessedSoFar()

  # Guess the specified word and update the game state accordingly
  # @return The string representation of the current game state
  # (which will contain MYSTERY_LETTER in place of unknown letters)
  def guessWord(self, guess):
    self.__assertCanKeepGuessing()
    guess = guess.upper()

    if guess == self.__secretWord:
      # if the guess is correct, then set guessedSoFar to the secret word
      self.__guessedSoFar = self.__secretWord
    else:
      self.__incorrectlyGuessedWords.add(guess)

    return self.getGuessedSoFar()

  # @return The score for the current game state
  def currentScore(self):
    return 25 if self.gameStatus() == 'GAME_LOST' else self.numWrongGuessesMade() + len(self.__correctlyGuessedLetters)

  def __assertCanKeepGuessing(self):
    assert self.gameStatus() == 'KEEP_GUESSING', "Cannot keep guessing in current game state: %s" % gameStatus

  # @return The current game status
  def gameStatus(self):
    if self.__secretWord == self.__guessedSoFar:
      return 'GAME_WON'
    elif self.numWrongGuessesMade() > self.__maxWrongGuesses:
      return 'GAME_LOST'
    else:
      return 'KEEP_GUESSING'

  # @return Number of wrong guesses made so far
  def numWrongGuessesMade(self):
    return len(self.__incorrectlyGuessedLetters) + len(self.__incorrectlyGuessedWords)

  # @return Number of wrong guesses still allowed
  def numWrongGuessesRemaining(self):
    return self.__maxWrongGuesses - self.numWrongGuessesMade()

  # @return Number of total wrong guesses allowed
  def getMaxWrongGuesses(self):
    return self.__maxWrongGuesses

  # @return The string representation of the current game state
  # (which will contain MYSTERY_LETTER in place of unknown letters)
  def getGuessedSoFar(self):
    return self.__guessedSoFar

  # @return Set of all correctly guessed letters so far
  def getCorrectlyGuessedLetters(self):
    return set(self.__correctlyGuessedLetters)

  # @return Set of all incorrectly guessed letters so far
  def getIncorrectlyGuessedLetters(self):
    return set(self.__incorrectlyGuessedLetters)

  # @return Set of all guessed letters so far
  def getAllGuessedLetters(self):
    return self.__correctlyGuessedLetters | self.__incorrectlyGuessedLetters

  # @return Set of all incorrectly guessed words so far
  def getIncorrectlyGuessedWords(self):
    return set(self.__incorrectlyGuessedWords)

  # @return The length of the secret word
  def getSecretWordLength(self):
    return len(self.__secretWord)

  def __str__(self):
    return "%s; score=%d; status=%s" % (self.__guessedSoFar, self.currentScore(), self.gameStatus())

  def run(self, strategy, debugOut):
    while self.gameStatus() == 'KEEP_GUESSING':
      if debugOut:
        print >> sys.stderr, "%s" % self
      guess = strategy.nextGuess(self)
      if debugOut:
        print >> sys.stderr, "%s" % guess
      guess.makeGuess(self)

    if debugOut:
      print >> sys.stderr, "%s" % self

    return self.currentScore()

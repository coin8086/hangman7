module(..., package.seeall)

local cl = require "cl"
local Set = require 'Set'
require "ext"

HangmanGame = cl.makeClass {
  -- A marker for the letters in the secret words that have not been guessed yet.
  MYSTERY_LETTER = '-',

  init = function(self, secretWord, maxWrongGuesses)
    -- The word that needs to be guessed (e.g. 'FACTUAL')
    self.secretWord = {}

    -- The letters guessed so far (unknown letters will be marked by the MYSTERY_LETTER constant). For example, 'F-CTU-L'
    self.guessedSoFar = {}

    secretWord = secretWord:upper()
    for i = 1, #secretWord do
      self.secretWord[i] = secretWord:charAt(i)
      self.guessedSoFar[i] = HangmanGame.MYSTERY_LETTER
    end

    -- The maximum number of wrong letter/word guesses that are allowed (e.g. 6, and if you exceed 6 then you lose)
    self.maxWrongGuesses = maxWrongGuesses

    -- Set of all correct letter guesses so far (e.g. 'C', 'F', 'L', 'T', 'U')
    self.correctlyGuessedLetters = Set()

    -- Set of all incorrect letter guesses so far (e.g. 'R', 'S')
    self.incorrectlyGuessedLetters = Set()

    -- Set of all incorrect word guesses so far (e.g. 'FACTORS')
    self.incorrectlyGuessedWords = Set()
  end,

  -- Guess the specified letter and update the game state accordingly
  -- self.return The string representation of the current game state
  -- (which will contain MYSTERY_LETTER in place of unknown letters)
  guessLetter = function(self, ch)
    self:assertCanKeepGuessing()
    ch = ch:upper()

    -- update the guessedSoFar buffer with the new character
    local goodGuess = false
    local i = 1
    while i <= #self.secretWord do
      if self.secretWord[i] == ch then
        self.guessedSoFar[i] = ch
        goodGuess = true
      end
      i = i + 1
    end

    -- update the proper set of guessed letters
    if goodGuess then
      self.correctlyGuessedLetters:add(ch)
    else
      self.incorrectlyGuessedLetters:add(ch)
    end

    return self:getGuessedSoFar()
  end,

  -- Guess the specified word and update the game state accordingly
  -- self.return The string representation of the current game state
  -- (which will contain MYSTERY_LETTER in place of unknown letters)
  guessWord = function(self, guess)
    self:assertCanKeepGuessing()
    guess = guess:upper()

    if guess == table.concat(self.secretWord) then
      -- if the guess is correct, then set guessedSoFar to the secret word
      self.guessedSoFar = self.secretWord
    else
      self.incorrectlyGuessedWords:add(guess)
    end

    return self:getGuessedSoFar()
  end,

  -- self.return The score for the current game state
  currentScore = function(self)
    if self:gameStatus() == "GAME_LOST" then
      return 25
    else
      return self:numWrongGuessesMade() + self.correctlyGuessedLetters:size()
    end
  end,

  assertCanKeepGuessing = function(self)
    assert(self:gameStatus() == "KEEP_GUESSING", "Cannot keep guessing in current game state: " .. self:gameStatus())
  end,

  -- self.return The current game status
  gameStatus = function(self)
    if self.secretWord == self.guessedSoFar then
      return "GAME_WON"
    elseif self:numWrongGuessesMade() > self.maxWrongGuesses then
      return "GAME_LOST"
    else
      return "KEEP_GUESSING"
    end
  end,

  -- self.return Number of wrong guesses made so far
  numWrongGuessesMade = function(self)
    return self.incorrectlyGuessedLetters:size() + self.incorrectlyGuessedWords:size()
  end,

  -- self.return Number of wrong guesses still allowed
  numWrongGuessesRemaining = function(self)
    return self.maxWrongGuesses - self:numWrongGuessesMade()
  end,

  -- self.return Number of total wrong guesses allowed
  getMaxWrongGuesses = function(self)
    return self.maxWrongGuesses
  end,

  -- self.return The string representation of the current game state
  -- (which will contain MYSTERY_LETTER in place of unknown letters)
  getGuessedSoFar = function(self)
    return table.concat(self.guessedSoFar)
  end,

  -- self.return Set of all correctly guessed letters so far
  getCorrectlyGuessedLetters = function(self)
    return Set(self.correctlyGuessedLetters)
  end,

  -- self.return Set of all incorrectly guessed letters so far
  getIncorrectlyGuessedLetters = function(self)
    return Set(self.incorrectlyGuessedLetters)
  end,

  -- self.return Set of all guessed letters so far
  getAllGuessedLetters = function(self)
    local guessed = Set(self.correctlyGuessedLetters)
    return guessed.merge(self.incorrectlyGuessedLetters)
  end,

  -- self.return Set of all incorrectly guessed words so far
  getIncorrectlyGuessedWords = function(self)
    return Set(self.incorrectlyGuessedWords)
  end,

  -- self.return The length of the secret word
  getSecretWordLength = function(self)
    return #self.secretWord
  end,

  __tostring = function(self)
    return string.format("%s; score=%d; status=%s", table.concat(self.guessedSoFar), self:currentScore(), self:gameStatus())
  end,

  run = function(self, strategy, debugOut)
    while self:gameStatus() == "KEEP_GUESSING" do
      if debugOut then
        io.stderr:write(tostring(self), "\n")
      end
      guess = strategy:nextGuess(self)
      if debugOut then
        io.stderr:write(tostring(guess), "\n")
      end
      guess:makeGuess(self)
    end

    if debugOut then
      io.stderr:write(tostring(self), "\n")
    end
    return self:currentScore()
  end,
}

return HangmanGame

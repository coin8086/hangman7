module(..., package.seeall)

Guess = require "Guess"
cl = require "cl"

-- A Guess that represents guessing a word for the current Hangman game

GuessWord = cl.makeClass({
  init = function(self, guess)
    self.guess = guess
  end,

  makeGuess = function(self, game)
    game:guessWord(self.guess)
  end,

  __tostring = function(self)
    return string.format("GuessWord[%s]", self.guess)
  end

}, Guess)

return GuessWord

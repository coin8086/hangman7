module(..., package.seeall)

Guess = require "Guess"
cl = require "cl"

-- A Guess that represents guessing a letter for the current Hangman game

GuessLetter = cl.makeClass({
  init = function(self, guess)
    self.guess = guess
  end,

  makeGuess = function(self, game)
    game:guessLetter(self.guess)
  end,

  __tostring = function(self)
    return string.format("GuessLetter[%s]", self.guess)
  end

}, Guess)

return GuessLetter

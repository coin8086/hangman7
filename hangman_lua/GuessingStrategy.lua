module(..., package.seeall)

cl = require "cl"

-- A strategy for generating guesses given the current state of a Hangman game.

GuessingStrategy = cl.makeClass {
  nextGuess = function(self, game)
    assert(false, "Not implemented!")
  end
}

return GuessingStrategy

module(..., package.seeall)

cl = require "cl"

Guess = cl.makeClass {
  -- Applies the current guess to the specified game.
  -- @param game The game to make the guess on.
  makeGuess = function(self, game)
    assert(false, "Not implemented!")
  end
}

return Guess

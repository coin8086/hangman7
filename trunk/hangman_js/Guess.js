"use strict"

/**
 * Common interface for GuessWord and GuessLetter
 */
function Guess() {
}

/**
 * Applies the current guess to the specified game.
 * @param game The game to make the guess on.
 */
Guess.prototype.makeGuess = function(game) {
  throw "Not implemented!";
}

exports.Guess = Guess;

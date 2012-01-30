"use strict"

/**
 * A strategy for generating guesses given the current state of a Hangman game.
 */
function GuessingStrategy() {
}

GuessingStrategy.prototype.nextGuess = function(game) {
  throw "Not implemented!";
};

exports.GuessingStrategy = GuessingStrategy;

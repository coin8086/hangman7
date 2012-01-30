"use strict"

var Guess = require("./Guess.js").Guess;

/**
 * A Guess that represents guessing a letter for the current Hangman game
 */
function GuessLetter(guess) {
  this.guess = guess;
}

GuessLetter.prototype = new Guess();
GuessLetter.prototype.constructor = GuessLetter;

GuessLetter.prototype.makeGuess = function(game) {
  game.guessLetter(this.guess);
}

GuessLetter.prototype.toString = function() {
  return "GuessLetter[" + this.guess + "]";
}

exports.GuessLetter = GuessLetter;

"use strict"

var Guess = require("./Guess.js").Guess;

/**
 * A Guess that represents guessing a word for the current Hangman game
 */
function GuessWord(guess) {
  this.guess = guess;
}

GuessWord.prototype = new Guess();
GuessWord.prototype.constructor = GuessWord;

GuessWord.prototype.makeGuess = function(game) {
  game.guessWord(this.guess);
}

GuessWord.prototype.toString = function() {
  return "GuessWord[" + this.guess + "]";
}

exports.GuessWord = GuessWord;

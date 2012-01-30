"use strict"

var Set = require("./Set.js").Set;

/**
 * @param secretWord The word that needs to be guessed
 * @param maxWrongGuesses The maximum number of incorrect word/letter guesses that are allowed
 */
function HangmanGame(secretWord, maxWrongGuesses) {
  // The word that needs to be guessed (e.g. 'FACTUAL')
  this.secretWord = secretWord.toUpperCase();
  // The letters guessed so far (unknown letters will be marked by the MYSTERY_LETTER constant). For example, 'F-CTU-L'
  this.guessedSoFar = [];
  for (var i = 0; i < secretWord.length; i++) {
    this.guessedSoFar[i] = HangmanGame.MYSTERY_LETTER;
  }
  // The maximum number of wrong letter/word guesses that are allowed (e.g. 6, and if you exceed 6 then you lose)
  this.maxWrongGuesses = maxWrongGuesses;
  // Set of all correct letter guesses so far (e.g. 'C', 'F', 'L', 'T', 'U')
  this.correctlyGuessedLetters = new Set();
  // Set of all incorrect letter guesses so far (e.g. 'R', 'S')
  this.incorrectlyGuessedLetters = new Set();
  // Set of all incorrect word guesses so far (e.g. 'FACTORS')
  this.incorrectlyGuessedWords = new Set();
}

// A marker for the letters in the secret words that have not been guessed yet.
HangmanGame.MYSTERY_LETTER = '-';

/**
 * Guess the specified letter and update the game state accordingly
 * @return The string representation of the current game state
 * (which will contain MYSTERY_LETTER in place of unknown letters)
 */
HangmanGame.prototype.guessLetter = function(ch) {
  this.assertCanKeepGuessing();
  ch = ch.toUpperCase();

  // update the guessedSoFar buffer with the new character
  var goodGuess = false;
  for (var i = 0; i < this.secretWord.length; i++) {
    if (this.secretWord.charAt(i) == ch) {
      this.guessedSoFar[i] = ch;
      goodGuess = true;
    }
  }

  // update the proper set of guessed letters
  if (goodGuess) {
    this.correctlyGuessedLetters.add(ch);
  }
  else {
    this.incorrectlyGuessedLetters.add(ch);
  }

  return this.getGuessedSoFar();
}

/**
 * Guess the specified word and update the game state accordingly
 * @return The string representation of the current game state
 * (which will contain MYSTERY_LETTER in place of unknown letters)
 */
HangmanGame.prototype.guessWord = function(guess) {
  this.assertCanKeepGuessing();
  guess = guess.toUpperCase();

  if (guess == this.secretWord) {
    // if the guess is correct, then set guessedSoFar to the secret word
    for (var i = 0; i < this.secretWord.length; i++) {
      this.guessedSoFar[i] = this.secretWord.charAt(i);
    }
  }
  else {
    this.incorrectlyGuessedWords.add(guess);
  }

  return this.getGuessedSoFar();
}

/**
 * @return The score for the current game state
 */
HangmanGame.prototype.currentScore = function() {
  if (this.gameStatus() == "GAME_LOST") {
    return 25;
  }
  else {
    return this.numWrongGuessesMade() + this.correctlyGuessedLetters.size();
  }
}

HangmanGame.prototype.assertCanKeepGuessing = function() {
  if (this.gameStatus() != "KEEP_GUESSING") {
    throw "Cannot keep guessing in current game state: " + this.gameStatus();
  }
}

/**
 * @return The current game status
 */
HangmanGame.prototype.gameStatus = function() {
  if (this.secretWord == this.getGuessedSoFar()) {
    return "GAME_WON";
  }
  else if (this.numWrongGuessesMade() > this.maxWrongGuesses) {
    return "GAME_LOST";
  }
  else {
    return "KEEP_GUESSING";
  }
}

/**
 * @return Number of wrong guesses made so far
 */
HangmanGame.prototype.numWrongGuessesMade = function() {
  return this.incorrectlyGuessedLetters.size() + this.incorrectlyGuessedWords.size();
}

/**
 * @return Number of wrong guesses still allowed
 */
HangmanGame.prototype.numWrongGuessesRemaining = function() {
  return this.getMaxWrongGuesses() - this.numWrongGuessesMade();
}

/**
 * @return Number of total wrong guesses allowed
 */
HangmanGame.prototype.getMaxWrongGuesses = function() {
  return this.maxWrongGuesses;
}

/**
 * @return The string representation of the current game state
 * (which will contain MYSTERY_LETTER in place of unknown letters)
 */
HangmanGame.prototype.getGuessedSoFar = function() {
  return this.guessedSoFar.join("");
}

/**
 * @return Set of all correctly guessed letters so far
 */
HangmanGame.prototype.getCorrectlyGuessedLetters = function() {
  return new Set(this.correctlyGuessedLetters);
}

/**
 * @return Set of all incorrectly guessed letters so far
 */
HangmanGame.prototype.getIncorrectlyGuessedLetters = function() {
  return new Set(this.incorrectlyGuessedLetters);
}

/**
 * @return Set of all guessed letters so far
 */
HangmanGame.prototype.getAllGuessedLetters = function() {
  var guessed = new Set();
  guessed.addAll(this.correctlyGuessedLetters);
  guessed.addAll(this.incorrectlyGuessedLetters);
  return guessed;
}

/**
 * @return Set of all incorrectly guessed words so far
 */
HangmanGame.prototype.getIncorrectlyGuessedWords = function() {
  return new Set(this.incorrectlyGuessedWords);
}

/**
 * @return The length of the secret word
 */
HangmanGame.prototype.getSecretWordLength = function() {
  return this.secretWord.length;
}

HangmanGame.prototype.toString = function() {
  return this.getGuessedSoFar() + "; score=" + this.currentScore() + "; status=" + this.gameStatus();
}

HangmanGame.prototype.run = function(strategy, debugOut) {
  while(this.gameStatus() == "KEEP_GUESSING") {
    if (debugOut)
      console.error(this.toString());
    var guess = strategy.nextGuess(this);
    if (debugOut)
      console.error(guess.toString());
    guess.makeGuess(this);
  }
  if (debugOut)
    console.error(this.toString());
  return this.currentScore();
}

exports.HangmanGame = HangmanGame;

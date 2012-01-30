"use strict"

var GuessingStrategy = require("./GuessingStrategy.js").GuessingStrategy;
var GuessLetter = require("./GuessLetter.js").GuessLetter;
var GuessWord = require("./GuessWord.js").GuessWord;
var HangmanGame = require("./HangmanGame.js").HangmanGame;
var Set = require("./Set.js").Set;

/**
 * If a string has any characters in set chars, return true, otherwise false.
 */
String.prototype.hasAny = function(chars) {
  for (var i = 0; i < this.length; i++) {
    if (chars.contains(this.charAt(i)))
      return true;
  }
  return false;
}

function LetterStat() {
  this.frequency = 0;  //How many times the letter appears in a WordSet
  this.wordCount = 0;  //How many words contains the letter in a WordSet
}

/**
 * A WordSet is a set of words all having the same pattern.
 * e.g. Given a pattern "AB-", the words may be {"ABC", "ABD", "ABX"}
 * A WordSet also contains statistical info about the words in it, such as
 * letter occurrence times.
 */
function WordSet() {
  //A map of letters to their statistical info.
  this._stat = {};
  //Letters in descendent order on frequency
  this._order = null;
  //Words in the set.
  this._words = [];
}

WordSet.prototype.wordCount = function() {
  return this._words.length;
}

WordSet.prototype.words = function() {
  return this._words;
}

/**
 * Insert a new word to the word set, and update the letter statistical info.
 * Letters in the excluded set are not counted for the statistical info.
 */
WordSet.prototype.update = function(word, excluded) {
  var parsed = new Set();
  for (var i = 0; i < word.length; i++) {
    var ch = word.charAt(i);
    if (!excluded || !excluded.contains(ch)) {
      var stat = this._stat[ch];
      if (stat) {
        stat.frequency++;
        if (parsed.add(ch)) {
          stat.wordCount++;
        }
      }
      else {
        stat = new LetterStat();
        stat.frequency++;
        stat.wordCount++;
        this._stat[ch] = stat;
        parsed.add(ch);
      }
    }
  }
  this._words.push(word);
}

/**
 * Give a suggest of the most probable letter not in the excluded letter set.
 */
WordSet.prototype.suggest = function(excluded) {
  if (!this._order)
    this.makeOrder();
  for (var i = 0; i < this._order.length; i++) {
    if (!excluded.contains(this._order[i])) {
      return this._order[i];
    }
  }
  throw "Impossibility!";
}

/**
 * Sort letters in a word set on their frquencies in descending order.
 */
WordSet.prototype.makeOrder = function() {
  var tmp = [];
  for (var k in this._stat) {
    var v = this._stat[k];
    tmp.push({ch : k, frequency : v.frequency, wordCount : v.wordCount});
  }

  tmp.sort(function (a, b) {
    if (a.frequency > b.frequency)
      return -1;

    if (a.frequency == b.frequency)
      return a.wordCount - b.wordCount;

    return 1;
  });

  this._order = tmp.map(function (e) { return e.ch; });
  Object.freeze(this);
}

function MyGuessingStrategy(dict) {
  /**
   * An array of maps of patterns to their WordSets.
   * Given a pattern P, its WordSet can be retrieved by patternMapGroup[P.length - 1][P]
   */
  this.patternMapGroup = [];

  var patterns = [];
  dict.forEach(function(s) {
    s = s.toUpperCase();
    var len = s.length;
    var p = patterns[len - 1];
    if (!p) {
      var pattern = [];
      for (var i = 0; i < len; i++) {
        pattern[i] = HangmanGame.MYSTERY_LETTER;
      }
      p = pattern.join("");
      patterns[len - 1] = p;
    }
    this.insert(p, s);
  }, this);
}

MyGuessingStrategy.prototype = new GuessingStrategy();
MyGuessingStrategy.prototype.constructor = MyGuessingStrategy;

MyGuessingStrategy.prototype.nextGuess = function(game) {
  var pattern = game.getGuessedSoFar(); //This line clearly explains what a "pattern" is.
  var wordset = this.patternMapGroup[pattern.length - 1][pattern];
  if (!wordset) { //If no statistical info collected for the pattern, collect it now.
    wordset = this.newWordSet(pattern);
  }
  var n = this.suggest(pattern, wordset, game);
  if (n.length == 1) {
    return new GuessLetter(n.charAt(0));
  }
  else {
    return new GuessWord(n);
  }
}

/**
 * Insert a word and its pattern to patternMapGroup
 */
MyGuessingStrategy.prototype.insert = function(pattern, word) {
  console.assert(pattern.length == word.length);

  var len = pattern.length;
  var map = this.patternMapGroup[len - 1];
  if (map) {
    var set = map[pattern];
    if (!set) {
      set = new WordSet();
      map[pattern] = set;
    }
    set.update(word);
  }
  else {
    map = {};
    this.patternMapGroup[len - 1] = map;
    var set = new WordSet();
    map[pattern] = set;
    set.update(word);
  }
}

/**
 * Return true only when str matches pattern EXACTLY. A pattern is a string returned by HangmanGame::getGuessedSoFar.
 * e.g. given pattern "AB-", string "ABC" and "ABD" match it, while "ABA" "ABB" and "XYZ" DON'T. In the same
 * example, the patternChars argument must be {'A', 'B'}
 */
function match(pattern, str, patternChars) {
  console.assert(pattern.length == str.length);

  var size = pattern.length;
  var ret = true;
  for (var i = 0; i < size; i++) {
    if (pattern.charAt(i) != HangmanGame.MYSTERY_LETTER) {
      if (pattern.charAt(i) != str.charAt(i)) {
        ret = false;
        break;
      }
    }
    else {
      if (patternChars.contains(str.charAt(i))) {
        ret = false;
        break;
      }
    }
  }
  return ret;
}

/**
 * Make a new WordSet to the pattern.
 */
MyGuessingStrategy.prototype.newWordSet = function(pattern) {
  var len = pattern.length;
  var map = this.patternMapGroup[len - 1];

  //Find the smallest "parent" pattern collection
  var parentWordSet = null;
  var parentPattern = null;
  var patternChars = new Set(); //e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
  for (var i = 0; i < len; i++) {
    var ch = pattern.charAt(i);
    if (ch != HangmanGame.MYSTERY_LETTER && patternChars.add(ch)) {
      var copy = pattern.split("");
      copy[i] = HangmanGame.MYSTERY_LETTER;
      for (var j = i + 1; j < len; j++) {
        if (copy[j] == ch)
          copy[j] = HangmanGame.MYSTERY_LETTER;
      }

      var p = copy.join("");
      var set = map[p];
      if (set && (!parentWordSet || parentWordSet.wordCount() > set.wordCount())) {
        parentWordSet = set;
        parentPattern = p;
      }
    }
  }
  console.assert(parentWordSet);

  //Draw the new pattern collection and info through filtering the parent
  var newSet = new WordSet();
  map[pattern] = newSet;
  parentWordSet.words().forEach(function(word) {
    if (match(pattern, word, patternChars)) {
      newSet.update(word, patternChars);
    }
  });

  return newSet;
}

/**
 * When we have a last chance to make a guess and there're more than one blanks
 * in a pattern, we do the final blow! The basic idea is to select a word, which
 * dosn't contain those wrong guessed letters while has the most probable
 * letter given by a WordSet::suggest.
 */
MyGuessingStrategy.prototype.finalBlow = function(pattern, wordset, wrongLetters) {
  var guess = null;
  var candidates = [];
  var ch = wordset.suggest(wrongLetters);
  var words = wordset.words();

  for (var i = 0; i < words.length; i++) {
    var word = words[i];
    if (!word.hasAny(wrongLetters)) {
      candidates.push(word);
      if (word.indexOf(ch) != -1) {
        guess = word;
        break;
      }
    }
  }

  if (!guess) {
    var excluded = new Set(wrongLetters);
    while (!guess) {
      excluded.add(ch);
      ch = wordset.suggest(excluded);
      for (var i = 0; i < candidates.length; i++) {
        var word = candidates[i];
        if (word.indexOf(ch) != -1) {
          guess = word;
          break;
        }
      }
    }
  }

  console.assert(guess);
  return guess;
}

function numOfBlanks(pattern) {
  var count = 0;
  for (var i = 0; i < pattern.length; i++) {
    if (pattern.charAt(i) == HangmanGame.MYSTERY_LETTER)
      count++;
  }
  return count;
}

/**
 * Suggest a letter or word.
 */
MyGuessingStrategy.prototype.suggest = function(pattern, wordset, game) {
  //If the pattern collection has only one word, that's it!
  if (wordset.wordCount() == 1) {
    return wordset.words()[0];
  }

  //Make a guess, according to letter frequency of a pattern.
  var word = null;
  var wrongLetters = game.getIncorrectlyGuessedLetters();
  var wrongWords = game.getIncorrectlyGuessedWords();
  var patternBlanks = numOfBlanks(pattern); //Number of '-' characters in a pattern.

  if (patternBlanks > 1) {
    if (game.numWrongGuessesRemaining() == 0)
      word = this.finalBlow(pattern, wordset, wrongLetters);
    else {
      word = wordset.suggest(wrongLetters);
    }
  }
  else {
    var excluded = new Set(wrongLetters);
    while(true) {
      var ch = wordset.suggest(excluded);
      word = pattern.replace(HangmanGame.MYSTERY_LETTER, ch);
      if (!wrongWords.contains(word))
        break;
      else
        excluded.add(ch);
    }
  }

  console.assert(word);
  return word;
}

exports.MyGuessingStrategy = MyGuessingStrategy;

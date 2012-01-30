"use strict"

var fs = require("fs");
var tty = require("tty");
var HangmanGame = require("./HangmanGame.js").HangmanGame;
var MyGuessingStrategy = require("./MyGuessingStrategy.js").MyGuessingStrategy;
var Set = require("./Set.js").Set;

var env = process.env;
var file = env['hangman_dict'] || 'words.txt';
var guesses = env['hangman_guesses'] || 5;
var debug = env['hangman_debug'];

// Read in dictionary file
try {
  var content = fs.readFileSync(file, "ascii");
}
catch (e) {
  console.error("Cannot open dictionary file '%s' for reading!", file);
  process.exit(1);
}

var words = content.toUpperCase().match(/\w+/g);
var dict = new Set(words);

// Run game
var strategy = new MyGuessingStrategy(dict);
var totalScore = 0;
var total = 0;

function runGame(word) {
  if (debug)
    console.error("New Game [%s]", word);

  var game = new HangmanGame(word, guesses);
  var score = game.run(strategy, debug);
  totalScore += score;
  total++;
  console.log(word + " = " + score);
}

var concluded = false;
function conclude() {
  if (total > 0 && !concluded) {
    concluded = true;
    console.log("-----------------------------\nAVG: %d\nNUM: %d\nTOTAL: %d", totalScore / total, total, totalScore);
  }
}

process.stdin.setEncoding('ascii');
process.stdin.on('data', function (data) {
  if (tty.isatty(process.stdin)) {
    var word = data.trim();
    if (!word) {
      process.stdin.destroy();
    }
    else {
      word = word.toUpperCase();
      if (!dict.contains(word)) {
        console.error("Word '%s' is not in dicitionary!", word);
      }
      else {
        runGame(word);
      }
      console.error("Enter a word:");
    }
  }
  else {
    var words = data.toUpperCase().match(/\w+/g);
    for (var i = 0; i < words.length; i++) {
      var word = words[i].trim();
      if (word)
        runGame(word);
    }
  }
})
.on('close', function() { //What a fucking pair of close and end events!
  conclude();
})
.on('end', function() {
  conclude();
});

if (tty.isatty(process.stdin))
  console.error("Enter a word:");

process.stdin.resume();

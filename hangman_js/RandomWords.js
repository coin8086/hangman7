"use strict"

var fs = require("fs");
var Set = require("./Set.js").Set;

var env = process.env;
var file = env['hangman_dict'] || 'words.txt';

if (process.argv.length < 3) {
  console.error("A number of random words is expected but missing.");
  process.exit(1);
}

// Read in dictionary file
try {
  var content = fs.readFileSync(file, "ascii");
}
catch (e) {
  console.error("Cannot open dictionary file '%s' for reading!", file);
  process.exit(1);
}

var dict = content.toUpperCase().match(/\w+/g);

var count = Number(process.argv[2]);
if (isNaN(count) || count < 1 || count > dict.length) {
  console.error("%s is out of [1, %d]!", process.argv[2], dict.length);
  process.exit(1);
}

count = Math.ceil(count);

// Produce random words in dictionary
var size = dict.length;
var included = new Set();

function rand() {
  return Math.floor(Math.random() * size);
}

while (count > 0) {
  var r = Math.floor(rand() * 10 + rand() + Math.floor(rand() / (rand() + 1))) % size;
  if (included.add(r)) {
    console.log(dict[r]);
    count--;
  }
}

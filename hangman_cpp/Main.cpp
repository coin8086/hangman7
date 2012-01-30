#include <string>
#include <set>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "HangmanGame.h"
#include "MyGuessingStrategy.h"
#include "Utility.h"

#ifdef __GNUC__
#include <unistd.h> //isatty
#define _fileno fileno
#define _isatty isatty
#else
#include <io.h>     //_isatty
#endif

using namespace std;

int main(int argc, char * argv[]) {
  const char * file = getenv("hangman_dict");
  if (!file)
    file = "words.txt";

  int guesses = 5;
  const char * sguesses = getenv("hangman_guesses");
  if (sguesses) {
    guesses = atoi(sguesses);
    if (guesses < 1)
      guesses = 5;
  }

  bool debug = getenv("hangman_debug") ? true : false;

  FILE * f = fopen(file, "rb");
  if (!f) {
    fprintf(stderr, "Cannot open dictionary file '%s' for reading!\n", file);
    return -1;
  }

  // Read in dictionary file
  set<string> dict;
  while (!feof(f)) {
    string word = readWord(f);
    if (!word.empty()) {
      dict.insert(word);
    }
  }
  fclose(f);

  // Run game
  bool atty = _isatty(_fileno(stdin));
  MyGuessingStrategy strategy(dict);
  double totalScore = 0;
  int total = 0;

  while (!feof(stdin)) {
    if (atty)
      fprintf(stderr, "Enter a word:\n");

    string word = readWord(stdin);
    if (word.empty())
      break;

    if (!dict.count(word)) {
      fprintf(stderr, "Word '%s' is not in dicitionary!\n", word.c_str());
      continue;
    }

    if (debug)
      fprintf(stderr, "New Game [%s]\n", word.c_str());
    HangmanGame game(word, guesses);
    int score = game.run(strategy, debug);
    totalScore += score;
    total++;
    fprintf(stdout, "%s = %d\n", word.c_str(), score);
  }

  if (total > 0)
    fprintf(stdout, "-----------------------------\nAVG: %g\nNUM: %d\nTOTAL: %g\n",
      totalScore / total, total, totalScore);
  return 0;
}

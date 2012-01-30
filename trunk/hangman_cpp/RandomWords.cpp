#include <string>
#include <vector>
#include <set>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include "Utility.h"

using namespace std;

int main(int argc, char * argv[]) {
  if (argc < 2) {
    fprintf(stderr, "usage:\n%s <number-of-words>\n", argv[0]);
    return -1;
  }

  const char * file = getenv("hangman_dict");
  if (!file)
    file = "words.txt";

  FILE * f = fopen(file, "rb");
  if (!f) {
    fprintf(stderr, "Cannot open dictionary file '%s' for reading!\n", file);
    return -1;
  }

  // Read in dictionary file
  vector<string> dict;
  char wordbuf[1024];
  while (!feof(f)) {
    string word = readWord(f);
    if (!word.empty()) {
      dict.push_back(word);
    }
  }
  fclose(f);

  int count = atoi(argv[1]);
  if (count < 1 || count > dict.size()) {
    fprintf(stderr, "%s is not a number, or its value is out of [1, %d]\n", argv[1], dict.size());
    return -1;
  }

  // Produce random words in dictionary
  unsigned int size = dict.size();
  set<unsigned int> included;
  srand(time(NULL));

  while (count > 0) {
    unsigned int r = (unsigned int)(rand() * 10 + rand() + (rand() / (rand() + 1))) % size;
    if (included.insert(r).second) {
      fprintf(stdout, "%s\n", dict[r].c_str());
      count--;
    }
  }

  return 0;
}

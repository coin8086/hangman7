#include <set>
#include <algorithm>
#include <assert.h>

#include "MyGuessingStrategy.h"
#include "HangmanGame.h"
#include "Guess.h"
#include "GuessLetter.h"
#include "GuessWord.h"

////////////////////////////////////////////////////////////////////////////////
//
//  Class MyGuessingStrategy::WordSet
//

/**
 * Sort letters in a word set on their frquencies in descending order.
 */
void MyGuessingStrategy::WordSet::makeOrder() {
  assert(m_order.empty());

  vector<Pair> values(m_stat.begin(), m_stat.end());
  sort(values.begin(), values.end(), LessThan());
  m_order.resize(values.size());
  for (int i = 0; i < values.size(); i++) {
    m_order[i] = values[i].first;
  }
}

/**
 * Insert a new word to the word set, and update the letter statistical info.
 * Letters in the excluded set are not counted for the statistical info.
 */
void MyGuessingStrategy::WordSet::update(const string & word, const set<char> * excluded) {
  set<char> parsed;
  unsigned int i;
  for (i = 0; i < word.length(); i++) {
    char ch = word[i];
    if (!excluded || !excluded->count(ch)) {
      LetterStat & stat = m_stat[ch];
      stat.m_frequency++;
      if (parsed.insert(ch).second) {
        stat.m_wordCount++;
      }
    }
  }
  m_words.push_back(word);
}

/**
 * Give a suggest of the most probable letter not in the excluded letter set.
 * When given a pos, start searching m_order from it and update it to point to a new
 * starting index for the next call.
 */
char MyGuessingStrategy::WordSet::suggest(const set<char> & excluded, unsigned int * pos) {
  if (m_order.empty()) {
    makeOrder();
  }
  unsigned int i = pos ? *pos : 0;
  for (; i < m_order.size(); i++) {
    if (!excluded.count(m_order[i])) {
      if (pos)
        *pos = i + 1;
      return m_order[i];
    }
  }
  assert(0);
  return '\0';
}

////////////////////////////////////////////////////////////////////////////////
//
//  Helper functions used in MyGuessingStrategy
//

/**
 * Return true only when str matches pattern EXACTLY. e.g. given a pattern "AB-",
 * string "ABC" and "ABD" match it, WHILE "ABA" "ABB" AND "XYZ" DON'T. In the same
 * example, the patternChars argument must be {'A', 'B'}
 */
static bool match(const string & pattern, const string & word, const set<char> patternChars) {
  assert(pattern.size() == word.size());
  int size = pattern.size();
  bool ret = true;
  for (int i = 0; i < size; i++) {
    if (pattern[i] != HangmanGame::MYSTERY_LETTER) {
      if (pattern[i] != word[i]) {
        ret = false;
        break;
      }
    }
    else {
      if (patternChars.count(word[i])) {
        ret = false;
        break;
      }
    }
  }
  return ret;
}

/**
 * Fill the first '-' character in pattern with ch.
 * Return a new string of the filled version.
 */
static inline string fillBlank(const string & pattern, char ch) {
  string word = pattern;
  string::size_type idx = word.find(HangmanGame::MYSTERY_LETTER);
  assert(idx != string::npos);
  word[idx] = ch;
  return word;
}

/**
 * If a word has any characters in chars, return true, otherwise false.
 */
static inline bool hasAny(const string & word, const set<char> & chars) {
  for (unsigned int i = 0; i < word.length(); i++) {
    if (chars.count(word[i]) > 0)
      return true;
  }
  return false;
}

////////////////////////////////////////////////////////////////////////////////
//
//  Class MyGuessingStrategy
//

/**
 * Initialize with a dictionary of words.
 */
MyGuessingStrategy::MyGuessingStrategy(const set<string> & dict) {
  set<string>::const_iterator it = dict.begin();
  set<string>::const_iterator end = dict.end();
  vector<string> patterns;
  for (; it != end; ++it) {
    const string & word = toUpperCase(*it);
    unsigned int len = word.length();
    if (patterns.size() < len)
      patterns.resize(len);
    string & pattern = patterns[len - 1];
    if (pattern.empty())
      pattern.assign(len, HangmanGame::MYSTERY_LETTER);
    if (m_patternMapGroup.size() < len)
      m_patternMapGroup.resize(len);
    m_patternMapGroup[len - 1][pattern].update(word);
  }
}

/**
 * Make a new WordSet to the pattern.
 */
MyGuessingStrategy::WordSet & MyGuessingStrategy::newWordSet(const string & pattern) {
  int len = pattern.length();
  PatternMap & map = m_patternMapGroup[len - 1];

  //Find the smallest "parent" pattern collection
  PatternMap::iterator end = map.end();
  PatternMap::iterator found = end;
  set<char> patternChars; //e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
  for (int i = 0; i < len; i++) {
    char ch = pattern[i];
    if (ch != HangmanGame::MYSTERY_LETTER && patternChars.insert(ch).second) {
      string copy = pattern;
      copy[i] = HangmanGame::MYSTERY_LETTER;
      for (int j = i + 1; j < len; j++) {
        if (copy[j] == ch)
          copy[j] = HangmanGame::MYSTERY_LETTER;
      }

      PatternMap::iterator iter = map.find(copy);
      if (iter != end && (found == end || found->second.wordCount() > iter->second.wordCount())) {
        found = iter;
      }
    }
  }
  assert(found != end);

  //Draw the new pattern collection and info through filtering the parent
  WordSet & parentSet = map[found->first];
  WordSet & newSet = map[pattern];

  vector<string>::const_iterator iter = parentSet.words().begin();
  vector<string>::const_iterator tail = parentSet.words().end();
  for(; iter != tail; ++iter) {
    const string & word = *iter;
    if (match(pattern, word, patternChars)) {
      newSet.update(word, &patternChars);
    }
  }
  return newSet;
}

/**
 * When we have a last chance to make a guess and there're more than one blanks
 * in a pattern, we do the final blow! The basic idea is to select a word, which
 * dosn't contain any wrong guessed letters while having the most probable letter
 * given by WordSet::suggest.
 */
string MyGuessingStrategy::finalBlow(const string & pattern, WordSet & wordset, const set<char> & wrongLetters) {
  string guess;
  vector<string> candidates;
  unsigned int i = 0;
  char ch = wordset.suggest(wrongLetters, &i);
  vector<string>::const_iterator iter = wordset.words().begin();
  vector<string>::const_iterator tail = wordset.words().end();
  for(; iter != tail; ++iter) {
    const string & word = *iter;
    if (!hasAny(word, wrongLetters)) {
      candidates.push_back(word);
      if (word.find(ch) != string::npos) {
        guess = word;
        break;
      }
    }
  }

  while (guess.empty()) {
    unsigned int j;
    char ch = wordset.suggest(wrongLetters, &i);
    for (j = 0; j < candidates.size(); j++) {
      if (candidates[j].find(ch) != string::npos) {
        guess = candidates[j];
        break;
      }
    }
  }

  return guess;
}

/**
 * Suggest a letter or word.
 */
string MyGuessingStrategy::suggest(const string & pattern, WordSet & wordset, const HangmanGame & game) {
  //If the pattern collection has only one word, that's it!
  if (wordset.wordCount() == 1) {
    return wordset.words()[0];
  }

  //Make a guess, according to letter frequency of a pattern.
  string word;
  const set<char> & wrongLetters = game.getIncorrectlyGuessedLetters();
  const set<string> & wrongWords = game.getIncorrectlyGuessedWords();
  //Number of '-' characters in a pattern.
  int patternBlanks = count(pattern.begin(), pattern.end(), HangmanGame::MYSTERY_LETTER);

  if (patternBlanks > 1) {
    if (game.numWrongGuessesRemaining() == 0)
      word = finalBlow(pattern, wordset, wrongLetters);
    else
      word = wordset.suggest(wrongLetters);
  }
  else {
    unsigned int i = 0;
    set<char> excluded = wrongLetters;
    while(1) {
      char ch = wordset.suggest(excluded, &i);
      word = fillBlank(pattern, ch);
      if (!wrongWords.count(word))
        break;
      else
        excluded.insert(ch);
    }
  }

  assert(!word.empty());
  return word;
}

Guess & MyGuessingStrategy::nextGuess(const HangmanGame & game) {
  const string & pattern = game.getGuessedSoFar(); //This line clearly explains what a "pattern" is.
  WordSet & wordset = wordSet(pattern);
  string next = suggest(pattern, wordset, game);
  if (next.length() == 1) {
    m_guessLetter.setLetter(next[0]);
    return m_guessLetter;
  }
  else {
    m_guessWord.setWord(next);
    return m_guessWord;
  }
}

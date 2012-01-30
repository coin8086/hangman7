#ifndef __MYGUESSINGSTRATEGY_H__
#define __MYGUESSINGSTRATEGY_H__

#include <string>
#include <vector>
#include <map>
#include <set>
#include "GuessingStrategy.h"
#include "GuessLetter.h"
#include "GuessWord.h"

using namespace std;

class MyGuessingStrategy : public GuessingStrategy {
public:
  MyGuessingStrategy(const set<string> & dict);

  Guess & nextGuess(const HangmanGame & game);

private:
  /**
   * A WordSet is a set of words all having the same pattern.
   * e.g. Given a pattern "AB-", the words may be {"ABC", "ABD", "ABX"}
   * A WordSet also contains statistical info about the words in it, such as
   * letter occurrence times.
   */
  class WordSet {
  public:
    void update(const string & word, const set<char> * excluded = 0);

    unsigned int wordCount() const {
      return m_words.size();
    }

    const vector<string> & words() const {
      return m_words;
    }

    char suggest(const set<char> & excluded, unsigned int * pos = 0);

  private:
    class LetterStat {
    public:
      LetterStat() : m_frequency(0), m_wordCount(0) {}

      int m_frequency;
      int m_wordCount;
    };

    typedef pair<char, LetterStat> Pair;

    class LessThan {
    public:
      bool operator()(const Pair & left, const Pair & right) {
        const LetterStat & l = left.second;
        const LetterStat & r = right.second;

        if (l.m_frequency > r.m_frequency)
          return true;

        if (l.m_frequency == r.m_frequency)
          return l.m_wordCount < r.m_wordCount;

        return false;
      }
    };

    /**
     * A map of letters to their statistical info.
     */
    map<char, LetterStat> m_stat;

    /**
     * Letters in descendent order on frequency
     */
    vector<char> m_order;

    /**
     * Words in the set.
     */
    vector<string> m_words;

  private:
    void makeOrder();

  };

  /**
   * A map of patterns to WordSets. All patterns in the same map have the same length
   */
  typedef map<string, WordSet> PatternMap;

  /**
   * Given a pattern P, its WordSet can be retrieved by PatternMapGroup[P.length - 1][P]
   */
  typedef vector<PatternMap> PatternMapGroup;

  PatternMapGroup m_patternMapGroup;

  /**
   * These two members are used to store return value of nextGuess.
   */
  GuessLetter m_guessLetter;
  GuessWord m_guessWord;

private:
  WordSet & wordSet(const string & pattern) {
    WordSet & set = m_patternMapGroup[pattern.length() - 1][pattern];
    return set.wordCount() ? set : newWordSet(pattern);
  }

  WordSet & newWordSet(const string & pattern);

  string finalBlow(const string & pattern, WordSet & wordset, const set<char> & wrongLetters);

  string suggest(const string & pattern, WordSet & wordset, const HangmanGame & game);

};

#endif

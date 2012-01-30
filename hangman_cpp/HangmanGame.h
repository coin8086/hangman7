#ifndef __HANGMANGAME_H__
#define __HANGMANGAME_H__

#include <string>
#include <set>
#include <assert.h>
#include "Utility.h"

using namespace std;

class GuessingStrategy;

class HangmanGame {
public:
  /**
   * A enum for the current state of the game
   */
  enum Status {GAME_WON, GAME_LOST, KEEP_GUESSING};

  /**
   * A marker for the letters in the secret words that have not been guessed yet.
   */
  static const char MYSTERY_LETTER = '-';

  /**
   * @param secretWord The word that needs to be guessed
   * @param maxWrongGuesses The maximum number of incorrect word/letter guesses that are allowed
   */
  HangmanGame(const string & secretWord, int maxWrongGuesses) {
    m_secretWord = toUpperCase(secretWord);
    string tmp(secretWord.length(), MYSTERY_LETTER);
    m_guessedSoFar = tmp;
    m_maxWrongGuesses = maxWrongGuesses;
  }

  /**
   * Guess the specified letter and update the game state accordingly
   * @return The string representation of the current game state
   * (which will contain MYSTERY_LETTER in place of unknown letters)
   */
  const string & guessLetter(char ch);

  /**
   * Guess the specified word and update the game state accordingly
   * @return The string representation of the current game state
   * (which will contain MYSTERY_LETTER in place of unknown letters)
   */
  const string & guessWord(const string & word);

  /**
   * @return The score for the current game state
   */
  int currentScore() const {
    if (gameStatus() == GAME_LOST) {
      return 25;
    }
    else {
      return numWrongGuessesMade() + m_correctlyGuessedLetters.size();
    }
  }

  /**
   * @return The current game status
   */
  Status gameStatus() const {
    if (m_secretWord == m_guessedSoFar) {
      return GAME_WON;
    }
    else if (numWrongGuessesMade() > m_maxWrongGuesses) {
      return GAME_LOST;
    }
    else {
      return KEEP_GUESSING;
    }
  }

  /**
   * @return Number of wrong guesses made so far
   */
  int numWrongGuessesMade() const {
    return m_incorrectlyGuessedLetters.size() + m_incorrectlyGuessedWords.size();
  }

  /**
   * @return Number of wrong guesses still allowed
   */
  int numWrongGuessesRemaining() const {
    return getMaxWrongGuesses() - numWrongGuessesMade();
  }

  /**
   * @return Number of total wrong guesses allowed
   */
  int getMaxWrongGuesses() const {
    return m_maxWrongGuesses;
  }

  /**
   * @return The string representation of the current game state
   * (which will contain MYSTERY_LETTER in place of unknown letters)
   */
  const string & getGuessedSoFar() const {
    return m_guessedSoFar;
  }

  /**
   * @return Set of all correctly guessed letters so far
   */
  const set<char> & getCorrectlyGuessedLetters() const {
    return m_correctlyGuessedLetters;
  }

  /**
   * @return Set of all incorrectly guessed letters so far
   */
  const set<char> & getIncorrectlyGuessedLetters() const {
    return m_incorrectlyGuessedLetters;
  }

  /**
   * @return Set of all guessed letters so far
   */
  set<char> getAllGuessedLetters() const {
    set<char> guessed(m_correctlyGuessedLetters);
    guessed.insert(m_incorrectlyGuessedLetters.begin(), m_incorrectlyGuessedLetters.end());
    return guessed;
  }

  /**
   * @return Set of all incorrectly guessed words so far
   */
  const set<string> & getIncorrectlyGuessedWords() const {
    return m_incorrectlyGuessedWords;
  }

  /**
   * @return The length of the secret word
   */
  int getSecretWordLength() const {
    return m_secretWord.length();
  }

  const char * toString() const;

  int run(GuessingStrategy & strategy, bool debugOut = 0);

private:
  /**
   * The word that needs to be guessed (e.g. 'FACTUAL')
   */
  string m_secretWord;

  /**
   * The maximum number of wrong letter/word guesses that are allowed (e.g. 6, and if you exceed 6 then you lose)
   */
  int m_maxWrongGuesses;

  /**
   * The letters guessed so far (unknown letters will be marked by the MYSTERY_LETTER constant). For example, 'F-CTU-L'
   */
  string m_guessedSoFar;

  /**
   * Set of all correct letter guesses so far (e.g. 'C', 'F', 'L', 'T', 'U')
   */
  set<char> m_correctlyGuessedLetters;

  /**
   * Set of all incorrect letter guesses so far (e.g. 'R', 'S')
   */
  set<char> m_incorrectlyGuessedLetters;

  /**
   * Set of all incorrect word guesses so far (e.g. 'FACTORS')
   */
  set<string> m_incorrectlyGuessedWords;

  static const int STR_BUF_LEN = 128;

  /**
   * String representation
   */
  mutable char m_repr[STR_BUF_LEN];

  void assertCanKeepGuessing() {
    assert(gameStatus() == KEEP_GUESSING);
  }
};

#endif

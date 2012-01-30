#ifndef __GUESSWORD_H__
#define __GUESSWORD_H__

#include "Guess.h"
#include "HangmanGame.h"
#include <stdio.h>

#ifdef __GNUC__
#define _snprintf snprintf
#endif

/**
 * A Guess that represents guessing a word for the current Hangman game
 */
class GuessWord : public Guess {
public:
  GuessWord() {}

  GuessWord(const string & guess) {
    m_guess = guess;
  }

  void makeGuess(HangmanGame & game) {
    game.guessWord(m_guess);
  }

  void setWord(const string & guess) {
    m_guess = guess;
  }

  const char * toString() const {
    int written = _snprintf(m_repr, STR_BUF_LEN, "GuessWord[%s]", m_guess.c_str());
    if (written == STR_BUF_LEN)
      m_repr[STR_BUF_LEN - 1] = '\0';
    return m_repr;
  }

private:
  string m_guess;
  static const int STR_BUF_LEN = 64;
  mutable char m_repr[STR_BUF_LEN];
};

#endif

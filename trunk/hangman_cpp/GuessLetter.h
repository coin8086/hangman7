#ifndef __GUESSLEETER_H__
#define __GUESSLEETER_H__

#include "Guess.h"
#include "HangmanGame.h"
#include <stdio.h>

#ifdef __GNUC__
#define _snprintf snprintf
#endif

/**
 * A Guess that represents guessing a letter for the current Hangman game
 */
class GuessLetter : public Guess {
public:
  GuessLetter() : m_guess('\0') {}

  GuessLetter(char guess) {
    m_guess = guess;
  }

  void makeGuess(HangmanGame & game) {
    game.guessLetter(m_guess);
  }

  void setLetter(char guess) {
    m_guess = guess;
  }

  const char * toString() const {
    int written = _snprintf(m_repr, STR_BUF_LEN, "GuessLetter[%c]", m_guess);
    if (written == STR_BUF_LEN)
      m_repr[STR_BUF_LEN - 1] = '\0';
    return m_repr;
  }

private:
  char m_guess;
  static const int STR_BUF_LEN = 32;
  mutable char m_repr[STR_BUF_LEN];
};

#endif

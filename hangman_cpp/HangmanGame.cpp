#include "HangmanGame.h"
#include "GuessingStrategy.h"
#include "Guess.h"
#include <stdio.h>

#ifdef __GNUC__
#define _snprintf snprintf

const char HangmanGame::MYSTERY_LETTER;
#endif

const string & HangmanGame::guessLetter(char ch) {
  assertCanKeepGuessing();
  ch = toupper(ch);

  // update the guessedSoFar buffer with the new character
  bool goodGuess = false;
  for (unsigned int i = 0; i < m_secretWord.length(); i++) {
    if (m_secretWord[i] == ch) {
      m_guessedSoFar[i] = ch;
      goodGuess = true;
    }
  }

  // update the proper set of guessed letters
  if (goodGuess) {
    m_correctlyGuessedLetters.insert(ch);
  }
  else {
    m_incorrectlyGuessedLetters.insert(ch);
  }

  return m_guessedSoFar;
}

const string & HangmanGame::guessWord(const string & word) {
  assertCanKeepGuessing();
  string guess = toUpperCase(word);

  if (guess == m_secretWord) {
    // if the guess is correct, then set guessedSoFar to the secret word
    m_guessedSoFar = m_secretWord;
  }
  else {
    m_incorrectlyGuessedWords.insert(guess);
  }

  return m_guessedSoFar;
}

const char * HangmanGame::toString() const {
  static const char * status[] = {"GAME_WON", "GAME_LOST", "KEEP_GUESSING"};
  int written = _snprintf(m_repr, STR_BUF_LEN, "%s; score=%d; status=%s",
    getGuessedSoFar().c_str(), currentScore(), status[gameStatus()]);
  if (written == STR_BUF_LEN)
    m_repr[STR_BUF_LEN - 1] = '\0';
  return m_repr;
}

int HangmanGame::run(GuessingStrategy & strategy, bool debugOut) {
  while(gameStatus() == KEEP_GUESSING) {
    if (debugOut)
      fprintf(stderr, "%s\n", toString());

    Guess & guess = strategy.nextGuess(*this);

    if (debugOut)
      fprintf(stderr, "%s\n", guess.toString());

    guess.makeGuess(*this);
  }

  if (debugOut)
    fprintf(stderr, "%s\n", toString());

  return currentScore();
}

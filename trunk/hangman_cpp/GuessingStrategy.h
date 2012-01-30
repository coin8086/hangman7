#ifndef __GUESSINGSTRATEGY_H__
#define __GUESSINGSTRATEGY_H__

class HangmanGame;
class Guess;

/**
 * A strategy for generating guesses given the current state of a Hangman game.
 */
class GuessingStrategy {
public:
  virtual Guess & nextGuess(const HangmanGame & game) = 0;
};

#endif

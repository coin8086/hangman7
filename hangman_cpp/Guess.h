#ifndef __GUESS_H__
#define __GUESS_H__

class HangmanGame;

class Guess {
public:
  /**
   * Applies the current guess to the specified game.
   * @param game The game to make the guess on.
   */
  virtual void makeGuess(HangmanGame & game) = 0;

  virtual const char * toString() const = 0;
};

#endif

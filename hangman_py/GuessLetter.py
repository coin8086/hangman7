from Guess import Guess

# A Guess that represents guessing a letter for the current Hangman game

class GuessLetter(Guess):
  def __init__(self, guess):
    self.guess = guess

  def makeGuess(self, game):
    game.guessLetter(self.guess)

  def __str__(self):
    return "GuessLetter[%s]" % self.guess

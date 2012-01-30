from Guess import Guess

# A Guess that represents guessing a word for the current Hangman game

class GuessWord(Guess):
  def __init__(self, guess):
    self.guess = guess

  def makeGuess(self, game):
    game.guessWord(self.guess)

  def __str__(self):
    return "GuessWord[%s]" % self.guess

require 'Guess'

# A Guess that represents guessing a word for the current Hangman game

class GuessWord < Guess
  @guess

  def initialize(guess)
    @guess = guess
  end

  def makeGuess(game)
    game.guessWord(@guess)
  end

  def to_s
    "GuessWord[%s]" % @guess
  end
end

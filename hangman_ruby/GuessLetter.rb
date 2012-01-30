require 'Guess'

# A Guess that represents guessing a letter for the current Hangman game

class GuessLetter < Guess
  @guess

  def initialize(guess)
    @guess = guess
  end

  def makeGuess(game)
    game.guessLetter(@guess)
  end

  def to_s
    "GuessLetter[%s]" % @guess
  end
end

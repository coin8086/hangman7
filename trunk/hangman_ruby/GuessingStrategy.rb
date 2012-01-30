# A strategy for generating guesses given the current state of a Hangman game.

class GuessingStrategy
  def nextGuess(game)
    raise NotImplementedError
  end
end

import java.util.Scanner;
import java.io.File;
import java.io.IOException;
import java.util.Set;
import java.util.HashSet;

class Main {
  public static int run(HangmanGame game, GuessingStrategy strategy, boolean debug) {
    while(game.gameStatus() == HangmanGame.Status.KEEP_GUESSING) {
      if (debug) {
        System.err.println(game.toString());
      }
      Guess guess = strategy.nextGuess(game);
      if (debug) {
        System.err.println(guess.toString());
        System.err.println(strategy.toString());
      }
      guess.makeGuess(game);
    }
    if (debug) {
      System.err.println(game.toString());
    }
    return game.currentScore();
  }

  public static void main(String[] args) {
    String file = System.getenv("hangman_dict");
    if (file == null)
      file = "words.txt";

    int guesses = 5;
    String sguesses = System.getenv("hangman_guesses");
    if (sguesses != null) {
      try {
        guesses = Integer.parseInt(sguesses);
      }
      catch (NumberFormatException e) {
        guesses = 5;
      }
      if (guesses < 1)
        guesses = 5;
    }

    boolean debug = System.getenv("hangman_debug") != null ? true : false;

    // Read in dictionary file
    Set<String> dict = new HashSet<String>();
    try (Scanner s = new Scanner(new File(file))) {
      while (s.hasNext()) {
		    String word = s.next();
		    if (word.length() > 0)
		      dict.add(word.toUpperCase());
      }
    }
    catch (IOException e) {
      System.err.println(String.format("Cannot open dictionary file '%s' for reading!", file));
      System.exit(-1);
    }

    // Run game
    double totalScore = 0;
    int total = 0;

    try (Scanner s = new Scanner(System.in)) {
      System.err.println("Enter a word:");
      while (s.hasNext()) {
        String word = s.next();
        if (word.isEmpty())
          break;

        word = word.toUpperCase();
        if (!dict.contains(word)) {
          System.err.println(String.format("Word '%s' is not in dicitionary!", word));
          continue;
        }

        if (debug) {
          System.err.println(String.format("New Game [%s]", word));
        }

        HangmanGame game = new HangmanGame(word, guesses);
        MyGuessingStrategy strategy = new MyGuessingStrategy(game, dict);
        int score = run(game, strategy, debug);
        totalScore += score;
        total++;
        System.out.println(String.format("%s = %d", word, score));
        System.err.println("Enter a word:");
      }
    }

    if (total > 0)
      System.out.println(String.format("-----------------------------\nAVG: %g\nNUM: %d\nTOTAL: %g\n",
        totalScore / total, total, totalScore));
  }
}

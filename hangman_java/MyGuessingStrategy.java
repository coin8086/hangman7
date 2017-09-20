import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Collection;
import java.util.AbstractCollection;

class MyGuessingStrategy implements GuessingStrategy {
  /**
   * A WordSet is a set of words having the same pattern.
   * A pattern is a string returned by HangmanGame::getGuessedSoFar. It's like
   * "AB-", which matches words like "ABC", "ABD" and "ABX", but not "ABA" or "ABB".
   * A WordSet contains statistical info about letters that are NOT GUESSED yet.
   */
  private static class WordSet extends AbstractCollection<String> {

    private class WordIterator implements Iterator<String> {
      private Iterator<String> it = WordSet.this.words.iterator();

      @Override
      public boolean hasNext() {
        return it.hasNext();
      }

      @Override
      public String next() {
        return it.next();
      }

      @Override
      public void remove() {
        throw new UnsupportedOperationException();
      }
    }

    private static class LetterStat implements Comparable<LetterStat> {
      public final char ch;
      public int count = 0;  //How many times the letter appears in a WordSet
      public int wordCount = 0;  //How many words contains the letter in a WordSet

      LetterStat(char ch) {
        this.ch = ch;
      }

      @Override
      public int compareTo(LetterStat rhs) {
        if (this.count > rhs.count)
          return -1;

        if (this.count == rhs.count)
          return this.wordCount - rhs.wordCount;

        return 1;
      }
    }

    /**
     * A map of letters to their statistical info.
     */
    private Map<Character, LetterStat> stat = new HashMap<Character, LetterStat>();

    /**
     * Letters in descendent order on frequency
     */
    private List<LetterStat> order = null;

    /**
     * Words in the set.
     */
    private List<String> words = new ArrayList<String>();

    public final String pattern;

    public final Set<Character> guessedLetters;

    WordSet(String pattern, Set<Character> guessedLetters, Collection<String> words) {
      assert(pattern != null && guessedLetters != null);
      this.pattern = pattern;
      this.guessedLetters = guessedLetters;
      addAll(words);
    }

    /**
     * Determine if a word matches the pattern and guessed letters.
     */
    private boolean match(String word) {
      int size = pattern.length();
      assert(size == word.length());

      boolean ret = true;
      for (int i = 0; i < size; i++) {
        if (pattern.charAt(i) != HangmanGame.MYSTERY_LETTER) {
          if (pattern.charAt(i) != word.charAt(i)) {
            ret = false;
            break;
          }
        }
        else {
          if (guessedLetters.contains(word.charAt(i))) {
            ret = false;
            break;
          }
        }
      }
      return ret;
    }

    @Override
    public boolean add(String word) {
      if (!match(word)) {
        //throw new IllegalArgumentException();
        //It really should raise the exception when the word is not acceptable.
        //However, returning false can make addAll work conveniently on a
        //collection of words.
        return false;
      }

      Set<Character> parsed = new HashSet<Character>();
      for (int i = 0; i < word.length(); i++) {
        char ch = word.charAt(i);
        if (!guessedLetters.contains(ch)) {
          LetterStat stat = this.stat.get(ch);
          if (stat != null) {
            stat.count++;
            if (parsed.add(ch)) {
              stat.wordCount++;
            }
          }
          else {
            stat = new LetterStat(ch);
            stat.count++;
            stat.wordCount++;
            this.stat.put(ch, stat);
            parsed.add(ch);
          }
        }
      }
      this.words.add(word);
      return true;
    }

    @Override
    public int size() {
      return words.size();
    }

    @Override
    public Iterator<String> iterator() {
      return new WordIterator();
    }

    /**
     * Give a suggest of the most probable letter not in the excluded letter set.
     */
    public char suggest(Set<Character> excluded) {
      if (this.order == null) {
        makeOrder();
      }
      for (int i = 0; i < this.order.size(); i++) {
        char ch = this.order.get(i).ch;
        if (!excluded.contains(ch)) {
          return ch;
        }
      }
      assert(false);
      return '\0';
    }

    /**
     * Sort letters in a word set on their frquencies in descending order.
     */
    private void makeOrder() {
      order = new ArrayList<LetterStat>(this.stat.values());
      Collections.sort(order);
    }

    @Override
    public String toString() {
      return "WordSet[" + size() + "]";
    }
  };

  private WordSet wordset;

  public MyGuessingStrategy(HangmanGame game, Set<String> dict) {
    String pattern = game.getGuessedSoFar();
    int len = pattern.length();
    List<String> words = new ArrayList<String>();
    for (String word: dict) {
      if (word.length() == len) {
        words.add(word);
      }
    }
    this.wordset = new WordSet(pattern, game.getAllGuessedLetters(), words);
  }

  @Override
  public Guess nextGuess(HangmanGame game) {
    //Update wordset on a previous guess result, be it successful or not.
    this.wordset = new WordSet(game.getGuessedSoFar(), game.getAllGuessedLetters(), this.wordset);
    String next = suggest(game);
    if (next.length() == 1) {
      return new GuessLetter(next.charAt(0));
    }
    else {
      return new GuessWord(next);
    }
  }

  /**
   * When we have a last chance to make a guess and there're more than one blanks
   * in a pattern, we do the final blow! The basic idea is to select a word, which
   * dosn't contain those wrong guessed letters while has the most probable
   * letter given by a WordSet::suggest.
   */
  private String finalBlow(HangmanGame game) {
    String guess = null;
    List<String> candidates = new ArrayList<String>();
    char ch = this.wordset.suggest(game.getAllGuessedLetters());
    Set<Character> wrongLetters = game.getIncorrectlyGuessedLetters();

    for (String word : this.wordset) {
      if (!hasAny(word, wrongLetters)) {
        candidates.add(word);
        if (word.indexOf(ch) != -1) {
          guess = word;
          break;
        }
      }
    }

    if (guess == null) {
      Set<Character> excluded = new HashSet<Character>(wrongLetters);
      while (guess == null) {
        excluded.add(ch);
        ch = this.wordset.suggest(excluded);
        for (String word : candidates) {
          if (word.indexOf(ch) != -1) {
            guess = word;
            break;
          }
        }
      }
    }

    assert(guess != null);
    return guess;
  }

  /**
   * Suggest a letter or word.
   */
  private String suggest(HangmanGame game) {
    if (this.wordset.size() == 1) {
      return this.wordset.iterator().next();
    }

    String word = null;
    Set<Character> guessedLetters = game.getAllGuessedLetters();
    String pattern = game.getGuessedSoFar();
    int patternBlanks = numOfBlanks(pattern); //Number of '-' characters in a pattern.

    if (patternBlanks > 1) {
      if (game.numWrongGuessesRemaining() == 0) {
        word = finalBlow(game);
      }
      else {
        word = Character.toString(this.wordset.suggest(guessedLetters));
      }
    }
    else {
      //When there's only one blank letter, try to guess the word to save one
      //score on a successfull guess.
      Set<Character> excluded;
      Set<String> wrongWords = game.getIncorrectlyGuessedWords();
      if (!wrongWords.isEmpty()) {
        //Reduce the wordset by incorrectly guessed letters from the wrongWords
        //and guessedLetters.
        int idx = pattern.indexOf(HangmanGame.MYSTERY_LETTER);
        excluded = new HashSet<Character>(guessedLetters);
        for (String wd : wrongWords) {
          excluded.add(wd.charAt(idx));
        }
        this.wordset = new WordSet(pattern, excluded, this.wordset);
      }
      else {
        excluded = guessedLetters;
      }
      char ch = this.wordset.suggest(excluded);
      word = pattern.replace(HangmanGame.MYSTERY_LETTER, ch);
    }

    assert(word != null);
    return word;
  }

  /**
   * If a word has any characters in chars, return true, otherwise false.
   */
  private static boolean hasAny(String word, Set<Character> chars) {
    for (int i = 0; i < word.length(); i++) {
      if (chars.contains(word.charAt(i)))
        return true;
    }
    return false;
  }

  private static int numOfBlanks(String pattern) {
    int count = 0;
    for (int i = 0; i < pattern.length(); i++) {
      if (pattern.charAt(i) == HangmanGame.MYSTERY_LETTER)
        count++;
    }
    return count;
  }

  @Override
  public String toString() {
    return "MyGuessingStrategy[" + this.wordset.toString() + "]";
  }
}

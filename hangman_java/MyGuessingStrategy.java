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
   * A WordSet is a set of words all having the same pattern.
   * A pattern is a string returned by HangmanGame::getGuessedSoFar. It's like
   * "AB-", which matches words like "ABC", "ABD" and "ABX", but not "ABA" or "ABB".
   * A WordSet contains statistical info about letters of the words in it.
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

    private final String pattern;

    private final Set<Character> guessedLetters;

    WordSet(String pattern, Set<Character> guessedLetters, Collection<String> words) {
      assert(pattern != null && guessedLetters != null);
      this.pattern = pattern;
      this.guessedLetters = guessedLetters;
      addAll(words);
    }

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

  };

  private final Set<String> dict;

  /**
   * A map of patterns to WordSets.
   */
  private Map<String, WordSet> patterns = new HashMap<String, WordSet>();

  public MyGuessingStrategy(Set<String> dict) {
    this.dict = dict;
  }

  @Override
  public Guess nextGuess(HangmanGame game) {
    String pattern = game.getGuessedSoFar();
    WordSet wordset = this.patterns.get(pattern);
    if (wordset == null) {
      //NOTE: A wordset is related to a specific game status, i.e. the pattern
      //AND the guessed letters. And a strategy instance contains such wordsets.
      //So there MUST be a new strategy instance for a new game.
      wordset = newWordSet(pattern, game.getAllGuessedLetters());
    }
    String next = suggest(pattern, wordset, game);
    if (next.length() == 1) {
      return new GuessLetter(next.charAt(0));
    }
    else {
      return new GuessWord(next);
    }
  }

  /**
   * Make a new WordSet for the pattern AND the guessed letters.
   */
  private WordSet newWordSet(String pattern, Set<Character> guessed) {
    int len = pattern.length();
    Collection<String> coll;
    if (patterns.isEmpty()) {
      List<String> words = new ArrayList<String>();
      for (String word: this.dict) {
        if (word.length() == len) {
          words.add(word);
        }
      }
      coll = words;
    }
    else {
      //Find the smallest "parent" pattern collection
      WordSet parentWordSet = null;
      Set<Character> patternChars = new HashSet<Character>(); //e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
      for (int i = 0; i < len; i++) {
        char ch = pattern.charAt(i);
        if (ch != HangmanGame.MYSTERY_LETTER && patternChars.add(ch)) {
          char[] copy = pattern.toCharArray();
          copy[i] = HangmanGame.MYSTERY_LETTER;
          for (int j = i + 1; j < len; j++) {
            if (copy[j] == ch)
              copy[j] = HangmanGame.MYSTERY_LETTER;
          }

          String p = new String(copy);
          WordSet set = this.patterns.get(p);
          if (set != null && (parentWordSet == null || parentWordSet.size() > set.size())) {
            parentWordSet = set;
          }
        }
      }
      assert(parentWordSet != null);
      coll = parentWordSet;
    }
    WordSet newSet = new WordSet(pattern, guessed, coll);
    this.patterns.put(pattern, newSet);
    return newSet;
  }

  /**
   * When we have a last chance to make a guess and there're more than one blanks
   * in a pattern, we do the final blow! The basic idea is to select a word, which
   * dosn't contain those wrong guessed letters while has the most probable
   * letter given by a WordSet::suggest.
   */
  private String finalBlow(String pattern, WordSet wordset, Set<Character> wrongLetters) {
    String guess = null;
    List<String> candidates = new ArrayList<String>();
    char ch = wordset.suggest(wrongLetters);

    for (String word : wordset) {
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
        ch = wordset.suggest(excluded);
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
  private String suggest(String pattern, WordSet wordset, HangmanGame game) {
    //If the pattern collection has only one word, that's it!
    if (wordset.size() == 1) {
      return wordset.iterator().next();
    }

    //Make a guess, according to letter frequency of a pattern.
    String word = null;
    Set<Character> wrongLetters = game.getIncorrectlyGuessedLetters();
    Set<String> wrongWords = game.getIncorrectlyGuessedWords();
    int patternBlanks = numOfBlanks(pattern); //Number of '-' characters in a pattern.

    if (patternBlanks > 1) {
      if (game.numWrongGuessesRemaining() == 0)
        word = finalBlow(pattern, wordset, wrongLetters);
      else {
        word = Character.toString(wordset.suggest(wrongLetters));
      }
    }
    else {
      Set<Character> excluded = new HashSet<Character>(wrongLetters);
      while(true) {
        char ch = wordset.suggest(excluded);
        word = pattern.replace(HangmanGame.MYSTERY_LETTER, ch);
        if (!wrongWords.contains(word))
          break;
        else
          excluded.add(ch);
      }
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

}

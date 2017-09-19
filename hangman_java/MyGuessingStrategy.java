import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;
import java.util.Iterator;

class MyGuessingStrategy implements GuessingStrategy {
  /**
   * A WordSet is a set of words all having the same pattern.
   * e.g. Given a pattern "AB-", the words may be {"ABC", "ABD", "ABX"}
   * A WordSet contains statistical info about letters of the words in it.
   */
  private static class WordSet {

    private static class LetterStat implements Comparable<LetterStat> {
      public char ch = 0;
      public int count = 0;  //How many times the letter appears in a WordSet
      public int wordCount = 0;  //How many words contains the letter in a WordSet

      LetterStat(char ch) {
        this.ch = ch;
      }

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

    public int size() {
      return words.size();
    }

    public List<String> words() {
      return Collections.unmodifiableList(words);
    }

    /**
     * Insert a new word to the word set, and update the letter statistical info.
     * Letters in the excluded set are not counted for the statistical info.
     */
    public void update(String word, Set<Character> excluded) {
      Set<Character> parsed = new HashSet<Character>();
      int i;
      for (i = 0; i < word.length(); i++) {
        char ch = word.charAt(i);
        if (excluded == null || !excluded.contains(ch)) {
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
    }

    /**
     * Give a suggest of the most probable letter not in the excluded letter set.
     */
    public char suggest(Set<Character> excluded) {
      if (this.order == null)
        makeOrder();
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

  /**
   * An array of maps of patterns to their WordSets.
   * Given a pattern P, its WordSet can be retrieved by patternMapGroup[P.length - 1][P]
   */
  private List<Map<String, WordSet > > patternMapGroup = new ArrayList<Map<String, WordSet > >();

  public MyGuessingStrategy(Set<String> dict) {
    List<String> patterns = new ArrayList<String>(20);
    Iterator<String> it = dict.iterator();
    while (it.hasNext()) {
      String s = it.next().toUpperCase();
      int len = s.length();
      if (patterns.size() < len) {
        for (int i = patterns.size(); i < len; i++)
          patterns.add(null);
      }
      String p = patterns.get(len - 1);
      if (p == null) {
        char[] pattern = new char[len];
        for (int i = 0; i < len; i++) {
          pattern[i] = HangmanGame.MYSTERY_LETTER;
        }
        p = new String(pattern);
        patterns.set(len - 1, p);
      }
      insert(p, s);
    }
  }

  public Guess nextGuess(HangmanGame game) {
    String pattern = game.getGuessedSoFar(); //This line clearly explains what a "pattern" is.
    WordSet wordset = this.patternMapGroup.get(pattern.length() - 1).get(pattern);
    if (wordset == null) { //If no statistical info collected for the pattern, collect it now.
      wordset = newWordSet(pattern);
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
   * Insert a word and its pattern to patternMapGroup
   */
  private void insert(String pattern, String word) {
    assert(pattern.length() == word.length());

    int len = pattern.length();
    if (this.patternMapGroup.size() < len) { //Increase the list size if necessary
      for (int i = this.patternMapGroup.size(); i < len; i++) {
        this.patternMapGroup.add(new HashMap<String, WordSet>());
      }
    }

    Map<String, WordSet > map = this.patternMapGroup.get(len - 1);
    WordSet set = map.get(pattern);
    if (set == null) {
      set = new WordSet();
      map.put(pattern, set);
    }
    set.update(word, null);
  }

  /**
   * Make a new WordSet to the pattern.
   */
  private WordSet newWordSet(String pattern) {
    int len = pattern.length();
    Map<String, WordSet> map = this.patternMapGroup.get(len - 1);

    //Find the smallest "parent" pattern collection
    int i;
    WordSet parentWordSet = null;
    String parentPattern = null;
    Set<Character> patternChars = new HashSet<Character>(); //e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
    for (i = 0; i < len; i++) {
      char ch = pattern.charAt(i);
      if (ch != HangmanGame.MYSTERY_LETTER && patternChars.add(ch)) {
        char[] copy = pattern.toCharArray();
        copy[i] = HangmanGame.MYSTERY_LETTER;
        for (int j = i + 1; j < len; j++) {
          if (copy[j] == ch)
            copy[j] = HangmanGame.MYSTERY_LETTER;
        }

        String p = new String(copy);
        WordSet set = map.get(p);
        if (set != null && (parentWordSet == null || parentWordSet.size() > set.size())) {
          parentWordSet = set;
          parentPattern = p;
        }
      }
    }
    assert(parentWordSet != null);

    //Draw the new pattern collection and info through filtering the parent
    WordSet newSet = new WordSet();
    map.put(pattern, newSet);
    for (String word : parentWordSet.words()) {
      if (match(pattern, word, patternChars)) {
        newSet.update(word, patternChars);
      }
    }

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

    for (String word : wordset.words()) {
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
      return wordset.words().get(0);
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
   * Return true only when str matches pattern EXACTLY. A pattern is a string returned by HangmanGame::getGuessedSoFar.
   * e.g. given pattern "AB-", string "ABC" and "ABD" match it, while "ABA" "ABB" and "XYZ" DON'T. In the same
   * example, the patternChars argument must be {'A', 'B'}
   */
  private static boolean match(String pattern, String str, Set<Character> patternChars) {
    assert(pattern.length() == str.length());

    int size = pattern.length();
    boolean ret = true;
    for (int i = 0; i < size; i++) {
      if (pattern.charAt(i) != HangmanGame.MYSTERY_LETTER) {
        if (pattern.charAt(i) != str.charAt(i)) {
          ret = false;
          break;
        }
      }
      else {
        if (patternChars.contains(str.charAt(i))) {
          ret = false;
          break;
        }
      }
    }
    return ret;
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

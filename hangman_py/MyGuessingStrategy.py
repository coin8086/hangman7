from HangmanGame import HangmanGame
from GuessingStrategy import GuessingStrategy
from GuessLetter import GuessLetter
from GuessWord import GuessWord
from collections import defaultdict

# If a word has any characters in chars, return true, otherwise false.
def hasAny(word, chars):
  for ch in word:
    if ch in chars:
      return True
  return False

class MyGuessingStrategy(GuessingStrategy):

  # A WordSet is a set of words all having the same pattern.
  # e.g. Given a pattern "AB-", the words may be {"ABC", "ABD", "ABX"}
  # A WordSet also contains statistical info about the words in it, such as
  # letter occurrence times.
  class WordSet:

    class LetterStat:
      def __init__(self):
        self.frequency = 0
        self.wordCount = 0

    def __init__(self):
      # Words in the set.
      self.__words = []

      # A map of letters to LetterStats.
      self.__stat = defaultdict(MyGuessingStrategy.WordSet.LetterStat)

      # Letters in descendent order on frequency
      self.__order = None

    # Insert a new word to the word set, and update the letter statistical info.
    # Letters in the excluded set are not counted for the statistical info.
    def update(self, word, excluded = None):
      parsed = set()
      for ch in word:
        if (not excluded) or (ch not in excluded):
          stat = self.__stat[ch]
          stat.frequency += 1
          if ch not in parsed:
            parsed.add(ch)
            stat.wordCount += 1

      self.__words.append(word)

    def wordCount(self):
      return len(self.__words)

    def words(self):
      return list(self.__words)

    # Give a suggest of the most probable letter not in the excluded letter set.
    # When given a pos, start searching self.__order from it.
    def suggest(self, excluded, pos = 0):
      if not self.__order:
        self.makeOrder()

      i = pos
      while i < len(self.__order):
        if self.__order[i] not in excluded:
          return self.__order[i], i + 1
        i += 1

      assert False

    # private

    # Sort letters in a word set on their frquencies in descending order.
    def makeOrder(self):
      def cmp(l, r):
        l, r = l[1], r[1]
        if l.frequency > r.frequency:
          return -1
        elif l.frequency == r.frequency:
          return l.wordCount - r.wordCount
        else:
          return 1

      def key(e):
        return e[0]

      order = sorted(self.__stat.items(), cmp)
      self.__order = map(key, order)


  # Initialize with a dictionary of words.
  def __init__(self, dict):
    # An array of maps of patterns to their WordSets.
    # Given a pattern P, its WordSet can be retrieved by patternMapGroup[P.length - 1][P]
    self.__patternMapGroup = {}
    patterns = {}

    for word in dict:
      word = word.upper()
      length = len(word)
      pattern = patterns.get(length)
      if not pattern:
        pattern = patterns[length] = HangmanGame.MYSTERY_LETTER * length

      words = self.__patternMapGroup.get(length - 1)
      if not words:
        words = self.__patternMapGroup[length - 1] = defaultdict(MyGuessingStrategy.WordSet)

      words[pattern].update(word)

  def nextGuess(self, game):
    pattern = game.getGuessedSoFar() # This line clearly explains what a "pattern" is.
    wordset = self.wordSet(pattern)
    guess = self.suggest(pattern, wordset, game)
    return GuessLetter(guess) if len(guess) == 1 else GuessWord(guess)

  # private

  def wordSet(self, pattern):
    set = self.__patternMapGroup[len(pattern) - 1][pattern]
    return set if set.wordCount() > 0 else self.newWordSet(pattern)

  # Make a new WordSet to the pattern.
  def newWordSet(self, pattern):
    length = len(pattern)
    map = self.__patternMapGroup[length - 1]

    # Find the smallest "parent" pattern collection
    i = 0
    parentWordSet = None
    parentPattern = None
    patternChars = set() # e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
    while i < length:
      ch = pattern[i]
      if ch != HangmanGame.MYSTERY_LETTER and ch not in patternChars:
        patternChars.add(ch)
        copy = list(pattern)
        copy[i] = HangmanGame.MYSTERY_LETTER
        j = i + 1
        while j < length:
          if copy[j] == ch:
            copy[j] = HangmanGame.MYSTERY_LETTER
          j += 1

        copy = ''.join(copy)
        wordset = map.get(copy) # [] may return a default value
        if wordset and (not parentWordSet or parentWordSet.wordCount() > wordset.wordCount()):
          parentWordSet = wordset
          parentPattern = copy

      i += 1

    assert parentPattern

    # Draw the new pattern collection and info through filtering the parent
    newSet = map[pattern]
    for word in parentWordSet.words():
      if MyGuessingStrategy.match(pattern, word, patternChars):
        newSet.update(word, patternChars)

    return newSet

  # Suggest a letter or word.
  def suggest(self, pattern, wordset, game):
    # If the pattern collection has only one word, that's it!
    if wordset.wordCount() == 1:
      return wordset.words()[0]

    # Make a guess, according to letter frequency of a pattern.
    word = None
    wrongLetters = game.getIncorrectlyGuessedLetters()
    wrongWords = game.getIncorrectlyGuessedWords()
    patternBlanks = pattern.count(HangmanGame.MYSTERY_LETTER) # Number of '-' characters in a pattern.

    if patternBlanks > 1:
      if game.numWrongGuessesRemaining() == 0:
        word = self.finalBlow(pattern, wordset, wrongLetters)
      else:
        word, _ = wordset.suggest(wrongLetters)
    else:
      i = 0
      while True:
        ch, i = wordset.suggest(wrongLetters, i)
        word = pattern.replace(HangmanGame.MYSTERY_LETTER, ch, 1)
        if word not in wrongWords:
          break
        else:
          wrongLetters.add(ch)

    assert word
    return word

  # When we have a last chance to make a guess and there're more than one blanks
  # in a pattern, we do the final blow! The basic idea is to select a word, which
  # dosn't contain those wrong guessed letters while having the most probable
  # letter given by a WordSet#suggets.
  def finalBlow(self, pattern, wordset, wrongLetters):
    candidates = []
    i = 0
    ch, i = wordset.suggest(wrongLetters, i)

    for word in wordset.words():
      if not hasAny(word, wrongLetters):
        candidates.append(word)
        if ch in word:
          return word

    guess = None
    while not guess:
      ch, i = wordset.suggest(wrongLetters, i)
      for word in candidates:
        if ch in word:
          guess = word
          break

    return guess

  # Return true only when str matches pattern EXACTLY(a pattern is a string returned
  # by HangmanGame#getGuessedSoFar). e.g. given pattern "AB-", string "ABC" and
  # "ABD" match it, while "ABA" "ABB" and "XYZ" DON'T. In the same example,
  # the patternChars argument must be {'A', 'B'}
  @staticmethod
  def match(pattern, str, patternChars):
    size = len(pattern)
    assert size == len(str)

    ret = True
    i = 0
    while i < size:
      if pattern[i] != HangmanGame.MYSTERY_LETTER:
        if pattern[i] != str[i]:
          ret = False
          break
      else:
        if str[i] in patternChars:
          ret = False
          break
      i += 1

    return ret


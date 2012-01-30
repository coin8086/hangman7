module(..., package.seeall)

HangmanGame = require "HangmanGame"
GuessingStrategy = require "GuessingStrategy"
GuessLetter = require "GuessLetter"
GuessWord = require "GuessWord"
Set = require "Set"
cl = require "cl"
require "ext"

-- Return true only when str matches pattern EXACTLY(a pattern is a string returned
-- by HangmanGame--getGuessedSoFar). e.g. given pattern "AB-", string "ABC" and
-- "ABD" match it, while "ABA" "ABB" and "XYZ" DON'T. In the same example,
-- the patternChars argument must be {'A', 'B'}
local function match(pattern, str, patternChars)
  local size = #pattern
  assert(size == #str)

  local ret = true
  for i = 1, size do
    if pattern:charAt(i) ~= HangmanGame.MYSTERY_LETTER then
      if pattern:charAt(i) ~= str:charAt(i) then
        ret = false
        break
      end
    else
      if patternChars:contains(str:charAt(i)) then
        ret = false
        break
      end
    end
  end

  return ret
end

MyGuessingStrategy = cl.makeClass({

  -- A WordSet is a set of words all having the same pattern.
  -- e.g. Given a pattern "AB-", the words may be {"ABC", "ABD", "ABX"}
  -- A WordSet also contains statistical info about the words in it, such as
  -- letter occurrence times.
  WordSet = cl.makeClass {

    LetterStat = cl.makeClass {
      init = function(self)
        self.frequency = 0
        self.wordCount = 0
      end
    },

    init = function(self)
      -- Words in the set.
      self._words = {}

      -- A map of letters to LetterStats.
      self._stat = {}

      -- Letters in descendent order on frequency
      self._order = false
    end,

    -- Insert a new word to the word set, and update the letter statistical info.
    -- Letters in the excluded set are not counted for the statistical info.
    update = function(self, word, excluded)
      local parsed = Set()
      for ch in word:chars() do
        if not excluded or not excluded:contains(ch) then
          stat = self._stat[ch]
          if stat then
            stat.frequency = stat.frequency + 1
            if parsed:add(ch) then
              stat.wordCount = stat.wordCount + 1
            end
          else
            stat = MyGuessingStrategy.WordSet.LetterStat()
            stat.frequency = 1
            stat.wordCount = 1
            self._stat[ch] = stat
            parsed:add(ch)
          end
        end
      end
      table.insert(self._words, word)
      return self
    end,

    wordCount = function(self)
      return #self._words
    end,

    words = function(self)
      return self._words
    end,

    -- Give a suggest of the most probable letter not in the excluded letter set.
    -- When given a pos, start searching self._order from it.
    suggest = function(self, excluded, pos)
      if not self._order then
        self:makeOrder()
      end
      for i = pos or 1, #self._order do
        if not excluded:contains(self._order[i]) then
          return self._order[i], i + 1
        end
      end
      assert(false)
    end,

    -- private

    -- Sort letters in a word set on their frquencies in descending order.
    makeOrder = function(self)
      local tmp = {}
      for k, v in pairs(self._stat) do
        table.insert(tmp, {k, v})
      end

      table.sort(tmp, function(l, r)
        l, r = l[2], r[2]
        if l.frequency > r.frequency then
          return true
        elseif l.frequency == r.frequency then
          return l.wordCount < r.wordCount
        else
          return false
        end
      end)

      self._order = {}
      for i, v in ipairs(tmp) do
        table.insert(self._order, v[1])
      end
    end,

  },

  -- Initialize with a dictionary of words.
  init = function(self, dict)
    -- An array of maps of patterns to their WordSets.
    -- Given a pattern P, its WordSet can be retrieved by patternMapGroup[P.length][P]
    self._patternMapGroup = {}

    local patterns = {}

    for word in dict:elements() do
      word = word:upper()
      local len = #word
      local pattern = patterns[len]
      if not pattern then
        pattern = HangmanGame.MYSTERY_LETTER:rep(len)
        patterns[len] = pattern
      end

      local words = self._patternMapGroup[len]
      if not words then
        words = {}
        self._patternMapGroup[len] = words
      end

      local wordset = words[pattern]
      if not wordset then
        wordset = MyGuessingStrategy.WordSet()
        words[pattern] = wordset
      end
      wordset:update(word)
    end

  end,

  nextGuess = function(self, game)
    local pattern = game:getGuessedSoFar() -- This line clearly explains what a "pattern" is.
    local wordset = self:wordSet(pattern)
    local guess = self:suggest(pattern, wordset, game)
    if #guess == 1 then
      return GuessLetter(guess)
    else
      return GuessWord(guess)
    end
  end,

  -- private

  wordSet = function(self, pattern)
    local set = self._patternMapGroup[#pattern][pattern]
    if set then
      return set
    else
      return self:newWordSet(pattern)
    end
  end,

  -- Make a new WordSet to the pattern.
  newWordSet = function(self, pattern)
    local len = #pattern
    local map = self._patternMapGroup[len]

    -- Find the smallest "parent" pattern collection
    local parentWordSet = nil
    local parentPattern = nil
    local patternChars = Set() -- e.g. given a pattern "AB-A--", patternChars is {'A', 'B'}
    for i = 1, len do
      local ch = pattern:charAt(i)
      if ch ~= HangmanGame.MYSTERY_LETTER and patternChars:add(ch) then
        local copy = {}
        for c in pattern:chars() do
          table.insert(copy, c)
        end
        copy[i] = HangmanGame.MYSTERY_LETTER
        for j = i + 1, len do
          if copy[j] == ch then
            copy[j] = HangmanGame.MYSTERY_LETTER
          end
        end

        copy = table.concat(copy)
        local wordset = map[copy]
        if wordset and (not parentWordSet or parentWordSet:wordCount() > wordset:wordCount()) then
          parentWordSet = wordset
          parentPattern = copy
        end
      end
    end

    assert(parentPattern)

    -- Draw the new pattern collection and info through filtering the parent
    local newSet = MyGuessingStrategy.WordSet()
    map[pattern] = newSet

    for i, word in ipairs(parentWordSet:words()) do
      if match(pattern, word, patternChars) then
        newSet:update(word, patternChars)
      end
    end

    return newSet
  end,

  -- Suggest a letter or word.
  suggest = function(self, pattern, wordset, game)
    -- If the pattern collection has only one word, that's it!
    if wordset:wordCount() == 1 then
      return wordset:words()[1]
    end

    -- Make a guess, according to letter frequency of a pattern.
    local word = nil
    local wrongLetters = game:getIncorrectlyGuessedLetters()
    local wrongWords = game:getIncorrectlyGuessedWords()
    local patternBlanks = pattern:count(HangmanGame.MYSTERY_LETTER) -- Number of '-' characters in a pattern.

    if patternBlanks > 1 then
      if game:numWrongGuessesRemaining() == 0 then
        word = self:finalBlow(pattern, wordset, wrongLetters)
      else
        word = wordset:suggest(wrongLetters)
      end
    else
      local i = 1
      while true do
        local ch
        ch, i = wordset:suggest(wrongLetters, i)
        word = pattern:gsub(HangmanGame.MYSTERY_LETTER, ch)
        if not wrongWords:contains(word) then
          break
        else
          wrongLetters:add(ch)
        end
      end
    end

    assert(word)
    return word
  end,

  -- When we have a last chance to make a guess and there're more than one blanks
  -- in a pattern, we do the final blow! The basic idea is to select a word, which
  -- dosn't contain those wrong guessed letters while having the most probable
  -- letter given by a WordSet--suggets.
  finalBlow = function(self, pattern, wordset, wrongLetters)
    local candidates = {}
    local i = 1
    local ch
    ch, i = wordset:suggest(wrongLetters, i)

    for _, word in ipairs(wordset:words()) do
      if not word:hasAny(wrongLetters) then
        table.insert(candidates, word)
        if word:find(ch) then
          return word
        end
      end
    end

    local guess = nil
    while not guess do
      ch, i = wordset:suggest(wrongLetters, i)
      for _, word in ipairs(candidates) do
        if word:find(ch) then
          guess = word
          break
        end
      end
    end

    return guess
  end

}, GuessingStrategy)

return MyGuessingStrategy

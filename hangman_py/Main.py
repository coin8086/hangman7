from HangmanGame import HangmanGame
from MyGuessingStrategy import MyGuessingStrategy
import os
import sys

MAX_WRONG_GUESSES = os.environ.get('hangman_guesses', 5)
DICT_FILE = os.environ.get('hangman_dict', 'words.txt')
DEBUG = os.environ.get('hangman_debug')

dict = set()
try:
  for line in open(DICT_FILE, 'rb'):
    word = line.strip()
    if len(word) > 0:
      dict.add(word.upper())

except IOError:
  print >> sys.stderr, "Cannot open dictionary file '%s' for reading!" % DICT_FILE
  sys.exit(1)

strategy = MyGuessingStrategy(dict)
totalScore = 0
total = 0
isatty = sys.stdin.isatty()
while True:
  try:
    if isatty:
      print >> sys.stderr, "Enter a word:"

    word = sys.stdin.readline().strip().upper()
    if len(word) == 0:
      raise EOFError
    elif word not in dict:
      print >> sys.stderr, "Word '%s' is not in dicitionary!" % word
      continue

    if DEBUG:
      print >> sys.stderr, "New Game [%s]" % word

    game = HangmanGame(word, MAX_WRONG_GUESSES)
    score = game.run(strategy, DEBUG)
    totalScore += score
    total += 1
    print "%s = %d" % (word, score)

  except EOFError:
    break

if total > 0:
  print "-----------------------------\nAVG: %g\nNUM: %d\nTOTAL: %d" % (1.0 * totalScore / total, total, totalScore)

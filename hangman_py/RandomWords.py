import os
import sys
import random

if len(sys.argv) < 2:
  print >> sys.stderr, "A number of random words is expected but missing."
  sys.exit(1)

DICT_FILE = os.environ.get('hangman_dict', 'words.txt')

dict = []
try:
  for line in open(DICT_FILE, 'rb'):
    word = line.strip()
    if len(word) > 0:
      dict.append(word.upper())

except IOError:
  print >> sys.stderr, "Cannot open dictionary file '%s' for reading!" % DICT_FILE
  sys.exit(1)

try:
  count = int(sys.argv[1])
except TypeError:
  count = 0

if count < 1 or count > len(dict):
  print >> sys.stderr, "%s is not a number, or its value is out of [1, %d]" % (sys.argv[1], len(dict))
  sys.exit(1)

out = set()
size = len(dict)
random.seed()

def rand():
  return int(random.random() * size)

i = count
while i >= 1:
  idx = (rand() * 10 + rand() + int(rand() / (rand() + 1))) % size
  if idx not in out:
    out.add(idx)
    print dict[idx].upper()
    i -= 1

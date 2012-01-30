local HangmanGame = require "HangmanGame"
local MyGuessingStrategy = require "MyGuessingStrategy"
local Set = require "Set"
require "ext"

local MAX_WRONG_GUESSES = os.getenv("hangman_guesses") or 5
local DICT_FILE = os.getenv("hangman_dict") or "words.txt"
local DEBUG = os.getenv("hangman_debug")

local dict = Set()
local f = io.open(DICT_FILE, "rb")
if not f then
  io.stderr:write(string.format("Cannot open dictionary file '%s' for reading!\n", DICT_FILE))
  os.exit(false, true)
end

for line in f:lines() do
  if #line > 0 then
    dict:add(line:upper())
  end
end

local strategy = MyGuessingStrategy(dict)
local totalScore = 0
local total = 0
while true do
  io.stderr:write("Enter a word:\n")
  local word = io.stdin:read()
  if not word then
    break
  end
  word = word:strip():upper()
  if #word == 0 then
    break
  end
  if not dict:contains(word) then
    io.stderr:write(string.format("Word '%s' is not in dicitionary!\n", word))
  else
    if DEBUG then
      io.stderr:write(string.format("New Game [%s]\n", word))
    end
    local game = HangmanGame(word, MAX_WRONG_GUESSES)
    local score = game:run(strategy, DEBUG)
    totalScore = totalScore + score
    total = total + 1
    io.stdout:write(string.format("%s = %d\n", word, score))
  end
end

if total > 0 then
  io.stdout:write(string.format("-----------------------------\nAVG: %g\nNUM: %d\nTOTAL: %d\n",
    1.0 * totalScore / total, total, totalScore))
end

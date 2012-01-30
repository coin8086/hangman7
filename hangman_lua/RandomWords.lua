local Set = require 'Set'

if not arg or #arg < 1 then
  io.stderr:write("A number of random words is expected but missing.\n")
  os.exit(false, true)
end

local DICT_FILE = os.getenv("hangman_dict") or "words.txt"

local dict = {}
local f = io.open(DICT_FILE, "rb")
if not f then
  io.stderr:write(string.format("Cannot open dictionary file '%s' for reading!\n", DICT_FILE))
  os.exit(false, true)
end

for line in f:lines() do
  if #line > 0 then
    table.insert(dict, line:upper())
  end
end

local count = tonumber(arg[1])
if count < 1 or count > #dict then
  io.stderr:write(string.format("%s is not a number, or its value is out of [1, %d]\n", arg[1], #dict))
  os.exit(false, true)
end

local out = Set()
local size = #dict
math.randomseed(os.time())
local i = count
while i >= 1 do
  local idx = (math.random(size) * 10 + math.random(size) + math.floor(math.random(size) / (math.random(size) + 1))) % size + 1
  if out:add(idx) then
    io.stdout:write(dict[idx]:upper(), "\n")
    i = i - 1
  end
end

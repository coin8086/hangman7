Set = require "Set"

s = Set()
assert(s:size() == 0)

for i = 1, 10 do
  s:add(i)
  assert(s:size() == i)
end

assert((not s:add(10)) and s:size() == 10)
assert(#s == 10)

s2 = Set()
for i = 9, 12 do
  s2:add(i)
end

s:merge(s2)

assert(s:size() == 12)

function collect(t)
  return function(e)
    table.insert(t, e)
  end
end

t1 = {}
s:each(collect(t1))

t2 = {}

for e in s:elements() do
  table.insert(t2, e)
end

assert(#t1 == #t2)
for i = 1, #t2 do
  assert(t1[i] == t2[i])
end

s3 = Set(s)
assert(s3:size() == s:size())

print "OK!"
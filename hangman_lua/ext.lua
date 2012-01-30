module(..., package.seeall)

-- If a string has any characters in set chars, return true, otherwise false.
function string.hasAny(str, chars)
  for ch in str:chars() do
    if chars:contains(ch) then
      return true
    end
  end
  return false
end

--String enumerator on chars
function string.chars(str)
  return coroutine.wrap(function()
    for i = 1, #str do
      coroutine.yield(str:sub(i, i))
    end
  end)
end

function string.charAt(str, i)
  return str:sub(i, i)
end

function string.count(str, pattern)
  local c = 0
  for w in str:gmatch(pattern) do
    c = c + 1
  end
  return c
end

function string.strip(str)
  return str:match("^%s*(.-)%s*$")
end

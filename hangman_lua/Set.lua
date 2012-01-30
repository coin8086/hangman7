module(..., package.seeall)

local cl = require "cl"

Set = cl.makeClass {
  init = function(self, s)
    self._data = {}
    self._size = 0
    if s then
      assert(cl.instanceOf(s, Set))
      for k in pairs(s._data) do
        self._data[k] = true
        self._size = self._size + 1
      end
    end
  end,

  size = function(self)
    return self._size
  end,

  __len = function(self)
    return self._size
  end,

  contains = function(self, e)
    return self._data[e]
  end,

  add = function(self, e)
    local v = self._data[e]
    if v then
      return false
    else
      self._data[e] = true
      self._size = self._size + 1
      return true
    end
  end,

  merge = function(self, s)
    assert(cl.instanceOf(s, Set))
    for k in pairs(s._data) do
      if not self._data[k] then
        self._data[k] = true
        self._size = self._size + 1
      end
    end
    return self
  end,

  elements = function(self)
    return next, self._data
  end,

  each = function(self, cb)
    for k in pairs(self._data) do
      cb(k)
    end
  end,
}

return Set

module(..., package.seeall)

local function construct(cls, ...)
  local o = setmetatable({}, cls)
  if o.init then
    o:init(...)
  end
  return o
end

function makeClass(cls, super)
  cls.class = cls
  cls.super = super
  cls.__index = cls
  return setmetatable(cls, {__call = construct, __index = super})
end

function instanceOf(o, cls)
  local c = o.class
  while c do
    if c == cls then
      return true
    else
      c = c.super
    end
  end
  return false
end

cl = {
  makeClass = makeClass,
  instanceOf = instanceOf
}

return cl

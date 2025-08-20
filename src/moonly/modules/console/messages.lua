---@class Moonly.Console.Messages
---@field private _count number
---@field private _messages string[]
local M = {
  _count    = 0,
  _messages = {}
}

--- Adds new message.
---@param str string
---@param ... any
function M:add(str, ...)
  if select("#", ...) > 0 then
    str = str:format(...)
  end

  self._count = self._count + 1
  self._messages[self._count] = str
end

function M:count()
  return self._count
end

function M:get()
  return self._messages
end

function M:at(idx)
  return self._messages[idx]
end

function M:clear()
  self._count = 0
  self._messages = {}
end

return M

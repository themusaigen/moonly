-- console/log.lua
-- Description: Console logging service.
-- Author: Musaigen

---@class Moonly.Console.LoggingService
---@field private console Moonly.Console
local M         = {}

local tags      = require("moonly.modules.console.tags")
local constants = require("moonly.modules.console.constants")

function M:initialize(console)
  self.console = console

  -- Subscribe to events.
  addEventHandler("onSystemMessage", function(...)
    self:on_system_message(...)
  end)

  addEventHandler("onScriptMessage", function(...)
    self:on_script_message(...)
  end)
end

--- Produces logging.
---@param message string
---@param tag string?
---@param color number?
---@param sender LuaScript?
function M:log(message, tag, color, sender, prefix)
  local str = ""
  if prefix then
    str = string.format("{%06X}[%s] ", constants.COLOR_MSG, prefix)
  end
  if tag then
    str = str .. string.format("{%06X}(%s) ", color, tag)
  end
  if sender then
    str = str .. string.format("{%06X}%s: ", constants.COLOR_SENDER, sender.name)
  end
  self.console.messages:add("%s{%06X}%s", str, constants.COLOR_MSG, message)
end

function M:on_system_message(message, type, sender)
  if tags.is_debug(type) then
    return
  end

  local prefix = tags.get_tag_prefix(type)
  local color = tags.get_tag_color(type)
  self:log(message, prefix, color, sender, "ML")
end

function M:on_script_message(message, sender)
  self:log(message, "script", constants.COLOR_SCRIPTMSG, sender, "ML")
end

return M

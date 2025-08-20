---@class Moonly.Console.KeyHandlerService
---@field private console Moonly.Console
---@field private key number
local M = {}

-- Virtual keys library.
local keys = require("vkeys")

-- Predefined constants.
local constants = require("moonly.modules.console.constants")

--- Initializes keyhandler service.
---@param console Moonly.Console
function M:initialize(console)
  self.console = console
  self.key = keys.name_to_id(console.key)

  -- Subscribe to events.
  addEventHandler("onWindowMessage", function(...)
    self:on_window_message(...)
  end)
end

--- Handles Windows Messages.
---@param message number
---@param wparam number
---@param lparam number
function M:on_window_message(message, wparam, lparam)
  if not (message == constants.WM_KEYDOWN) then
    return
  end

  local repeat_count = bit.band(lparam, constants.KF_REPEAT)
  if repeat_count > 0 then
    return
  end

  local need_to_handle = wparam == self.key or wparam == keys.VK_ESCAPE
  if need_to_handle then
    self.console:on_key_press(wparam == keys.VK_ESCAPE)
  end
end

return M

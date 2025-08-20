-- console.lua
-- Description: Moonly's console.
-- Author: Musaigen

local logger = require("moonly.logger")

--- Check is upmimgui present.
do
  local success = pcall(require, "upmimgui")
  if not success then
    logger:error("Console requires upmimgui to work. Please install upmimgui.")
    return {}
  end
end

local tags = require("moonly.modules.console.tags")

---@class Moonly.Console: Moonly.Module
---@field enabled boolean
---@field key string
---@field messages Moonly.Console.Messages
---@field private _logger Moonly.Console.LoggingService
---@field private _gui Moonly.Console.GuiService
---@field private _keyhandler Moonly.Console.KeyHandlerService
local M = {
  enabled  = false,
  key      = "`",
  messages = require("moonly.modules.console.messages"),
  saved    = {},
}

function M:initialize(config)
  self.enabled          = config["moonly.console.enable"] or false
  self.key              = config["moonly.console.key"] or "`"

  -- Singleplayer.
  local is_enable_in_sp = config["moonly.console.singleplayer.auto-enable"] or true
  if is_enable_in_sp and not isSampLoaded() then
    self.enabled = true
  end

  if not self.enabled then
    return
  end

  -- Initialize services.
  self._logger = require("moonly.modules.console.log")
  self._logger:initialize(self)

  self._gui = require("moonly.modules.console.gui")
  self._gui:initialize(self, config)

  self._keyhandler = require("moonly.modules.console.keyhandler")
  self._keyhandler:initialize(self)

  -- Add saved messages from moonly's logger.
  for _, msg in ipairs(self.saved) do
    local level = msg.level
    local message = msg.message
    if level then
      local type = tags.get_tag_type(level)
      local prefix = tags.get_tag_prefix(type)
      local color = tags.get_tag_color(type)
      self._logger:log(message, prefix, color, nil, "MLY")
    else
      self._logger:log(message)
    end
  end

  -- Clear saved messages.
  self.saved = {}
end

---@param escape boolean
function M:on_key_press(escape)
  if isSampLoaded() and isSampAvailable() and sampIsCursorActive() then
    return
  end

  if escape then
    if not self._gui:is_drawing() then
      return
    end
  end

  if escape then
    self._gui:hide()
  else
    self._gui:toggle()
  end

  consumeWindowMessage(true, true)
end

--- Adds new internally non-edited message.
---@param message string
---@param ... any
function M:add_message(message, ...)
  if select("#", ...) > 0 then
    message = message:format(...)
  end

  self.messages:add(message)
end

function M:save_message(level, message)
  self.saved[#self.saved + 1] = { level = level, message = message }
end

function M:save(config)
  config["moonly.console.window.x"] = self._gui.x
  config["moonly.console.window.y"] = self._gui.y
  config["moonly.console.window.width"] = self._gui.width
  config["moonly.console.window.height"] = self._gui.height
end

return M

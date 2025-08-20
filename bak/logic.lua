local M               = {}

-- Virtual keys library.
local keys            = require("vkeys")

-- Win32 constants.
local WM_KEYDOWN      = 0x0100
local KF_REPEAT       = 0x40000000

-- MoonLoader constants.
local COLOR_MSG       = 0xC0C0C0
local COLOR_SCRIPTMSG = 0x7DD156
local COLOR_SENDER    = 0xE0E0E0

local TAG             = require("moonloader").message_prefix
local TAGS            = {
  [TAG.TYPE_INFO]      = { "info", 0xA9EFF5 },
  [TAG.TYPE_DEBUG]     = { "debug", 0xAFA9F5 },
  [TAG.TYPE_ERROR]     = { "error", 0xFF7070 },
  [TAG.TYPE_WARN]      = { "warn", 0xF5C28E },
  [TAG.TYPE_SYSTEM]    = { "system", 0xFA9746 },
  [TAG.TYPE_FATAL]     = { "fatal", 0x040404 },
  [TAG.TYPE_EXCEPTION] = { "exception", 0xF5A9A9 }
}

--- Initializes the logic module.
---@param core Moonly.Console
function M:initialize(core)
  self._core = core

  addEventHandler("onWindowMessage", function(...)
    self:on_window_message(...)
  end)

  addEventHandler("onScriptMessage", function(...)
    self:on_script_message(...)
  end)

  addEventHandler("onSystemMessage", function(...)
    self:on_system_message(...)
  end)
end

function M:get_tag_text(n)
  local tag = TAGS[n]
  return tag ~= nil and tag[1] or nil
end

function M:get_tag_color(n)
  local tag = TAGS[n]
  return tag ~= nil and tag[2] or nil
end

function M:log_message(msg, tagtext, tagcolor, sender)
  local str = string.format("{%06X}[ML] ", COLOR_MSG)
  if tagtext then
    str = str .. string.format("{%06X}(%s) ", tagcolor, tagtext)
  end
  if sender then
    str = str .. string.format("{%06X}%s: ", COLOR_SENDER, sender.name)
  end
  self._core:add_message(string.format("%s{%06X}%s", str, COLOR_MSG, msg))
end

function M:on_system_message(message, type, sender)
  if type == TAG.TYPE_DEBUG then
    return
  end

  local tagtxt = self:get_tag_text(type)
  local tagclr = self:get_tag_color(type) or COLOR_MSG
  self:log_message(message, tagtxt, tagclr, sender)
end

function M:on_script_message(message, sender)
  self:log_message(message, "script", COLOR_SCRIPTMSG, sender)
end

function M:on_window_message(message, wparam, lparam)
  if isSampfuncsConsoleActive() and isSampLoaded() and isSampAvailable() then
    if sampIsCursorActive() then
      return
    end
  end

  if not (message == WM_KEYDOWN) then
    return
  end

  local repeat_count = bit.band(lparam, KF_REPEAT)
  if repeat_count > 0 then
    return
  end

  if wparam == keys.name_to_id(self._core.key) then
    self._core.window[0] = not self._core.window[0]
    --consumeWindowMessage(true, true)
  elseif self._core.window[0] then
    if wparam == keys.VK_ESCAPE then
      self._core.window[0] = false
      consumeWindowMessage(true, true)
    end
  end
end

return M

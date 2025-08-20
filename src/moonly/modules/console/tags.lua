-- console/tags.lua
-- Description: Utility module to work with tags.
-- Author: Musaigen

local M = {}

local TAG = require("moonloader").message_prefix
local TAGS = {
  [TAG.TYPE_INFO]      = { "info", 0xA9EFF5 },
  [TAG.TYPE_DEBUG]     = { "debug", 0xAFA9F5 },
  [TAG.TYPE_ERROR]     = { "error", 0xFF7070 },
  [TAG.TYPE_WARN]      = { "warn", 0xF5C28E },
  [TAG.TYPE_SYSTEM]    = { "system", 0xFA9746 },
  [TAG.TYPE_FATAL]     = { "fatal", 0x040404 },
  [TAG.TYPE_EXCEPTION] = { "exception", 0xF5A9A9 },
}
local TAG_MAP = {
  info      = TAG.TYPE_INFO,
  debug     = TAG.TYPE_DEBUG,
  error     = TAG.TYPE_ERROR,
  warn      = TAG.TYPE_WARN,
  system    = TAG.TYPE_SYSTEM,
  fatal     = TAG.TYPE_FATAL,
  exception = TAG.TYPE_EXCEPTION,
}

function M.get_tag_prefix(type)
  local tag = TAGS[type]
  return tag and tag[1]
end

function M.get_tag_color(type)
  local tag = TAGS[type]
  return tag and tag[2]
end

function M.get_tag_type(prefix)
  return TAG_MAP[prefix:lower()]
end

function M.is_debug(type)
  return type == TAG.TYPE_DEBUG
end

return M

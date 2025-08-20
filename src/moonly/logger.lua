-- logger.lua
-- Purpose: Simple logging module with file output and log levels.
-- Author: Musaigen

local M = {
  _file = nil,
}

local path = require("moonly.path")


--- Internal function to write a log entry to the file.
---@param level string? # Log level (DEBUG/INFO/WARN/ERROR)
---@param fmt string # Format string
---@param ... any # Arguments for format string
function M:entry(level, fmt, ...)
  -- Open file if not already open
  if not self._file then
    local log_file_path = path.concat(getWorkingDirectory(), "moonly.log")
    self._file = io.open(log_file_path, "w+")
    if not self._file then
      return -- Cannot log if file cannot be opened
    end
  end

  -- Ensure fmt is a string
  if type(fmt) ~= "string" then
    fmt = tostring(fmt)
  end

  -- Format message
  local message
  if select("#", ...) > 0 then
    message = fmt:format(...)
  else
    message = fmt
  end

  -- Get milliseconds
  local _, milliseconds = math.modf(os.clock())

  -- Format log line
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_line
  if level then
    log_line = string.format("[%s] [%s:%d]: %s\n", level, timestamp, milliseconds * 1000, message)
  else
    log_line = string.format("%s\n", message)
  end

  local console = require("moonly.modules.console")
  if console.save_message then
    console:save_message(level, message)
  end

  -- Write and flush
  self._file:write(log_line)
  self._file:flush()
end

--- Logs an non-categorized message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:log(fmt, ...)
  self:entry(nil, fmt, ...)
end

--- Logs an system message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:system(fmt, ...)
  self:entry("SYSTEM", fmt, ...)
end

--- Logs a debug message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:debug(fmt, ...)
  self:entry("DEBUG", fmt, ...)
end

--- Logs an informational message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:info(fmt, ...)
  self:entry("INFO", fmt, ...)
end

--- Logs a warning message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:warn(fmt, ...)
  self:entry("WARN", fmt, ...)
end

--- Logs an error message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:error(fmt, ...)
  self:entry("ERROR", fmt, ...)
end

--- Logs an fatal error message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function M:fatal(fmt, ...)
  self:entry("FATAL", fmt, ...)
end

--- Closes the log file.
function M:close()
  if self._file then
    self._file:close()
    self._file = nil
  end
end

return M

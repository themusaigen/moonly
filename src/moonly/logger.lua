-- logger.lua
-- Purpose: Simple logging module with file output and log levels.
-- Author: Musaigen

local logger = {
  _file = nil,
}

local path = require("moonly.path")

--- Internal function to write a log entry to the file.
---@param level string # Log level (DEBUG/INFO/WARN/ERROR)
---@param fmt string # Format string
---@param ... any # Arguments for format string
function logger:entry(level, fmt, ...)
  -- Open file if not already open
  if not self._file then
    local log_file_path = path.concat(getWorkingDirectory(), "moonly.log")
    self._file = io.open(log_file_path, "w+")
    if not self._file then
      return       -- Cannot log if file cannot be opened
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

  -- Format log line
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_line = string.format("[%s] [%s]: %s\n", level, timestamp, message)

  -- Write and flush
  self._file:write(log_line)
  self._file:flush()
end

--- Logs a debug message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function logger:debug(fmt, ...)
  self:entry("DEBUG", fmt, ...)
end

--- Logs an informational message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function logger:info(fmt, ...)
  self:entry("INFO", fmt, ...)
end

--- Logs a warning message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function logger:warn(fmt, ...)
  self:entry("WARN", fmt, ...)
end

--- Logs an error message.
---@param fmt string # Message format string
---@param ... any # Values to insert into format string
function logger:error(fmt, ...)
  self:entry("ERROR", fmt, ...)
end

--- Closes the log file.
function logger:close()
  if self._file then
    self._file:close()
    self._file = nil
  end
end

return logger

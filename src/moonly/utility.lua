-- utility.lua
-- Purpose: Provide common file and JSON handling utilities.
-- Author: Musaigen

local dkjson = require("dkjson")
local logger = require("moonly.logger")

local utility = {}

--- Writes a Lua table to a JSON file with pretty-print formatting.
---@param path string # Full path to the output file
---@param data table # Data to encode and write
---@return boolean success # True if write was successful, false otherwise
function utility.write_json(path, data)
  -- Validate input
  if type(data) ~= "table" then
    logger:error("write_json -> invalid data type: expected table, got %s", type(data))
    return false
  end

  local file = io.open(path, "w+")
  if not file then
    logger:error("write_json -> failed to open file for writing: %s", path)
    return false
  end

  local json_str = dkjson.encode(data, { indent = true })
  if not json_str then
    logger:error("write_json -> JSON encoding failed: %s", path)
    file:close()
    return false
  end

  file:write(json_str)
  file:close()
  logger:debug("write_json -> successfully wrote to %s", path)
  return true
end

--- Reads a JSON file and returns it as a Lua table.
---@param path string # Full path to the JSON file
---@return table|nil decoded_data # Parsed JSON data, or nil on error
function utility.read_json(path)
  if not doesFileExist(path) then
    logger:warn("read_json -> file does not exist: %s", path)
    return nil
  end

  local file = io.open(path, "r")
  if not file then
    logger:error("read_json -> failed to open file: %s", path)
    return nil
  end

  local content = file:read("*a")
  file:close()

  local data = dkjson.decode(content)
  if not data then
    logger:error("read_json -> JSON decoding failed at position: %s", path)
    return nil
  end

  logger:debug("read_json -> successfully read from %s", path)
  ---@cast data table
  return data
end

--- Reads the contents of a text file.
---@param path string # Full path to the file
---@return string|nil # File content, or nil on error
function utility.read_file(path)
  if not doesFileExist(path) then
    logger:warn("read_file -> file does not exist: %s", path)
    return nil
  end

  local file = io.open(path, "r")
  if not file then
    logger:error("read_file -> failed to open file: %s", path)
    return nil
  end

  local content = file:read("*a")
  file:close()

  logger:debug("read_file -> successfully read from %s", path)
  return content
end

return utility

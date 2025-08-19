-- utility.lua
-- Purpose: Provide common file and JSON handling utilities.
-- Author: Musaigen

local dkjson = require("dkjson")

local M = {}

--- Writes a Lua table to a JSON file with pretty-print formatting.
---@param path string # Full path to the output file
---@param data table # Data to encode and write
---@return boolean success # True if write was successful, false otherwise
function M.write_json(path, data)
  -- Validate input
  if type(data) ~= "table" then
    return false
  end

  local file = io.open(path, "w+")
  if not file then
    return false
  end

  local json_str = dkjson.encode(data, { indent = true })
  if not json_str then
    file:close()
    return false
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  file:write(json_str)
  file:close()
  return true
end

--- Reads a JSON file and returns it as a Lua table.
---@param path string # Full path to the JSON file
---@return table|nil decoded_data # Parsed JSON data, or nil on error
function M.read_json(path)
  local content = M.read_file(path)
  if not content then
    return nil
  end

  local data = dkjson.decode(content)
  if not data then
    return nil
  end

  ---@cast data table
  return data
end

--- Reads the contents of a text file.
---@param path string # Full path to the file
---@return string|nil # File content, or nil on error
function M.read_file(path)
  if not doesFileExist(path) then
    return nil
  end

  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()
  return content
end

return M

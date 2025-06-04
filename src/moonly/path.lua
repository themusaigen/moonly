-- path.lua
-- Purpose: Utility module for working with file and directory paths.
-- Author: Musaigen

local M = {}

local lfs = require("lfs")

--- Returns the default temporary directory used by Moonly.
--- Creates it if it doesn't exist.
---@return string # Path to the Moonly temporary directory
function M.get_moonly_temp_directory()
  local moonly_temp_dir = M.concat(os.getenv("TEMP"), "moonly")

  if not doesDirectoryExist(moonly_temp_dir) then
    createDirectory(moonly_temp_dir)
  end

  return moonly_temp_dir
end

--- Traverses a directory recursively or non-recursively, applying a callback to each entry.
---@param dir string # Directory to traverse
---@param callback fun(base_path: string, entry: string, isdirectory: boolean) # Function to call on each entry
---@param recursive boolean|nil # Whether to recurse into subdirectories
function M.traverse(dir, callback, recursive)
  if type(callback) ~= "function" then
    error("Callback must be a function")
  end

  -- Helper to process one directory entry
  local function process_entry(entry_name)
    if entry_name == "." or entry_name == ".." then
      return
    end

    local full_path = M.concat(dir, entry_name)
    local attributes = lfs.attributes(full_path)

    if not attributes then
      return
    end

    callback(dir, entry_name, attributes.mode == "directory")

    if recursive and attributes.mode == "directory" then
      M.traverse(full_path, callback, true)
    end
  end

  -- Traverse directory entries
  for entry in lfs.dir(dir) do
    process_entry(entry)
  end
end

--- Concatenates multiple path segments using backslashes (`\`).
---@param ... string # One or more path components
---@return string # The joined path
function M.concat(...)
  return table.concat({ ... }, "\\")
end

--- Extracts the last part of a file or directory path.
--- For example, `C:/folder/file.txt` ? `file.txt`
---@param input string # Full path
---@return string|nil # Last component of the path, or nil if invalid
function M.get_last_entry_name(input)
  return input:match("[\\/]([^\\/]+)$")
end

return M

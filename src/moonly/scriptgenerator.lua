-- scriptgenerator.lua
-- Purpose: Generates and writes temporary Lua scripts for project bootstrapping.
-- Author: Musaigen

local M = {}

-- Require external modules
require("moonly.string")
local path = require("moonly.path")

--- Generates the source code template for a temporary Moonloader script.
---@param project Moonly.Project # Project object with metadata and paths
---@return string # Generated Lua script content
function M:generate_source_code(project)
  local init_path = project:init_script_path():gsub("\\", "\\\\") -- Escape backslashes
  local root_dir = project:root_directory():gsub("\\", "\\\\")    -- Escape backslashes

  local source_template = [[
local script = loadfile("<path>")
if not script then
  print("failed to load source code of <path>")
  return
end

-- Get the environment of this script.
local env = getfenv(script)

-- Get the `package` lib of script.
local package = env.package

-- Prepare paths for mixinning them into package.path and package.cpath
local paths = {
  "<root>\\<src>\\?.lua;",
  "<root>\\<src>\\?\\init.lua;",
  "<root>\\<src>\\?.luac;",
  "<root>\\<src>\\?\\init.luac;",
  "<root>\\<lib>\\?.lua;",
  "<root>\\<lib>\\?\\init.lua;",
  "<root>\\<lib>\\?.luac;",
  "<root>\\<lib>\\?\\init.luac;"
}

-- Mixin package.cpath
package.cpath = "<root>\\<lib>\\?.dll;" .. package.cpath

-- Mixin package.path
for _, value in ipairs(paths) do
  package.path = value .. package.path
end

-- Patching ffi.load (for mimgui and other libraries using FFI)
local ffi = require("ffi")
local load = ffi.load
ffi.load = function(libname)
  local success, library = pcall(load, libname)
  if success then
    return library
  elseif type(libname) == "string" then
    -- Escape slashes if needeed.
    local cwd = getWorkingDirectory():gsub("/", "\\")
    local path = libname:gsub("/", "\\")

	  -- Check if string starts with project root.
    if path:sub(1, #cwd) == cwd then
      -- Replace it with new directory.
      local new_path = getMoonloaderDirectory() .. "\\" .. path:sub(#cwd + 1)
      return load(new_path)
    else
      error(library)
    end
  else
    error(library)
  end
end

-- Patch getWorkingDirectory to return the project root
local original_getWorkingDirectory = env.getWorkingDirectory
getWorkingDirectory = function()
  return "<root>"
end

-- Inject new method `getMoonloaderDirectory`
env.getMoonloaderDirectory = function()
  return original_getWorkingDirectory()
end

-- Define global constants for environment detection
env.MOONLY_ENVIRONMENT = true
env.MOONLY_VERSION = <version>

-- Set new environment.
setfenv(script, env)

-- Execute script
script()
]]

  -- Replace placeholders with real values
  source_template = source_template
      :gsub("<path>", init_path)
      :gsub("<root>", root_dir)
      :gsub("<src>", project:source_directory_name())
      :gsub("<lib>", project:libraries_directory_name())
      :gsub("<version>", script.this.version_num)

  return source_template
end

--- Generates a temporary script file and returns its path.
---@param project Moonly.Project # Project object with metadata and paths
---@return string|nil # Path to the generated script file, or nil on failure
function M:generate_scriptfile(project)
  -- Format temporary file path
  local temp_dir = path.get_moonly_temp_directory()
  local filename = string.concat(project:name(), ".lua")
  local scriptpath = path.concat(temp_dir, filename)

  -- Open file for writing
  local file = io.open(scriptpath, "w+")
  if not file then
    return nil
  end

  -- Write generated source code
  local source = self:generate_source_code(project)
  if source == "" then
    file:close()
    os.remove(scriptpath)
    return nil
  end

  file:write(source)
  file:close()
  return scriptpath
end

return M

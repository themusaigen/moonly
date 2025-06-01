-- scriptgenerator.lua
-- Purpose: Generates and writes temporary Lua scripts for project bootstrapping.
-- Author: Musaigen

local scriptgenerator = {}

-- Require external modules
require("moonly.string")
local path = require("moonly.path")
local utility = require("moonly.utility")
local logger = require("moonly.logger")

--- Generates the source code template for a temporary Moonloader script.
---@param project table # Project object with metadata and paths
---@return string # Generated Lua script content
function scriptgenerator:generate_source_code(project)
  local root_dir = project:root_directory():gsub("\\", "\\\\") -- Escape backslashes

  local source_template = [[
do
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
      local found = string.find(libname, getWorkingDirectory())
      if found then
        return load(string.gsub(libname, getWorkingDirectory(), getMoonloaderDirectory()))
      else
        error(library)
      end
    else
      error(library)
    end
  end

  -- Patch getWorkingDirectory to return the project root
  local original_getWorkingDirectory = getWorkingDirectory
  getWorkingDirectory = function()
    return "<root>"
  end

  -- Inject new method `getMoonloaderDirectory`
  getMoonloaderDirectory = function()
    return original_getWorkingDirectory()
  end

  -- Define global constants for environment detection
  MOONLY_ENVIRONMENT = true
  MOONLY_VERSION = <version>
end

<init>
]]

  -- Replace placeholders with real values
  source_template = source_template
      :gsub("<root>", root_dir)
      :gsub("<src>", project:source_directory_name())
      :gsub("<lib>", project:libraries_directory_name())
      :gsub("<version>", script.this.version_num)

  -- Insert init script content
  local init_script_content = utility.read_file(project:init_script_path())
  if not init_script_content then
    logger:error("Failed to read init script from %s", project:init_script_path())
    return ""
  end

  source_template = source_template:gsub("<init>", init_script_content)

  return source_template
end

--- Generates a temporary script file and returns its path.
---@param project table # Project object with metadata and paths
---@return string|nil # Path to the generated script file, or nil on failure
function scriptgenerator:generate_scriptfile(project)
  -- Format temporary file path
  local temp_dir = path.get_moonly_temp_directory()
  local filename = string.concat(project:name(), ".lua")
  local scriptpath = path.concat(temp_dir, filename)

  -- Open file for writing
  local file = io.open(scriptpath, "w+")
  if not file then
    logger:error("Cannot create temporary script file at %s", scriptpath)
    return nil
  end

  -- Write generated source code
  local source = self:generate_source_code(project)
  if source == "" then
    logger:error("Failed to generate source code for %s", project:name())
    file:close()
    os.remove(scriptpath)
    return nil
  end

  file:write(source)
  file:close()

  logger:debug("Generated temporary script at %s", scriptpath)
  return scriptpath
end

return scriptgenerator

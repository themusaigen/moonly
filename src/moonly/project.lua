-- project.lua
-- Purpose: Represents a project with configuration and directory structure.
-- Author: Musaigen

---@class Moonly.Project
---@field private _name string
---@field private _source_dirname string
---@field private _libraries_dirname string
---@field private _root_directory string
---@field private _source_dir string
---@field private _libraries_dir string
---@field private _init_path string
---@field private _script LuaScript
local M       = {}

local path    = require("moonly.path")
local utility = require("moonly.utility")

--- Creates a new Project instance based on a directory containing a 'project.json'.
--- @param directory string # Path to the project root directory
--- @return Moonly.Project? # New project object or nil if loading failed
function M.new(directory)
  local project_file_path = path.concat(directory, "project.json")
  local project_config = utility.read_json(project_file_path)

  if not project_config then
    return nil
  end

  -- Validate required fields
  local name              = project_config.name or path.get_last_entry_name(directory)
  local source_dirname    = project_config.source or "src"
  local libraries_dirname = project_config.library or "lib"

  -- Create project instance
  local self              = setmetatable({
    _name              = name,
    _source_dirname    = source_dirname,
    _libraries_dirname = libraries_dirname,
    _root_directory    = directory,

    _source_dir        = "",
    _libraries_dir     = "",
    _init_path         = "",
  }, { __index = M })

  -- Post-initialization setup
  self._source_dir        = path.concat(self._root_directory, self._source_dirname)
  self._libraries_dir     = path.concat(self._root_directory, self._libraries_dirname)
  self._init_path         = path.concat(self._source_dir, "init.lua")

  return self
end

--- Returns the name of the project.
---@return string
function M:name()
  return self._name
end

--- Returns the name of the source directory (e.g., "src").
---@return string
function M:source_directory_name()
  return self._source_dirname
end

--- Returns the name of the libraries directory (e.g., "lib").
---@return string
function M:libraries_directory_name()
  return self._libraries_dirname
end

--- Returns the absolute path to the project root directory.
---@return string
function M:root_directory()
  return self._root_directory
end

--- Returns the full path to the source directory.
--- @return string
function M:source_directory()
  return self._source_dir
end

--- Returns the full path to the libraries directory.
---@return string
function M:libraries_directory()
  return self._libraries_dir
end

--- Returns the full path to the init script file (e.g., "src/init.lua").
---@return string
function M:init_script_path()
  return self._init_path
end

--- Returns the associated script object if it was assigned.
---@return LuaScript?
function M:script()
  return self._script
end

return M

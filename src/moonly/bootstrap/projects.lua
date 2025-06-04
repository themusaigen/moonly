local M               = {}

local Project         = require("moonly.project")

local logger          = require("moonly.logger")
local path            = require("moonly.path")
local scriptgenerator = require("moonly.scriptgenerator")
local action_type     = require("moonly.bootstrap.action_type")

--- Loads a project by generating and running its temporary script.
---@param project table # Project object
function M:load_project(project)
  if not project then
    logger:warn("Trying to load invalid project")
    return
  end

  -- This method will unload project if it is loaded.
  self:unload_project(project)

  -- Generate mixin scriptfile.
  local scriptfile = scriptgenerator:generate_scriptfile(project)
  if not scriptfile then
    logger:error("Failed to generate script file for project '%s'", project:name())
    return
  end

  -- Load project.
  project._script = script.load(scriptfile)

  -- Tell the modules about newbie.
  self:emit("register", project)
end

--- Unloads a project's script and waits for it to terminate.
---@param project table # Project object
function M:unload_project(project)
  if not project then
    logger:warn("attempt to unload invalid project")
    return
  end

  if project:script() and not project:script().dead then
    -- Unload the script.
    project:script():unload()

    -- Add this project`s script to unload queue.
    self:new_action(action_type.UNLOAD, project)
  end
end

--- Reboots a project by unloading and reloading it.
---@param project table # Project object
function M:reboot_project(project)
  if not project then
    logger:warn("Attempted to reboot invalid project")
    return
  end

  -- If script present and not unloaded.
  if project:script() and not project:script().dead then
    -- Unload this script.
    project:script():unload()

    -- Add this project to reboot queue.
    self:new_action(action_type.REBOOT, project)
  else
    -- Just load the project.
    self:load_project(project)
  end
end

--- Scans configured runtime paths for projects and loads them.
function M:_initialize_projects()
  logger:info("Initializing projects...")

  for _, directory in ipairs(self:configuration_runtime_path()) do
    if not doesDirectoryExist(directory) then
      createDirectory(directory)
    end

    self:_lookup_for_projects_in_directory(directory)
  end
end

--- Checks a directory for a valid project and initializes it if found.
---@param directory string # Full path to the directory to check
---@return boolean # True if a project was initialized, false otherwise
function M:_lookup_for_project_in_directory(directory)
  local project = Project.new(directory)
  if project then
    logger:info("Initialized project '%s'", project:name())
    self:load_project(project)
    table.insert(self._projects, project)
    return true
  end

  return false
end

--- Recursively searches for project.json files in a directory and initializes projects.
---@param directory string # Directory to search in
function M:_lookup_for_projects_in_directory(directory)
  local project = self:_lookup_for_project_in_directory(directory)
  if not project then
    path.traverse(directory, function(base_path, entry, isdirectory)
      if isdirectory then
        self:_lookup_for_project_in_directory(path.concat(base_path, entry))
      end
    end)
  end
end

return M

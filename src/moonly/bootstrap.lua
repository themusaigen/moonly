-- bootstrap.lua
-- Purpose: Bootstrap module to initialize and manage projects, modules, and scripts.
-- Author: Musaigen

local bootstrap       = {
  _projects      = {},
  _modules       = {},
  _configuration = {},
}

local Project         = require("moonly.project")
local scriptgenerator = require("moonly.scriptgenerator")
local path            = require("moonly.path")
local logger          = require("moonly.logger")

require("moonly.string") -- Assuming this is for string.concat()

--- Initializes the system with the provided configuration.
---@param configuration table # Configuration loaded from moonly.json
function bootstrap:initialize(configuration)
  self._configuration = configuration or {}

  self:_initialize_modules()
  self:_initialize_module_threads()
  self:_initialize_projects()
end

--- Emits an event to all registered modules.
---@param fun string # Name of the function to call
---@param ... any # Arguments to pass to the function
function bootstrap:emit(fun, ...)
  for _, module in ipairs(self:modules()) do
    if type(module[fun]) == "function" then
      module[fun](module, ...)
    end
  end
end

--- Recursively searches for project.json files in a directory and initializes projects.
---@param directory string # Directory to search in
function bootstrap:_lookup_for_projects_in_directory(directory)
  local project = Project.new(directory)
  if project then
    logger:info("Initialized project '%s'", project:name())
    self:load_project(project)
    self._projects[#self._projects + 1] = project
  else
    path.traverse(directory, function(base_path, entry, isdirectory)
      if isdirectory then
        local full_path = path.concat(base_path, entry)
        self:_lookup_for_projects_in_directory(full_path)
      end
    end)
  end
end

--- Initializes core and user-defined modules.
function bootstrap:_initialize_modules()
  logger:info("Initializing modules...")

  for _, mod in ipairs(self:configuration().modules or {}) do
    local module_name = mod.core and string.concat("moonly.modules.", mod.name) or mod.name
    local module = require(module_name)

    if module.initialize then
      module:initialize(mod.options or {})
    end

    self._modules[#self._modules + 1] = module
    logger:info("Module '%s' initialized", mod.name)
  end
end

--- Creates background threads for modules that have a tick function.
function bootstrap:_initialize_module_threads()
  logger:info("Initializing module threads...")

  for _, module in ipairs(self:modules()) do
    if type(module.tick) == "function" then
      lua_thread.create(function()
        while true do
          wait(0)
          module:tick()
        end
      end)
    end
  end
end

--- Scans configured runtime paths for projects and loads them.
function bootstrap:_initialize_projects()
  logger:info("Initializing projects...")

  for _, directory in ipairs(self:configuration().runtime.path or {}) do
    if not doesDirectoryExist(directory) then
      createDirectory(directory)
    end

    self:_lookup_for_projects_in_directory(directory)
  end
end

--- Loads a project by generating and running its temporary script.
---@param project table # Project object
function bootstrap:load_project(project)
  self:unload_project(project)

  if project then
    local scriptfile = scriptgenerator:generate_scriptfile(project)
    if scriptfile then
      project._script = script.load(scriptfile)
      self:emit("register", project)
    else
      logger:error("Failed to generate script file for project '%s'", project:name())
    end
  end
end

--- Unloads a project's script and waits for it to terminate.
---@param project table # Project object
function bootstrap:unload_project(project)
  if project and project:script() then
    project:script():unload()

    lua_thread.create(function()
      while not project:script().dead do
        wait(0)
      end

      project._script = nil
    end)
  end
end

--- Reboots a project by unloading and reloading it in a new thread.
---@param project table # Project object
function bootstrap:reboot_project(project)
  if project and project:script() then
    lua_thread.create(function()
      self:unload_project(project)

      while project:script() and not project:script().dead do
        wait(0)
      end

      self:load_project(project)
    end)
  end
end

--- Unloads all projects and emits an unload event.
function bootstrap:unload()
  for _, project in ipairs(self:projects()) do
    self:emit("unregister", project)
  end

  self:emit("unload")
end

--- Finds a project by its associated script.
---@param scr table # Script object
---@return table|nil # Matching project or nil
function bootstrap:find_project_by_script(scr)
  for _, project in ipairs(self:projects()) do
    if project:script() == scr then
      return project
    end
  end
  return nil
end

--- Returns the list of all loaded modules.
---@return table
function bootstrap:modules()
  return self._modules
end

--- Returns the current configuration.
---@return table
function bootstrap:configuration()
  return self._configuration
end

--- Returns the list of all loaded projects.
---@return table
function bootstrap:projects()
  return self._projects
end

return bootstrap

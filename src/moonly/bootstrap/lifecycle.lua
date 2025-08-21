local M = {
  ---@type Moonly.Project[]
  _projects                 = {},
  ---@type Moonly.Action[]
  _pending_projects_actions = {},
  ---@type Moonly.Module[]
  _modules                  = {},
  ---@type Moonly.Configuration
  _configuration            = {},
}

local logger = require("moonly.logger")
local utility = require("moonly.utility")
local configurator = require("moonly.configurator")
local path = require("moonly.path")

--- Initializes the system with the provided configuration.
---@param configuration Moonly.Configuration # Configuration loaded from moonly.json
function M:initialize(configuration)
  self._configuration = configuration

  self:_initialize_modules()
  self:_initialize_module_threads()
  self:_initialize_projects()
end

--- Unloads all projects and emits an unload event.
---@param died boolean # Is our script died due to some errors or not.
---@param quit boolean # Is we quitting game?
function M:unload(died, quit)
  -- Unregister all projects
  for _, project in ipairs(self:projects()) do
    ---@cast project Moonly.Project

    self:emit("unregister", project)

    -- Unload the project.
    if died then
      local script = project:script()
      if script and not script.dead then
        script:unload()

        logger:system("%s: Project terminated.", project:name())
      end
    end
  end

  -- In case where our script is died, but not because we are leaving the game...
  -- ...to prevent reloading projects from ML-Autoreboot when moonly.lua will be reloaded by a user...
  -- ...we create file-marker that tells moonly to not delete the %TEMP%/moonly directory.
  if died and not quit then
    io.open(path.concat(path.get_moonly_temp_directory(), "moonly.nodelete"), "w+"):close()
  end

  -- Emit save configuration event.
  self:emit("save", self._configuration)

  -- Save.
  utility.write_json(configurator:get_configuration_file_path(), self._configuration)

  -- Emit unload event
  self:emit("unload")

  -- Clear pending actions
  if self._pending_projects_actions then
    self._pending_projects_actions = {}
  end

  -- Optionally clear other internal state
  self._projects = {}
  self._modules = {}
end

return M

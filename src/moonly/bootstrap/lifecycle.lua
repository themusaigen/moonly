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

--- Initializes the system with the provided configuration.
---@param configuration Moonly.Configuration # Configuration loaded from moonly.json
function M:initialize(configuration)
  self._configuration = configuration

  self:_initialize_modules()
  self:_initialize_module_threads()
  self:_initialize_projects()
end

--- Unloads all projects and emits an unload event.
---@param unload boolean # Unload existing projects or not.
function M:unload(unload)
  -- Unregister all projects
  for _, project in ipairs(self:projects()) do
    ---@cast project Moonly.Project

    self:emit("unregister", project)

    -- Unload the project.
    if unload then
      local script = project:script()
      if script and not script.dead then
        script:unload()

        logger:system("%s: Project terminated.", project:name())
      end
    end
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

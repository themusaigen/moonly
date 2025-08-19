local M = {
  _projects                 = {},
  _pending_projects_actions = {},
  _modules                  = {},
  _configuration            = {},
}

local logger = require("moonly.logger")
local utility = require("moonly.utility")
local configurator = require("moonly.configurator")

--- Initializes the system with the provided configuration.
---@param configuration table # Configuration loaded from moonly.json
function M:initialize(configuration)
  self._configuration = configuration or {}

  self:_initialize_modules()
  self:_initialize_module_threads()
  self:_initialize_projects()
end

--- Unloads all projects and emits an unload event.
function M:unload(unload)
  -- Unregister all projects
  for _, project in ipairs(self:projects()) do
    self:emit("unregister", project)

    -- Unload the project.
    if unload then
      local script = project:script()
      if script and not script.dead then
        script:unload()

        logger:system("%s: Project terminated.", project.name)
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

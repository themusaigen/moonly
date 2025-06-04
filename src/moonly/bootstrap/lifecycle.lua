local M = {
  _projects                 = {},
  _pending_projects_actions = {},
  _modules                  = {},
  _configuration            = {},
}

local logger = require("moonly.logger")

--- Initializes the system with the provided configuration.
---@param configuration table # Configuration loaded from moonly.json
function M:initialize(configuration)
  self._configuration = configuration or {}

  self:_initialize_modules()
  self:_initialize_module_threads()
  self:_initialize_projects()
end

--- Unloads all projects and emits an unload event.
function M:unload()
  logger:info("Shutting down Moonly's bootstrap...")

  -- Unregister all projects
  for _, project in ipairs(self:projects()) do
    self:emit("unregister", project)
  end

  -- Emit unload event
  self:emit("unload")

  -- Clear pending actions
  if self._pending_projects_actions then
    self._pending_projects_actions = {}
  end

  -- Optionally clear other internal state
  self._projects = {}
  self._modules = {}

  logger:info("Moonly`s bootstrap shutdown complete.")
end

return M

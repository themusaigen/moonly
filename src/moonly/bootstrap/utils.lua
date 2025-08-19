local M = {}

local logger = require("moonly.logger")

--- Returns the list of all loaded modules.
---@return table
function M:modules()
  return self._modules
end

--- Returns the current configuration.
---@return table
function M:configuration()
  return self._configuration
end

--- Returns the list of all loaded projects.
---@return table
function M:projects()
  return self._projects
end

--- Returns the list of modules defined in the configuration.
---@return table # List of module definitions or empty table if none
function M:configuration_modules()
  if not self._configuration then
    logger:error("Configuration is not yet loaded.")
    return {}
  end

  return self._configuration["moonly.runtime.modules"] or {}
end

--- Returns the runtime paths defined in the configuration.
---@return table # List of paths or empty table if none
function M:configuration_runtime_path()
  if not self._configuration then
    logger:error("Configuration is not yet loaded.")
    return {}
  end

  return self._configuration and self._configuration["moonly.runtime.path"] or {}
end

--- Finds a project by its associated script.
---@param scr table # Script object
---@return table|nil # Matching project or nil
function M:find_project_by_script(scr)
  for _, project in ipairs(self:projects()) do
    if project:script() == scr then
      return project
    end
  end
  return nil
end

return M

---@class Moonly.Action
---@field type Moonly.ActionType
---@field project Moonly.Project

local M = {}

local logger = require("moonly.logger")

--- Schedules an action (e.g., UNLOAD or REBOOT) to be processed later.
---@param type Moonly.ActionType # Action type (from action_type module)
---@param project Moonly.Project # Project object to apply the action to
function M:new_action(type, project)
  if not project then
    logger:error("Attempted to schedule action on nil project")
    return
  end

  if not self._pending_projects_actions then
    self._pending_projects_actions = {}
  end

  table.insert(self._pending_projects_actions, {
    type = type,
    project = project
  })
end

return M

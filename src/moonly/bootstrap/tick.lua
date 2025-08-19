local M = {}

local logger = require("moonly.logger")
local action_type = require("moonly.bootstrap.action_type")

--- Processes pending actions for projects, such as unloading or rebooting.
--- This is typically called in a tick loop.
function M:tick()
  if not self._pending_projects_actions then
    return
  end

  for i = #self._pending_projects_actions, 1, -1 do
    local action = self._pending_projects_actions[i]
    local project = action.project

    if not project or not project._script then
      logger:warn("Skipping invalid project in action queue")
      table.remove(self._pending_projects_actions, i)
      goto continue
    end

    if project._script.dead then
      if action.type == action_type.UNLOAD then
        logger:system("Unloading project '%s'", project:name())
        project._script = nil
      else
        logger:system("Rebooting project '%s'", project:name())
        self:load_project(project)
      end

      table.remove(self._pending_projects_actions, i)
    end

    ::continue::
  end
end

return M

--- action_type.lua
-- Purpose: Defines standard action types used in the system for project lifecycle management.
-- Author: Musaigen

return {
  --- Represents an unload action (e.g., stop and remove a script).
  UNLOAD = 0,

  --- Represents a reboot action (e.g., unload and reload a project).
  REBOOT = 1,
}

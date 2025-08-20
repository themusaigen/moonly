-- configurator.lua
-- Purpose: Manages configuration loading and defaults for the Moonly framework.
-- Author: Musaigen

local M       = {}

local path    = require("moonly.path")
local utility = require("moonly.utility")
local logger  = require("moonly.logger")

---@alias Moonly.Configuration table<string, any>

--- Returns a default configuration structure.
---This is used if no configuration file exists.
---@return Moonly.Configuration # A default configuration table
function M:get_default_configuration()
  return {
    ["moonly.runtime.path"] = {
      path.concat(getGameDirectory(), "moonly")
    },
    ["moonly.runtime.modules"] = {
      "autoreboot"
    },
    ["moonly.autoreboot.delay"] = 1000,
  }
end

--- Returns the full path to the configuration file (`moonly.json`).
---@return string config_path # Full path to the configuration file
function M:get_configuration_file_path()
  return path.concat(getWorkingDirectory(), "moonly.json")
end

--- Loads the configuration from disk, or creates a new one if it doesn't exist.
---@return Moonly.Configuration? # Loaded configuration table or nil on error
function M:load()
  local config_path = self:get_configuration_file_path()

  -- Try to read existing configuration
  local config = utility.read_json(config_path)
  if not config then
    logger:warn("Configuration file not found at %s. Creating default...", config_path)
    local default_config = self:get_default_configuration()

    if not utility.write_json(config_path, default_config) then
      logger:error("Failed to write default configuration to %s", config_path)
      return nil
    end

    return default_config
  else
    logger:info("Configuration path: %s", config_path)

    -- Checking for using deprecated configuration.
    if config["runtime"] then
      local errmsg =
      "You are using deprecated configuration format. Please, delete current 'moonly.json' and let the moonly to create default configuration."

      logger:error(errmsg)
      error(errmsg)
    end
  end

  return config
end

return M

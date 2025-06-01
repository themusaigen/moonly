script_name("moonly")
script_version("1.1.0")
script_version_number(1.10)
script_author("Musaigen")

-- Load required modules
local configurator = require("moonly.configurator")
local bootstrap    = require("moonly.bootstrap")
local logger       = require("moonly.logger")

--- Main entry point of the script
function main()
  -- Log script start
  logger:info("Starting moonly v" .. script.this.version)

  -- Load configuration from file
  local config = configurator:load()

  if config then
    logger:debug("Configuration loaded successfully.")
    logger:info("Initializing project system...")
    bootstrap:initialize(config)
  else
    logger:error("Failed to load configuration file 'moonly.json'")
    logger:error("Please check file permissions or ensure the file exists.")
    return
  end

  -- Keep script running in background
  wait(-1)
end

--- Event handler for when a script terminates
addEventHandler("onScriptTerminate", function(scr)
  if scr == script.this then
    -- If this script is terminating, clean up resources
    logger:info("Shutting down moonly...")
    bootstrap:unload()
    logger:close()
  else
    -- Check if the terminated script belongs to a registered project
    local project = bootstrap:find_project_by_script(scr)
    if project then
      logger:info(string.format(
        "Script '%s' belongs to a project. Unregistering...",
        scr.name
      ))
      bootstrap:emit("unregister", project)
    end
  end
end)

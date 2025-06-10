script_name("moonly")
script_version("1.2.1")
script_version_number(1.21)
script_author("Musaigen")

-- Load required modules
local configurator = require("moonly.configurator")
local bootstrap    = require("moonly.bootstrap")
local logger       = require("moonly.logger")

local is_unloading = false

--- Main entry point of the script
function main()
  -- Log script start
  logger:info("Starting moonly v" .. script.this.version)

  -- Load configuration from file
  local config = configurator:load()

  if config then
    logger:debug("Configuration loaded successfully.")
    bootstrap:initialize(config)
  else
    logger:error("Failed to load configuration file 'moonly.json'")
    logger:error("Please check file permissions or ensure the file exists.")
    return
  end

  -- Keep script running in background
  while true do
    wait(0)

    bootstrap:tick()
  end
end

local function unload()
  if not is_unloading then
    is_unloading = true
    logger:info("Starting shutting down moonly...")
    bootstrap:unload()
    logger:info("Moonly shutdown complete.")
    logger:close()
  end
end

--- Event handler for when a script terminates
addEventHandler("onScriptTerminate", function(scr)
  if scr == script.this then
    unload()
  else
    -- Check if the terminated script belongs to a registered project
    local project = bootstrap:find_project_by_script(scr)
    if project then
      logger:info("Script belongs to a project. Unregistering...")
      bootstrap:emit("unregister", project)
    end
  end
end)

addEventHandler("onQuitGame", function()
  unload()
end)

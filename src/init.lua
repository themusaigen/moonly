script_name("moonly")
script_version("1.4.1")
script_version_number(1.401)
script_author("Musaigen")

-- Load required modules
local configurator = require("moonly.configurator")
local bootstrap    = require("moonly.bootstrap")
local logger       = require("moonly.logger")

local is_unloading = false

-- Log script start
logger:system("Session started.\n")

logger:log("Moonly v%s loaded.", script.this.version)
logger:log("Maintaners: Musaigen (https://github.com/themusaigen)")
logger:log("GitHub: https://github.com/themusaigen/moonly")
logger:log("BlastHack: https://www.blast.hk/threads/220380\n")

-- Load configuration from file
local config = configurator:load()

if config then
  bootstrap:initialize(config)
else
  logger:fatal("Failed to load configuration file 'moonly.json'")
  logger:fatal("Please check file permissions or ensure the file exists.")
  return
end

-- In SA:MP, script's entry point (main) will be automatically called...
-- ...But in singleplayer game, main will not be called until player will...
-- ...press 'Start new game' or 'Load game'
function main()
  while true do
    wait(0)

    bootstrap:tick()
  end
end

local function unload(quit)
  if not is_unloading then
    is_unloading = true
    logger:system("Unloading...")
    bootstrap:unload(quit)
    logger:system("Session terminated.")
    logger:close()
  end
end

--- Event handler for when a script terminates
addEventHandler("onScriptTerminate", function(scr, quit)
  if scr == script.this then
    unload(true)
  else
    -- Check if the terminated script belongs to a registered project
    local project = bootstrap:find_project_by_script(scr)
    if project then
      bootstrap:emit("unregister", project)
    end
  end
end)

addEventHandler("onQuitGame", function()
  unload(false)
end)

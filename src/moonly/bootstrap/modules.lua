local M = {}

local logger = require("moonly.logger")

--- Initializes core and user-defined modules.
function M._initialize_modules(self)
  logger:system("Initializing modules...")

  for _, modname in ipairs(self:configuration_modules()) do
    self:load_module(modname)
  end
end

--- Loads specific module
---@param modname string
function M:load_module(modname)
  logger:system("Loading module '%s'...", modname)

  -- Checking is we trying to load kernel module.
  local success, module = pcall(require, string.concat("moonly.modules.", modname))

  -- Not kernel, just require it.
  if not success then
    success, module = pcall(require, modname)
    if not success then
      local errmsg = string.format("Failed to load '%s' module, error: %s", modname, module)

      -- Got an error!
      logger:error(errmsg)
      error(errmsg)
    end
  end

  -- Call initialize callback if exists.
  if module.initialize then
    module:initialize(self._configuration)
  end

  -- Record this module and log.
  self._modules[#self._modules + 1] = module

  -- Log.
  logger:system("Module '%s': Loaded succesfully.", modname)
end

--- Creates background threads for modules that have a tick function.
function M._initialize_module_threads(self)
  logger:system("Initializing module threads...")

  for _, module in ipairs(self:modules()) do
    if type(module.tick) == "function" then
      lua_thread.create(function()
        while true do
          wait(0)
          module:tick()
        end
      end)
    end
  end
end

--- Emits an event to all registered modules.
---@param fun string # Name of the function to call
---@param ... any # Arguments to pass to the function
function M:emit(fun, ...)
  for _, module in ipairs(self:modules()) do
    if type(module[fun]) == "function" then
      module[fun](module, ...)
    end
  end
end

return M

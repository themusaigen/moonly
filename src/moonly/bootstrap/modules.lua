local M = {}

local logger = require("moonly.logger")

--- Initializes core and user-defined modules.
function M._initialize_modules(self)
  logger:info("Initializing modules...")

  for _, mod in ipairs(self:configuration_modules()) do
    local module_name = mod.core and string.concat("moonly.modules.", mod.name) or mod.name
    local module = require(module_name)

    if module.initialize then
      module:initialize(mod.options or {})
    end

    self._modules[#self._modules + 1] = module
    logger:info("Module '%s' initialized", mod.name)
  end
end

--- Creates background threads for modules that have a tick function.
function M._initialize_module_threads(self)
  logger:info("Initializing module threads...")

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

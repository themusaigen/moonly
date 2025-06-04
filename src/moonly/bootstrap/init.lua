local lifecycle = require("moonly.bootstrap.lifecycle")
local utils = require("moonly.bootstrap.utils")
local projects = require("moonly.bootstrap.projects")
local modules = require("moonly.bootstrap.modules")
local actions = require("moonly.bootstrap.actions")
local tick = require("moonly.bootstrap.tick")

return setmetatable(lifecycle, {
  __index = function(self, key)
    return utils[key]
        or projects[key]
        or modules[key]
        or actions[key]
        or tick[key]
        or rawget(self, key)
  end
})

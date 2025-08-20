local M = {
  name = "clear",
  description = "Clears the console.",
  ---@param console Moonly.Console
  callback = function(console)
    console.messages = {}
  end
}

return M

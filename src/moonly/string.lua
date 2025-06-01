local logger = require("moonly.logger")

--- Concatenates multiple strings into a single string.
--- This is a wrapper around table.concat for convenience.
---@param ... string # One or more strings to concatenate
---@return string result # The concatenated string
---@diagnostic disable-next-line: duplicate-set-field
function string.concat(...)
  local args = { ... }

  -- Optional: validate that all arguments are strings
  for i, v in ipairs(args) do
    if type(v) ~= "string" then
      logger:warn("string.concat -> argument %d is not a string (type: %s)", i, type(v))
      return ""
    end
  end

  return table.concat(args)
end

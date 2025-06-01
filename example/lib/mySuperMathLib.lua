local mathlib = {}

function mathlib.sum(...)
  local result = 0
  for _, value in ipairs({ ... }) do
    result = result + value
  end
  return result
end

return mathlib

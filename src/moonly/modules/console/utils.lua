local imgui = require("upmimgui")
local encoding = require("encoding")
encoding.default = "cp1251"
local u8 = encoding.UTF8

function imgui.TextColoredRGB(text, alpha)
  local style = imgui.GetStyle()
  local colors = style.Colors
  local ImVec4 = imgui.ImVec4
  local explode_argb = function(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, alpha or 0xFF)
    return a, r, g, b
  end
  local getcolor = function(color)
    if color:sub(1, 6):upper() == 'SSSSSS' then
      local r, g, b = colors[1].x, colors[1].y, colors[1].z
      local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
      return ImVec4(r, g, b, a / 255)
    end
    local color = type(color) == 'string' and tonumber(color, 16) or color
    if type(color) ~= 'number' then return end
    local r, g, b, a = explode_argb(color)
    return imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
  end
  local render_text = function(text_)
    for w in text_:gmatch('[^\r\n]+') do
      local text, colors_, m = {}, {}, 1
      w = w:gsub('{(......)}', '{%1FF}')
      while w:find('{........}') do
        local n, k = w:find('{........}')
        local color = getcolor(w:sub(n + 1, k - 1))
        if color then
          text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
          colors_[#colors_ + 1] = color
          m = n
        end
        w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
      end
      if text[0] then
        for i = 0, #text do
          imgui.PushStyleColor(imgui.Col.Text, colors_[i] or colors[1])
          imgui.TextUnformatted(u8(text[i]))
          if imgui.IsItemClicked(0) then
            setClipboardText(w)
          end
          imgui.PopStyleColor()
          imgui.SameLine(nil, 0)
        end
        imgui.NewLine()
      else
        imgui.TextUnformatted(u8(w))
        if imgui.IsItemClicked(0) then
          setClipboardText(w)
        end
      end
    end
  end
  render_text(text)
end

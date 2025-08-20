-- console/gui.lua
-- Description: GUI.
-- Author: Musaigen

local imgui = require("upmimgui")

local function ImGuiEnum(name)
  return setmetatable({ __name = name }, {
    __index = function(t, k)
      return imgui.lib[t.__name .. k]
    end
  })
end

-- Beautify upmimgui function names.
imgui.BeginChildFrame = imgui.BeginChild_Str -- ChildFrame was cut, so use basic child ;p
imgui.MouseButton = ImGuiEnum("ImGuiMouseButton_")

-- local ffi = require("ffi")

---@class Moonly.Console.GuiService
---@field private console Moonly.Console
---@field private state ffi.cdata*
---@field private buffer ffi.cdata*
---@field private bufsize number
---@field private title string
---@field x number
---@field y number
---@field width number
---@field height number
local M = {
  state = imgui.new.bool(false),
  -- buffer = imgui.new.char[256](),
  title = "MOONLY v" .. script.this.version .. " // blast.hk",
  -- bufsize = 0,
  x = 0,
  y = 0,
  width = 600,
  height = 400,
}

---@diagnostic disable-next-line: assign-type-mismatch
-- M.bufsize = ffi.sizeof(M.buffer)

-- ImGui utilities.
require("moonly.modules.console.utils")

-- Predefined constants.
local constants = require("moonly.modules.console.constants")

function M:initialize(console, config)
  local w, h   = getScreenResolution()

  self.console = console
  self.width   = config["moonly.console.window.width"] or self.width
  self.height  = config["moonly.console.window.height"] or self.height
  self.x       = config["moonly.console.window.x"] or (w / 2 - self.width / 2)
  self.y       = config["moonly.console.window.y"] or (h / 2 - self.height / 2)

  -- Subscribe to events.
  imgui.OnInitialize(function()
    self:on_initialize()
  end)

  imgui.OnFrame(function()
    return self:is_drawing()
  end, function()
    self:on_draw()
  end)
end

function M:on_initialize()
  -- Don't save settings of window to Ini. We do it by self.
  local io = imgui.GetIO()
  io.IniFilename = nil
  io.Fonts:Clear()

  -- Add 'Arial' font.
  local fonts_path = getFolderPath(constants.CSIDL_FONTS)
  local arial_path = fonts_path .. "\\arial.ttf"
  io.Fonts:AddFontFromFileTTF(arial_path, 14, nil, io.Fonts:GetGlyphRangesCyrillic())

  -- Apply SAMPFUNCS's console style.
  require("moonly.modules.console.style"):apply_sampfuncs_style(imgui)
end

function M:is_drawing()
  return self.state[0]
end

function M:on_draw()
  imgui.SetNextWindowSize(imgui.ImVec2(self.width, self.height), imgui.Cond.FirstUseEver)
  imgui.SetNextWindowPos(imgui.ImVec2(self.x, self.y), imgui.Cond.FirstUseEver)
  imgui.Begin(self.title, self.state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar)

  -- Update internal position and sizes.
  local position, size = imgui.GetWindowPos(), imgui.GetWindowSize()
  self.x, self.y = position.x, position.y
  self.width, self.height = size.x, size.y

  -- Layout.
  -- local frame_size, input_width, button_size
  -- do
  --   local style = imgui.GetStyle()
  --   local content = imgui.GetContentRegionAvail()

  --   local submit_size = imgui.CalcTextSize("Submit")

  --   button_size = imgui.ImVec2(submit_size.x + style.FramePadding.x * 2, submit_size.y + style.FramePadding.y * 2)
  --   frame_size = imgui.ImVec2(0, 0)
  --   input_width = content.x - button_size.x
  -- end

  -- Frame.
  imgui.BeginChildFrame("##moonly.console.frame", imgui.ImVec2(), imgui.ChildFlags.FrameStyle,
    imgui.WindowFlags.HorizontalScrollbar)

  -- Use clipper to prevent performance issues.
  local clipper = imgui.ImGuiListClipper()
  clipper:Begin(self.console.messages:count(), imgui.GetTextLineHeightWithSpacing())

  while clipper:Step() do
    for idx = clipper.DisplayStart + 1, clipper.DisplayEnd do
      imgui.TextColoredRGB(self.console.messages:at(idx))
    end
  end

  clipper:End()

  imgui.EndChild()

  if imgui.BeginPopupContextWindow("moonly.console.context-window") then
    if imgui.Button("Clear") then
      self.console.messages:clear()

      imgui.CloseCurrentPopup()
    end

    if imgui.Button("Close") then
      imgui.CloseCurrentPopup()
    end

    imgui.EndPopup()
  end

  if imgui.IsMouseClicked(imgui.MouseButton.Right, false) then
    imgui.OpenPopup("moonly.console.context-window")
  end

  -- I am really tired of this shit with scrolling issues in ImGui.
  -- So... It's just log window, yeah.

  -- -- Input box.
  -- imgui.SetNextItemWidth(input_width)
  -- if imgui.InputText("##moonly.console.inputbox", self.buffer, self.bufsize, imgui.InputTextFlags.EnterReturnsTrue) then
  --   self:process_input()
  -- end

  -- -- Button.
  -- imgui.PushStyleVar_Vec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2())
  -- imgui.SameLine()
  -- imgui.PopStyleVar()

  -- if imgui.Button("Submit", button_size) then
  --   self:process_input()
  -- end

  imgui.End()
end

-- function M:process_input()
--   local buffer = ffi.string(self.buffer)
--   if #buffer == 0 then
--     return
--   end

--   -- Add new message.
--   self.console:add_message(buffer)

--   -- Clear buffer.
--   imgui.StrCopy(self.buffer, "")
-- end

function M:show()
  self.state[0] = true
end

function M:hide()
  self.state[0] = false
end

function M:toggle()
  self.state[0] = not self.state[0]
end

return M

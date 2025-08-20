local M = {}

-- MoonLoader/LuaJIT modules.
local ffi = require("ffi")
local imgui = require("upmimgui")

-- Utility module.
require("moonly.modules.console.utility")

--- Initializes UI module.
---@param core Moonly.Console
function M:initialize(core)
  self.core = core
  self.screen = self.core.screen
  self.refocus_input = false

  imgui.OnInitialize(function()
    local io       = imgui.GetIO()
    io.IniFilename = nil
    -- io.Fonts:Clear()

    local style                            = imgui.GetStyle()
    local colors                           = style.Colors

    local background                       = imgui.ImVec4(42 / 255, 42 / 255, 42 / 255, 1)
    local foreground                       = imgui.ImVec4(192 / 255, 192 / 255, 192 / 255, 1)
    local child                            = imgui.ImVec4(53 / 255, 53 / 255, 53 / 255, 1)
    local button                           = imgui.ImVec4(67 / 255, 78 / 255, 97 / 255, 1)
    local button_hovered                   = imgui.ImVec4(84 / 255, 99 / 255, 122 / 255, 1)
    local button_active                    = imgui.ImVec4(58 / 255, 68 / 255, 84 / 255, 1)
    local resize                           = imgui.ImVec4(0, 0, 0, 0)
    local scrollbar                        = imgui.ImVec4(67 / 255, 67 / 255, 67 / 255, 1)
    local scrollbar_hovered                = imgui.ImVec4(88 / 255, 88 / 255, 88 / 255, 1)
    local scrollbar_active                 = imgui.ImVec4(73 / 255, 73 / 255, 73 / 255, 1)
    local header                           = imgui.ImVec4(46 / 255, 46 / 255, 48 / 255, 1)
    local header_hovered                   = imgui.ImVec4(67 / 255, 67 / 255, 69 / 255, 1)
    local header_active                    = imgui.ImVec4(56 / 255, 56 / 255, 58 / 255, 1)

    style.WindowRounding                   = 0
    style.FrameRounding                    = 0
    style.ChildRounding                    = 0
    style.PopupRounding                    = 0
    style.ScrollbarRounding                = 0
    style.GrabRounding                     = 0
    style.WindowBorderSize                 = 0
    style.FrameBorderSize                  = 0
    style.PopupBorderSize                  = 0
    style.ScrollbarSize                    = 10

    style.WindowPadding                    = imgui.ImVec2(6, 4)
    style.WindowTitleAlign                 = imgui.ImVec2(0.01, 1)
    style.FramePadding                     = imgui.ImVec2(5, 3.5)
    style.WindowMinSize                    = imgui.ImVec2(207.2, 159)

    colors[imgui.Col.Text]                 = foreground
    colors[imgui.Col.TitleBg]              = background
    colors[imgui.Col.TitleBgActive]        = background
    colors[imgui.Col.WindowBg]             = background
    colors[imgui.Col.ScrollbarBg]          = background
    colors[imgui.Col.ChildBg]              = child
    colors[imgui.Col.FrameBg]              = child
    colors[imgui.Col.FrameBgActive]        = child
    colors[imgui.Col.FrameBgHovered]       = child
    colors[imgui.Col.Button]               = button
    colors[imgui.Col.ButtonActive]         = button_active
    colors[imgui.Col.ButtonHovered]        = button_hovered
    colors[imgui.Col.ResizeGrip]           = resize
    colors[imgui.Col.ResizeGripActive]     = resize
    colors[imgui.Col.ResizeGripHovered]    = resize
    colors[imgui.Col.ScrollbarGrab]        = scrollbar
    colors[imgui.Col.ScrollbarGrabHovered] = scrollbar_hovered
    colors[imgui.Col.ScrollbarGrabActive]  = scrollbar_active
    colors[imgui.Col.Header]               = header
    colors[imgui.Col.HeaderHovered]        = header_hovered
    colors[imgui.Col.HeaderActive]         = header_active

    --
    -- local builder                          = imgui.ImFontGlyphRangesBuilder()
    -- builder:AddRanges(io.Fonts:GetGlyphRangesCyrillic())
    -- builder:AddText([[‚„…†‡ˆ‰‹‘’“”•–—™›¹]])
    -- local defaultGlyphRanges = imgui.ImVector_ImWchar()
    -- builder:BuildRanges(defaultGlyphRanges)
    -- io.Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arial.ttf', 14, nil, defaultGlyphRanges[0].Data)
  end)

  imgui.OnFrame(function()
    return self:condition()
  end, function()
    self:render()
  end)
end

function M:condition()
  return self.core.window[0]
end

function M:render()
  imgui.SetNextWindowSize(imgui.ImVec2(600, 400), imgui.Cond.FirstUseEver)
  imgui.SetNextWindowPos(imgui.ImVec2(self.screen.width / 2, self.screen.height / 2), imgui.Cond.FirstUseEver,
    imgui.ImVec2(0.5, 0.5))

  imgui.Begin("MOONLY v" .. script.this.version .. " // blast.hk", self.core.window,
    imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar)

  local bottom_pane_size = self:get_button_frame_size()

  local style = imgui.GetStyle()
  local avail = imgui.GetContentRegionAvail()

  -- Draw messages.
  do
    local frame_flags = imgui.WindowFlags.HorizontalScrollbar
    local frame_size = imgui.ImVec2(0, avail.y - bottom_pane_size.y - style.WindowPadding.y * 2)

    imgui.BeginChildFrame(1, frame_size, frame_flags)

    local clipper = imgui.ImGuiListClipper(#self.core.messages)
    while clipper:Step() do
      for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
        imgui.TextColoredRGB(self.core.messages[i])
      end



      -- local scroll_y = imgui.GetScrollY()
      -- local scroll_max_y = imgui.GetScrollMaxY()
      -- if scroll_y ~= scroll_max_y then
      --   if self.core.scroll then
      --     imgui.SetScrollY(imgui.GetScrollMaxY())
      --   end
      -- else
      --   self.core.scroll = false
      -- end
    end

    if self.core.scroll then
      imgui.SetScrollHereY(1)

      self.core.scroll = false
    end

    imgui.EndChildFrame()
  end

  -- Draw input.
  do
    local input_width = avail.x - bottom_pane_size.x
    local input_flags =
        imgui.InputTextFlags.EnterReturnsTrue

    imgui.PushItemWidth(input_width)
    if imgui.InputText("##moonly.console.input", self.core.input, ffi.sizeof(self.core.input), input_flags) then
      self:process_input()
    end
    imgui.PopItemWidth()

    if self.refocus_input then
      imgui.SetKeyboardFocusHere()

      self.refocus_input = false
    end

    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(0, 0))
    imgui.SameLine()
    imgui.PopStyleVar()

    if imgui.Button("Submit", bottom_pane_size) then
      self:process_input()
    end
  end

  -- Render tips.
  do
    local input = ffi.string(self.core.input)
    if #input == 0 then
      goto next_frame
    end

    local commands = self.core:pick_commands(input)
    local commands_length = #commands
    if commands_length == 0 then
      goto next_frame
    end

    local position = imgui.GetWindowPos()
    local size = imgui.GetWindowSize()

    imgui.SetNextWindowPos(position + imgui.ImVec2(0, size.y + 5))
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowMinSize, imgui.ImVec2())
    imgui.Begin("##moonly.console.tips", nil,
      imgui.WindowFlags.NoTitleBar
      + imgui.WindowFlags.NoCollapse
      + imgui.WindowFlags.NoResize
      + imgui.WindowFlags.AlwaysAutoResize)

    local clipper = imgui.ImGuiListClipper(commands_length)
    while clipper:Step() do
      for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
        local command = commands[i]
        if imgui.Selectable(command.name, false) then
          imgui.StrCopy(self.core.input, command.name)

          -- Refocus input on the next frame.
          self.refocus_input = true
        end

        imgui.SameLine()
        imgui.TextDisabled(command.description)
      end
    end

    imgui.End()
    imgui.PopStyleVar()
  end

  ::next_frame::
  imgui.End()
end

function M:process_input()
  local input = ffi.string(self.core.input)
  if #input == 0 then
    return
  end

  self.core:add_message(input)

  local user_command = input:match("(%S+)")
  local user_command_executed = false
  for _, command in ipairs(self.core.commands) do
    if command.name == user_command then
      command.callback(self.core)

      user_command_executed = true
    end
  end

  if not user_command_executed then
    self.core.messages[#self.core.messages + 1] = "Unknown command '" .. user_command .. "'"
  end

  -- Scroll down.
  self.core.scroll = true

  -- Clear the string.
  imgui.StrCopy(self.core.input, "")
end

function M:get_button_frame_size()
  local style      = imgui.GetStyle()
  local label_size = imgui.CalcTextSize("Submit", nil, true)
  return imgui.ImVec2(label_size.x + style.FramePadding.x * 2, label_size.y + style.FramePadding.y * 2)
end

return M

local M = {}

function M:apply_sampfuncs_style(imgui)
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
end

return M

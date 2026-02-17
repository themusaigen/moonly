local M = {}

local ffi = require("ffi")
local memory = require("memory")

local constants = {
  WM_SETFOCUS  = 0x0007,
  WM_KILLFOCUS = 0x0008
}

function M:initialize(configuration)
  self.antipause   = configuration["moonly.qol.antipause"] or false
  self.window_mode = configuration["moonly.qol.window-mode"] or false

  -- Enable antipause.
  if self.antipause then
    memory.fill(0x748A8D, 0x90, 6, true) -- cmp -> nop

    addEventHandler("onWindowMessage", function(...)
      self:on_window_message(...)
    end)
  end

  -- Set window mode.
  if self.window_mode then
    local initialized = false
    local window = ffi.cast("uint32_t*", 0xC97C1C)
    local nullptr = ffi.cast("void*", 0x00000000)

    addEventHandler("onD3DPresent", function()
      if initialized then
        return
      end

      if window == nullptr or window[0] == nullptr then
        return
      end

      local videomode_index = memory.getuint32(0xC97C18, true)

      -- Disable fullscreen in current video modes.
      local videomode = memory.getuint32(0xC97C48 + videomode_index * 0x14, true)
      memory.setuint32(videomode + 0x10, 0, true)

      -- Update video mode.
      local setVideoMode = ffi.cast("void(__cdecl*)(int, int)", 0x745C70)
      setVideoMode(false, videomode_index)


      initialized = true
    end)
  end
end

function M:on_window_message(message)
  if message == constants.WM_KILLFOCUS then
    memory.fill(0x74542B, 0x90, 8, true)                                              -- Patches 'psSetMousePos'.
  elseif message == constants.WM_SETFOCUS then
    memory.copy(0x74542B, memory.strptr("\x50\x51\xFF\x15\x00\x83\x85\x00"), 8, true) -- Unpatch.
  end
end

function M:unload()
  if self.antipause then
    memory.copy(0x748A8D, memory.strptr("\x0F\x84\x20\x03\x00\x00"), 6, true)
    memory.copy(0x74542B, memory.strptr("\x50\x51\xFF\x15\x00\x83\x85\x00"), 8, true)
  end
end

return M

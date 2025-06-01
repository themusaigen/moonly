-- autoreboot.lua
-- Purpose: Auto-reloads projects when their source or library files are modified.
-- Author: Musaigen

local ffi = require("ffi")

-- Define Windows API types and functions for file time tracking
ffi.cdef([[
    typedef void* HANDLE;
    typedef void* LPSECURITY_ATTRIBUTES;
    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef const char *LPCSTR;

    typedef struct _FILETIME {
        DWORD dwLowDateTime;
        DWORD dwHighDateTime;
    } FILETIME, *PFILETIME, *LPFILETIME;

    BOOL __stdcall GetFileTime(HANDLE hFile, LPFILETIME lpCreationTime, LPFILETIME lpLastAccessTime, LPFILETIME lpLastWriteTime);
    HANDLE __stdcall CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
    BOOL __stdcall CloseHandle(HANDLE hObject);
]])

--- Gets the last modification time of a file using Windows API.
---@param path string # Full path to the file
---@return table|nil # { low, high } timestamps or nil on error
local function get_file_modify_time(path)
  local handle = ffi.C.CreateFileA(
    path,
    0x80000000,              -- GENERIC_READ
    0x00000001 + 0x00000002, -- FILE_SHARE_READ | FILE_SHARE_WRITE
    nil,
    3,                       -- OPEN_EXISTING
    0x00000080,              -- FILE_ATTRIBUTE_NORMAL
    nil
  )

  if handle == -1 then
    return nil
  end

  local filetime = ffi.new('FILETIME[3]')
  local result = ffi.C.GetFileTime(handle, filetime, filetime + 1, filetime + 2)
  ffi.C.CloseHandle(handle)

  if result ~= 0 then
    return {
      low = tonumber(filetime[2].dwLowDateTime),
      high = tonumber(filetime[2].dwHighDateTime)
    }
  end

  return nil
end

--- Autoreboot module definition
local autoreboot = {
  projects = {}, -- Maps project -> list of tracked files with modification times
  delay = 1000,  -- Default tick interval in milliseconds
}

local bootstrap  = require("moonly.bootstrap")
local logger     = require("moonly.logger")
local path       = require("moonly.path")

--- Initializes the autoreboot module with options.
---@param options table # Options like `delay`
function autoreboot:initialize(options)
  self.delay = options and options.delay or self.delay
end

--- Scans a directory for .lua files and tracks their modification times.
---@param project table # Project object
---@param dir string # Directory to scan
function autoreboot:update_info_about_directory_files(project, dir)
  path.traverse(dir, function(base_path, entry, isdirectory)
    if isdirectory then
      return
    end

    local full_path = path.concat(base_path, entry)

    -- Skip if already tracked
    for _, file in ipairs(self.projects[project]) do
      if file.path == full_path then
        return
      end
    end

    -- Add new file info
    local modify_time = get_file_modify_time(full_path)
    if modify_time then
      table.insert(self.projects[project], {
        path = full_path,
        modify_time = modify_time
      })
    end
  end, true)
end

--- Registers a project with this autoreboot module.
---@param project table # Project object
function autoreboot:register(project)
  self.projects[project] = {}

  self:update_info_about_directory_files(project, project:source_directory())
  self:update_info_about_directory_files(project, project:libraries_directory())
end

--- Unregisters a project from being tracked.
---@param project table # Project object
function autoreboot:unregister(project)
  self.projects[project] = nil
end

--- Main tick function that checks for file changes and reboots project if needed.
function autoreboot:tick()
  wait(self.delay)

  for project, files in pairs(self.projects) do
    local needs_reload = false

    for _, file in ipairs(files) do
      local current_time = get_file_modify_time(file.path)
      if current_time then
        if current_time.low ~= file.modify_time.low or current_time.high ~= file.modify_time.high then
          needs_reload = true
          file.modify_time = current_time
        end
      else
        logger:warn("Failed to read modification time for file: %s", file.path)
      end
    end

    if needs_reload then
      logger:info("Detected changes in project '%s'. Rebooting...", project:name())

      bootstrap:reboot_project(project)

      -- Scan for new files.
      self:update_info_about_directory_files(project, project:source_directory())
      self:update_info_about_directory_files(project, project:libraries_directory())
    end
  end
end

return autoreboot

local lfs = require("lfs")
local ffi = require("ffi")
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

-- Moonly version
local _VERSION = 0.13

-- Config
local autoreload_delay = 1000

local function output(text, ...)
  print(text:format(...))
end

local function create_moonly_directory()
  local moonly_dir = getGameDirectory() .. "\\moonly"
  if not doesDirectoryExist(moonly_dir) then
    createDirectory(moonly_dir)
  end
end

local function get_moonly_temp_directory()
  local moonly_temp_dir = os.getenv("TEMP") .. "\\moonly"
  if not doesDirectoryExist(moonly_temp_dir) then
    createDirectory(moonly_temp_dir)
  end
  return moonly_temp_dir
end

-- AutoReboot by FYP.
local function get_file_modify_time(path)
  local handle = ffi.C.CreateFileA(path,
    0x80000000,              -- GENERIC_READ
    0x00000001 + 0x00000002, -- FILE_SHARE_READ | FILE_SHARE_WRITE
    nil,
    3,                       -- OPEN_EXISTING
    0x00000080,              -- FILE_ATTRIBUTE_NORMAL
    nil)
  local filetime = ffi.new('FILETIME[3]')
  if handle ~= -1 then
    local result = ffi.C.GetFileTime(handle, filetime, filetime + 1, filetime + 2)
    ffi.C.CloseHandle(handle)
    if result ~= 0 then
      return { tonumber(filetime[2].dwLowDateTime), tonumber(filetime[2].dwHighDateTime) }
    end
  end
  return nil
end

local function generate_temporary_script_source(project)
  local root = project.root:gsub("\\", "\\\\")
  local path = project.path:gsub("\\", "\\\\")

  local script =
  [[
local file = io.open("<path>", "r")
if not file then
  print("failed to open file <path>")
  return
end

local source_code = file:read("*a")
local script = loadstring(source_code)
if not script then
  print("failed to load source code of <path>")
  return
end

-- Prepare paths to rebuild
local paths = {
  "<root>\\<src>\\?.lua;",
  "<root>\\<src>\\?\\init.lua;",
  "<root>\\<src>\\?.luac;",
  "<root>\\<src>\\?\\init.luac;",
  "<root>\\<lib>\\?.lua;",
  "<root>\\<lib>\\?\\init.lua;",
  "<root>\\<lib>\\?.luac;",
  "<root>\\<lib>\\?\\init.luac;"
}

-- Get the environment of this script.
local env = getfenv(script)

-- Get the `package` lib of script.
local package = env.package

-- Spoof it.
for _, value in ipairs(paths) do
  package.path = value .. package.path
end

-- Spoof package.cpath
package.cpath = "<root>\\<lib>\\?.dll;" .. package.cpath

-- Spoof getWorkingDirectory
local getWorkingDirectory_ = env.getWorkingDirectory
env.getWorkingDirectory = function()
  return "<root>\\<src>"
end

env.getMoonloaderDirectory = function()
  return getWorkingDirectory_()
end

env.MOONLY_ENVIRONMENT = true
env.MOONLY_VERSION = <version>

env.getMoonlyVersion = function()
  return <version>
end

-- Set new environment. (Maybe useless, cuz env is table, but why not)
setfenv(script, env)

-- Load the script
script()
]]
  script = script:gsub("<path>", path):gsub("<root>", root):gsub("<src>", project.source):gsub("<lib>", project.library)
      :gsub("<version>", _VERSION)
  return script
end

local function generate_temporary_script(project)
  -- Format temporary file path.
  local path = ("%s\\moonly_%s.lua"):format(get_moonly_temp_directory(), project.name)

  -- Create file in that directory.
  local temp = io.open(path, "w+")
  if not temp then
    return false, "can't create file " .. path
  end

  -- Write temporary script source code.
  temp:write(generate_temporary_script_source(project))

  -- Close it.
  temp:close()

  -- Return our temporary script`s path to load.
  return path
end

local function load_project(project)
  local scr, err = generate_temporary_script(project)
  if scr then
    project.script = script.load(scr)
  else
    output("error on creating script stage: %s", err)
  end
end

local function load_projects(projects)
  for _, project in ipairs(projects) do
    load_project(project)
  end
end

local function lookup_for_project(dir)
  local path = dir .. "/" .. "project.json"
  if not doesFileExist(path) then
    return false, "don't exist"
  end

  local file = io.open(path, "r")
  if not file then
    return false, "io.open failed"
  end

  local json = decodeJson(file:read("*a"))
  file:close()
  return json
end

local function scan_dir(dir)
  local projects = {}

  local function process_lfs(dir, iterator, recursive)
    for file in lfs.dir(dir) do
      if (file ~= ".") and (file ~= "..") then
        iterator(dir, file)

        local path = ("%s\\%s"):format(dir, file)
        local attributes = lfs.attributes(path)
        if attributes and recursive and attributes.mode == "directory" then
          process_lfs(path, iterator, true)
        end
      end
    end
  end

  process_lfs(dir, function(_, file)
    local project_path = ("%s\\%s"):format(dir, file)

    -- Check for attributes.
    local attributes = lfs.attributes(project_path)
    if attributes and attributes.mode == "directory" then
      local project, err = lookup_for_project(project_path)
      if project then
        -- Index name of the project
        project.name = project.name or file

        -- Index the project path to use later.
        project.files = {}
        project.source = project.source or "src"
        project.library = project.library or "lib"
        project.root = project_path:gsub("%.", getGameDirectory())
        project.source_path = ("%s\\%s"):format(project.root, project.source)
        project.path = ("%s\\init.lua"):format(project.source_path)

        process_lfs(project.source_path, function(dir, file)
          if file:match(".lua$") then
            local file_path = ("%s\\%s"):format(dir, file)
            project.files[#project.files + 1] = { path = file_path, modify_time = get_file_modify_time(file_path) }
          end
        end, true)

        -- Add new project.
        projects[#projects + 1] = project
      else
        output("bad project %s, got error %s", file, err)
      end
    end
  end)
  return projects
end

local projects
function main()
  -- Create directory if don't exist
  create_moonly_directory()

  -- Scan for all projects.
  projects = scan_dir(".\\moonly")

  -- Load projects.
  load_projects(projects)

  -- AutoReboot impl.
  while true do
    wait(autoreload_delay)

    for _, project in ipairs(projects) do
      -- Script present.
      for _, file in ipairs(project.files) do
        local modify_time = get_file_modify_time(file.path)
        if modify_time then
          if (modify_time[1] ~= file.modify_time[1]) or (modify_time[2] ~= file.modify_time[2]) then
            if project.script then
              -- `reload` method is doing nothing?
              project.script:unload()
            end

            load_project(project)

            file.modify_time = modify_time
            break
          end
        end
      end
    end
  end
end

function onScriptTerminate(s)
  if s == script.this then
    for _, project in ipairs(projects) do
      if project.script then
        project.script:unload()
      end
    end
  end
end

on initLists
  global movieFiles, castFiles, memberTypes, memberCategories, exportFormats, exportOptions
  set movieFiles = list()
  set castFiles = list()
  set memberTypes = propList()
  set memberCategories = propList()
  set exportFormats = propList()
  set exportOptions = propList()
end

-- Within a tell statement, functions in other scripts can't be accessed normally
-- The only way is to reference the main movie directly
-- To make this more mnemonic, create variables that look like class names but point to the main movie
on initClasses
  global Progress, Logging, Files, Utils
  set thisMovie = the movie of the window
  set Progress = thisMovie
  set Logging = thisMovie
  set Files = thisMovie
  set Utils = thisMovie
end

on setDefaultOptions
  global memberTypes, exportFormats
  if the count of memberTypes = 0 then enableAllCategories()
  if the count of exportFormats = 0 then set exportFormats = defaultFormats()
end

on prepareMovie
  global pathSep, fileioObj, fxObj
  clearGlobals()
  -- set the debugPlaybackEnabled = 1
  set the idleLoadMode = 0
  set the title of the window = line 1 of the movieAboutInfo
  set pathSep = "\"
  set fileioObj = new xtra("fileio")
  set fxObj = new xtra("FileXtra4")
  -- This registration code was freely shared by the original developer
  -- See http://mods.com.au
  baRegister("Buddy API", 4031287)
  -- Director's default browser detection is broken
  -- Open URLs in the system default browser, not IE
  browserName(getOSDirectory() & pathSep & "explorer.exe")
  initLists()
  initClasses()
  initConsole()
  setToolPaths()
  processCommandLineArgs(getCommandLineArgs())
  setDefaultOptions()
end

on startMovie
  global consoleMode
  if consoleMode then go to "Command Line Export"
  else initUI()
end

on stopMovie
  closeAutoclicker()
  unlink()
  showButtons()
end

on setMemberTypes types
  global memberTypes
  if the count of types = 0 then
    errorMsg("Please specify at least one member type to export")
  else if the count of types = 1 and types.getAt(1) = "all" then
    enableAllCategories()
  else
    set msg = "Unknown member type:"
    set allTypes = the value of field "MemberTypes"
    set allCategories = getAllProps(the value of field "MemberCategories")
    repeat with t in types
      if t starts "#" then
        set memberType = value(t)
        if allTypes.getPos(memberType) > 0 then
          memberTypes.setaProp(memberType, True)
        else
          errorMsg(msg && t)
        end if
      else
        if t = "3d" then set t = "shockwave3d"
        set memberCategory = symbol(t)
        if allCategories.getPos(memberCategory) > 0 then
          updateCategory(memberCategory, True)
        else
          errorMsg(msg && t)
        end if
      end if
    end repeat
  end if
end

on setExportFormats formats
  global exportFormats
  set allFormats = the value of field "ExportFormats"
  repeat with fmt in formats
    set fmt = symbol(fmt)
    if allFormats.getPos(fmt) > 0 then
      exportFormats.setaProp(fmt, True)
    else
      errorMsg("Unknown export format:" && fmt)
    end if
  end repeat
end

on parseCommandLineArgs argsList
  set parsedArgs = propList()
  set argName = EMPTY
  set argVals = list()
  repeat with arg in argsList
    if char 1 to 2 of arg = "--" then
      set argName = arg
      delete char 1 to 2 of argName
      set argVals = parsedArgs.getaProp(argName)
      if argVals = VOID then 
        set argVals = list()
      end if
    else if char 1 of arg = "-" and the number of chars in arg = 2 then
      parsedArgs.setaProp(char 2 of arg, list())
    else
      argVals.append(arg)
    end if
    parsedArgs.setaProp(argName, argVals)
  end repeat
  return parsedArgs
end

on setFlagOpt optName, optVal
  global exportOptions
  if the count of optVal > 0 then
    errorMsg("Unknown arguments after" && optName & ":" && optVal)
  else
    exportOptions.setaProp(optName, True)
  end if
end

on processCommandLineArgs args
  global fxObj, consoleMode, movieFiles, castFiles, exportFolder
  set options = parseCommandLineArgs(args)
  if the count of options = 0 or the runMode = "Author" then return
  
  repeat with i = 1 to the count of options
    set optName = options.getPropAt(i)
    set optVal = options.getAt(i)
    case optName of
      "help", "h": printInfo(True)
      "version", "v": printInfo(False)
      "debug": set the debugPlaybackEnabled = True
      -- File paths can be passed without an option name
      "files", EMPTY: processSelection(optVal)
      "folders": set inputFolders = optVal
      "movies": set movies = optVal
      "casts": set casts = optVal
      "output-folder": set exportFolderOpt = optVal
      "member-types": setMemberTypes(optVal)
      "formats": setExportFormats(optVal)
      "include-names": setFlagOpt(#exportWithNames, optVal)
      "decompile": setFlagOpt(#decompile, optVal)
      "dismiss-dialogs": setFlagOpt(#dismissDialogs, optVal)
      "text-to-images": setFlagOpt(#textToImages, optVal)
      otherwise: errorMsg("Unknown option:" && optName)
    end case
  end repeat
  
  if listP(inputFolders) then
    repeat with folderPath in inputFolders
      if fxObj.fx_FolderExists(folderPath) then
        processSelection(getDirFilesInFolder(folderPath))
      else
        errorMsg("The specified input folder does not exist:" && folderPath)
      end if
    end repeat
  end if
  
  if listP(movies) then
    checkFilesExist(movies)
    appendItems(movieFiles, movies)
  end if
  
  if listP(casts) then
    checkFilesExist(casts)
    appendItems(castFiles, casts)
  end if
  
  if consoleMode then -- User won't be able to set these options via the UI; fail immediately
    if the count of movieFiles = 0 and the count of castFiles = 0 then
      errorMsg("Please specify at least one Director movie or cast file to export from")
    end if
    if voidP(exportFolder) and voidP(exportFolderOpt) then
      if not setDefaultExportFolder() then errorMsg("Please specify an output folder path to export to")
    end if
  end if
  
  if listP(exportFolderOpt) then 
    if the count of exportFolderOpt = 1 then
      if not setExportFolder(exportFolderOpt.getAt(1)) then
        errorMsg("The specified output folder does not exist or is not writable")
        set exportFolder = EMPTY
      end if
    else
      errorMsg("Please specify exactly one folder path to export to. If the path contains spaces, wrap it in quotes.")
    end if
  end if
end

on printInfo includeHelp
  infoMsg(the movieAboutInfo)
  if includeHelp then
    infoMsg("Usage:" && the applicationName && "[files...] [options...]")
    repeat with i = 1 to the number of lines of field "CmdLineHelp"
      infoMsg(SPACE & line i of field "CmdLineHelp")
    end repeat
  end if
  quit() -- halt() seems to sometimes not work from a prepareMovie handler
end

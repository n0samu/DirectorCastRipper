global pathSep, fxObj, fileioObj

on fileioError err, reason, path
  return err & "." && "Reason:" && reason & "," && "Path:" && path
end

on getFileioResult possibleError, path, append
  set existsMsg = "File already exists"
  set code = fileioObj.status()
  set msg = fileioObj.error(code)
  if append and msg = existsMsg then
    set code = 0
    set msg = fileioObj.error(code)
  end if
  if code <> 0 then set msg = fileioError(possibleError, msg, path)
  return [#code: code, #message: msg]
end

on writeTextFile fileContents, filePath, append
  fileioObj.createFile(filePath)
  set result = getFileioResult("Failed to create file", filePath, append)
  if result.code <> 0 then return result
  if fileContents = EMPTY then return result
  fileioObj.openFile(filePath, 0)
  set result = getFileioResult("Failed to open file", filePath, append)
  if result.code <> 0 then return result
  if append then fileioObj.setPosition(fileioObj.getLength())
  fileioObj.writeString(fileContents)
  set result = getFileioResult("Failed to write to file", filePath, append)
  fileioObj.closeFile()
  return result
end

on saveString fileContents, filePath
  set result = writeTextFile(fileContents, filePath, False)
  if result.code <> 0 then warnMsg(result.message)
  return result.code
end

on writeLog fileContents, filePath
  -- We can't write any errors to the log, because we're already writing to the log
  -- That would cause infinite recursion. Not good!
  return writeTextFile(fileContents, filePath, True)
end

on deleteEmptyFile filePath
  fileioObj.openFile(filePath, 0)
  if fileioObj.status() <> 0 then return
  if fileioObj.getLength() = 0 then fileioObj.delete()
  else fileioObj.closeFile()
  return
end

-- Need to open a file with fileioObj and seek to the correct position before calling
on readChars numChars
  set str = EMPTY
  repeat with i = 1 to numChars
    put fileioObj.readChar() after str
  end repeat
  return str
end

on isValidDirFile filePath
  set isValid = False
  
  set READONLY = 1
  fileioObj.openFile(filePath, READONLY)
  if fileioObj.status() = 0 then
    if fileioObj.getLength() > 12 then
      set fourCC = readChars(4)
      fileioObj.setPosition(8)
      set fType = readChars(4)
      
      case fType of
        -- Handle big endian and little endian files
        "MV93", "FGDM", "MC95", "FGDC":
          set isValid = (fourCC = "RIFX")
        "39VM", "MDGF", "59CM", "CDGF":
          set isValid = (fourCC = "XFIR")
      end case
    end if
    
    fileioObj.closeFile()
  end if
  
  return isValid
end

on fileMultiSelect
  -- FLAGS
  OFN_READONLY                 = 1
  OFN_OVERWRITEPROMPT          = 2
  OFN_HIDEREADONLY             = 4
  OFN_NOCHANGEDIR              = 8
  OFN_ADDEXTENSION             = 32
  OFN_RETURNASLIST             = 256
  OFN_ALLOWMULTISELECT         = 512
  OFN_PATHMUSTEXIST            = 2048
  OFN_FILEMUSTEXIST            = 4096
  OFN_CREATEPROMPT             = 8192
  OFN_NOREADONLYRETURN         = 32768
  OFN_NONETWORKBUTTON          = 131072
  OFN_NOLONGNAMES              = 262144
  OFN_EXPLORER                 = 524288
  OFN_NODEREFERENCELINKS       = 1048576
  OFN_LONGNAMES                = 2097152
  OFN_SHOWPLACESBAR            = 4194304
  OFN_ENABLESIZING             = 8388608
  
  set flags = OFN_HIDEREADONLY + OFN_RETURNASLIST + OFN_ALLOWMULTISELECT + \
              OFN_FILEMUSTEXIST + OFN_EXPLORER + OFN_ENABLESIZING
  set filter = "Director Movie or Cast|*.dir;*.dxr;*.dcr;*.cst;*.cxt;*.cct"
  set msg = "Select Director files"
  -- baGetFilename( Operation, StartDir, Filename, Filter, Flags, Instruction, NoFolders, X, Y )
  return baGetFilename("open", "", "", filter, flags, msg, False, -1, -1) -- BuddyAPI function
end

on folderSelect
  set caption = "Choose a folder location to save the exported files."
  -- baGetFolder( StartDir, Instruction, Flags, Caption, X, Y )
  return baGetFolder("", caption, 3, "Choose Output Folder", -1, -1)
end

on splitExt str, delim
  set the itemDelimiter = delim
  set ret = [str, VOID]
  if the number of items in str > 1 then
    set ext = the last item of str
    set rest = item 1 to (the number of items in str - 1) of str
    set ret = [rest, ext]
  end if
  return ret
end

on getFileExt filePath
  return splitExt(filePath, ".").getAt(2)
end

on getFilename filePath
  if filePath contains pathSep then return splitExt(filePath, pathSep).getAt(2)
  else return filePath
end

-- Get filename excluding extension
on getFileBaseName filePath
  return splitExt(getFilename(filePath), ".").getAt(1)
end

on getFolderPath filePath
  return splitExt(filePath, pathSep).getAt(1)
end

on sanitizeFilename fName
  set invalidChars = ["<", ">", ":", QUOTE, "/", "\", "|", "?", "*"]
  repeat with i = 1 to the number of chars in fName
    if invalidChars.getPos(char i of fName) > 0 then put "-" into char i of fName
  end repeat
  return fName
end

-- Filter a list of files by the specified extensions
on filterFiles fileList, exts
  set ret = list()
  repeat with filePath in fileList
    if listContains(exts, getFileExt(filePath)) then ret.append(filePath)
  end repeat
  return ret
end

on getDirFiles files
  set dirExts = ["dir", "dxr", "dcr", "cst", "cxt", "cct"]
  return filterFiles(files, dirExts)
end

on getDirFilesInFolder folderPath
  set folderPath = ensureTrailingSlash(folderPath)
  set dirFiles = getDirFiles(fxObj.fx_folderToList(folderPath))
  set dirFilePaths = list()
  repeat with fName in dirFiles
    dirFilePaths.append(folderPath & fName)
  end repeat
  return dirFilePaths
end

on ensureTrailingSlash folderPath
  if the last char of folderPath = pathSep then return folderPath
  return folderPath & pathSep
end

on quotePath p
  return QUOTE & p & QUOTE
end

on checkFilesExist filePaths
  repeat with filePath in filePaths
    if not fxObj.fx_FileExists(filePath) then
      errorMsg("The specified file does not exist:" && filePath)
    end if
  end repeat
end

-- Note: getNthFileNameInFolder treats EMPTY as the drive root and "\" as the current directory
on folderIsEmpty folderPath  
  return getNthFileNameInFolder(folderPath, 1) = EMPTY
end

-- Create a subfolder with the requested name, or an "incremented" name if it exists & already has files
on createSubfolder containingFolder, requestedName
  set folderPath = containingFolder & requestedName & pathSep
  set folderName = requestedName & "_1"
  repeat while fxObj.fx_FolderExists(folderPath) and not folderIsEmpty(folderPath)
    set folderName = incrementString(folderName)
    set folderPath = containingFolder & folderName & pathSep
  end repeat
  if fxObj.fx_FolderCreate(folderPath) then return folderPath
end

on getUniqueFile containingFolder, requestedName, ext
  if not (ext starts ".") then put "." before ext
  set filePath = containingFolder & requestedName & ext
  set fileBaseName = requestedName & "_1"
  repeat while fxObj.fx_FileExists(filePath)
    set fileBaseName = incrementString(fileBaseName)
    set filePath = containingFolder & fileBaseName & ext
  end repeat
  return filePath
end

on setDefaultExportFolder
  global exportFolder
  if voidP(exportFolder) or exportFolder = EMPTY then
    set exportFolder = string(createSubfolder(the moviePath, "Exports"))
  end if
  return exportFolder <> EMPTY
end

on setExportFolder folderPath
  global exportFolder
  set exportFolder = ensureTrailingSlash(folderPath)
  return fxObj.fx_FolderGetWriteState(exportFolder)
end

on processSelection filePaths
  global movieFiles, castFiles
  set movieExts = ["dir", "dxr", "dcr"]
  set castExts  = ["cst", "cxt", "cct"]
  
  appendItems(movieFiles, filterFiles(filePaths, movieExts))
  appendItems(castFiles, filterFiles(filePaths, castExts))
end

on setSelectedFiles filePaths
  global movieFiles, castFiles
  set movieFiles = list()
  set castFiles = list()
  processSelection(filePaths)
end

on setToolPaths
  global toolPaths
  set toolPaths = propList()
  set xtrasFolder = the moviePath & "Xtras" & pathSep
  set toolsFolder = the moviePath & "Tools" & pathSep
  
  set autoClicker = xtrasFolder & "AutoDismisser.exe"
  if fxObj.fx_FileExists(autoClicker) then toolPaths.setaProp(#autoClicker, autoClicker)
  
  repeat with fName in fxObj.fx_FolderToList(toolsFolder)
    if fName starts "projectorrays" and getFileExt(fName) = "exe" then
      toolPaths.setaProp(#projectorRays, toolsFolder & fName)
      exit repeat
    end if
  end repeat
end

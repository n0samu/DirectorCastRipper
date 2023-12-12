global Progress, Logging, Files, Utils

on defaultFormats
  return [#png: True, #html: True]
end

on getErr current, new
  if new <> 0 then return new
  else return current
end

on exportText textMember, basePath, formats, asImage
  set result = 0
  if formats.getaProp(#html) then set result = getErr(result, saveString(the HTML of textMember, basePath & ".htm"))
  if formats.getaProp(#rtf) then set result = getErr(result, saveString(the RTF of textMember, basePath & ".rtf"))
  if formats.getaProp(#txt) then set result = getErr(result, saveString(the text of textMember, basePath & ".txt"))
  if result <> 0 then return result
  else if asImage then set result = getErr(result, exportAsImage(the image of textMember, basePath, formats))
  return result
end

on exportField fieldMember, basePath, formats, asImage
  set result = 0
  set result = getErr(result, saveString(the text of fieldMember, basePath & ".txt"))
  if asImage then set result = getErr(result, exportAsImage(the picture of fieldMember, basePath, formats))
  return result
end

on exportScript scriptMember, basePath
  return saveString(the scriptText of scriptMember, basePath & ".ls")
end

on exportImage bitmapMember, basePath, formats
  set sharpExportObj = new xtra("SharpExport")
  set result = 0
  if formats.getaProp(#png) then set result = getErr(result, sharpExportObj.exportPNG(bitmapMember, basePath & ".png"))
  if formats.getaProp(#bmp) then set result = getErr(result, sharpExportObj.exportBMP(bitmapMember, basePath & ".bmp"))
  set sharpExportObj = 0
  return result
end

on exportPicture pictureMember, basePath, formats
  return exportAsImage(the picture of pictureMember, basePath, formats)
end

on exportSound soundMember, basePath
  set soundExportObj = new xtra("MP3Xtra")
  set result = not soundExportObj.mem2wav(soundMember, basePath & ".wav")
  soundExportObj = 0
  return result
end

-- The swfExport Xtra sometimes fails spuriously, so we need to retry several times to be sure
on exportFlash flashMember, basePath
  repeat with i = 1 to 5
    set ok = exportSWF(flashMember, basePath & ".swf")
    if ok then exit repeat
    else if the debugPlaybackEnabled then
      warnMsg(getMemberErrString(flashMember) & ". Retrying...")
    end if
  end repeat
  return not ok
end

on exportShockwave3d shockwave3dMember, basePath
  -- If we don't make sure the model is loaded, we might get a blank file!
  preLoadMember(shockwave3dMember)
  savew3d(shockwave3dMember, basePath & ".w3d")
  return 0
end

on exportAsImage imageOrPicture, basePath, formats
  -- Sadly I have to use _movie.newMember because movies often override new()
  set imageHolder = _movie.newMember(#bitmap)
  case (the ilk of imageOrPicture) of
    #image: set the image of imageHolder = imageOrPicture
    #picture: set the picture of imageHolder = imageOrPicture
  end case
  set result = exportImage(imageHolder, basePath, formats)
  erase(imageHolder)
  return result
end

on getCastPrefix castLibRef, includeNames
  if includeNames and the name of castLibRef <> EMPTY then
    return sanitizeFilename(the name of castLibRef) & "_"
  else
    return the number of castLibRef & "_"
  end if
end

on getMemberPrefix memberRef, includeNames
  set prefix = EMPTY
  set castLibRef = castLib (the castLibNum of memberRef)
  if isInternalCast(castLibRef) then
    if internalCastCountOver(1) then set prefix = getCastPrefix(castLibRef, includeNames)
  end if
  put the memberNum of memberRef after prefix
  if includeNames and the name of memberRef <> EMPTY then
    put "_" & sanitizeFilename(the name of memberRef) after prefix
  end if
  return prefix
end

on getMemberBasePath memberRef, toFolder, options
  return ensureTrailingSlash(toFolder) & getMemberPrefix(memberRef, options.getaProp(#exportWithNames))
end

on getMemberIdString memberRef, isCastMemberScript
  if isCastMemberScript then set memberType = "cast member script"
  else set memberType = string(the type of memberRef)
  set str = memberType && the memberNum of memberRef
  set castNumber = the castLibNum of memberRef
  if isInternalCast(castLib castNumber) then
    put SPACE & "of castLib" && castNumber after str
  end if
  return str
end

on getMemberErrString memberRef, errorCode, isCastMemberScript
  set idString = getMemberIdString(memberRef, isCastMemberScript)
  set fName = Files.getFilename(the fileName of castLib (the castLibNum of memberRef))
  set errString = "Failed to export" && idString && "from" && fName
  if integerP(errorCode) then put ":" && "Error code" && errorCode after errString
  return errString
end

on canExport memberRef
  -- Linked members can't be exported
  if the linked of memberRef then return False
  case (the type of memberRef) of
    #bitmap, #picture:
      return the width of memberRef > 0 and the height of memberRef > 0
    #sound:
      return the channelCount of memberRef > 0
    #flash, #vectorshape, #shockwave3d:
      return True -- haven't seen these break yet...
    #text, #field:
      return the text of memberRef <> EMPTY
    otherwise: return False
  end case
end

on exportMember memberRef, toFolder, formats, options
  if the ilk of formats <> #propList then set formats = defaultFormats()
  if the ilk of options <> #propList then set options = propList()
  set memberType = the type of memberRef
  set basePath = getMemberBasePath(memberRef, toFolder, options)
  
  if canExport(memberRef) then
    case memberType of
      #bitmap:
        exportImage(memberRef, basePath, formats)
      #picture:
        exportPicture(memberRef, basePath, formats)
      #sound:
        exportSound(memberRef, basePath)
      #flash, #vectorshape:
        exportFlash(memberRef, basePath)
      #shockwave3d:
        exportShockwave3d(memberRef, basePath)
      #text:
        exportText(memberRef, basePath, formats, options.getaProp(#textToImages))
      #field:
        exportField(memberRef, basePath, formats, options.getaProp(#textToImages))
    end case
    if the result <> 0 then warnMsg(getMemberErrString(memberRef, the result))
  end if
end

on exportMemberScript memberRef, toFolder, options
  if the scriptText of memberRef <> EMPTY then
    set basePath = getMemberBasePath(memberRef, toFolder, options)
    set resultCode = exportScript(memberRef, basePath)
    if resultCode <> 0 then
      warnMsg(getMemberErrString(memberRef, resultCode, the type of memberRef <> #script))
    end if
  end if
end

on exportMemberCsv castLibRef, toFolder, options
  set memberCsv = memberCsvHeader()
  set csvName = "Members"
  if isInternalCast(castLibRef) and internalCastCountOver(1) then
    put getCastPrefix(castLibRef, options.getaProp(#exportWithNames)) before csvName
  end if
  set castNumber = the number of castLibRef
  repeat with i = 1 to the number of members of castLib castNumber
    set memberRef = member i of castLib castNumber
    if the type of memberRef <> #empty then put newCsvLine(getMemberInfo(memberRef)) after memberCsv
  end repeat
  if the number of lines of memberCsv > 1 then saveString(memberCsv, toFolder & csvName & ".csv")
end

on exportCastMembers castLibRef, toFolder, memberTypes, formats, options
  exportMemberCsv(castLibRef, toFolder, options)
  -- member() and number of members take a castLib by number or name only, not reference
  set castNumber = the number of castLibRef
  repeat with i = 1 to the number of members of castLib castNumber
    set memberRef = member i of castLib castNumber
    if the type of memberRef <> #empty then
      if memberTypes.getaProp(#script) then exportMemberScript(memberRef, toFolder, options)
      if memberTypes.getaProp(the type of memberRef) then exportMember(memberRef, toFolder, formats, options)
    end if
  end repeat
end

on exportCastCsv toFolder
  set castCsv = castCsvHeader()
  repeat with i = 1 to the number of castLibs
    set castLibRef = castLib i
    put newCsvLine(getCastLibInfo(castLibRef)) after castCsv
  end repeat
  saveString(castCsv, toFolder & "Casts.csv")
end

on exportMovieMembers movieRef, toFolder, memberTypes, formats, options
  tell movieRef
    exportCastCsv(toFolder)
    repeat with i = 1 to the number of castLibs
      set castLibRef = castLib i
      if isInternalCast(castLibRef) then
        exportCastMembers(castLibRef, toFolder, memberTypes, formats, options)
      end if
    end repeat
  end tell
end

on exportFromFiles movieFiles, castFiles, toFolder, memberTypes, formats, options, toolPaths
  set decompilerPath = toolPaths.getaProp(#projectorRays)
  set decompile = options.getaProp(#decompile) and stringP(decompilerPath)
  set movieCsv = movieCsvHeader()
  repeat with movieFile in movieFiles
    set movieRef = linkMovie(movieFile)
    if not voidP(movieRef) then
      tell movieRef
        put newCsvLine(getMovieInfo(movieRef)) after movieCsv
        set movieFolder = getFileFolder(toFolder)
        exportMovieMembers(movieRef, movieFolder, memberTypes, formats, options)
      end tell
      set linkedCasts = getExternalCasts(movieRef)
      repeat with castFile in linkedCasts
        if castFiles.getPos(castFile) = 0 then castFiles.append(castFile)
      end repeat
      if decompile then decompileIfProtected(decompilerPath, movieFile, toFolder)
    end if
  end repeat
  if the number of lines of movieCsv > 1 then saveString(movieCsv, toFolder & "Movies.csv")
  
  repeat with castFile in castFiles
    set castLibRef = linkCast(castFile)
    if not voidP(castLibRef) then
      set castFolder = getFileFolder(toFolder, castLibRef)
      exportCastMembers(castLibRef, castFolder, memberTypes, formats, options)
      if decompile then decompileIfProtected(decompilerPath, castFile, toFolder)
    end if
  end repeat
end

on incrementalExport
  global exportFolder, memberTypes, exportFormats, exportOptions, toolPaths
  global movieCsv, movieRef, memberRef -- persistent variables
  global currFilename, currMemberId -- info for the UI
  
  set decompilerPath = toolPaths.getaProp(#projectorRays)
  set decompile = exportOptions.getaProp(#decompile) and stringP(decompilerPath)
  
  if voidP(movieRef) or voidP(memberRef) then -- first run
    set movieCsv = movieCsvHeader()
  else
    set prevCastNum = the castLibNum of memberRef
    tell movieRef to set memberRef = nextMember(memberRef)
  end if
  
  repeat while voidP(memberRef)
    if not voidP(movieRef) then Progress.finishTask()
    set movieRef = the window
    set prevCastNum = 0
    set linkedMovieOrCast = nextFile()
    set currMemberId = EMPTY
    case (the ilk of linkedMovieOrCast) of
      #sprite: -- Linked movie sprite
        set memberRef = member 0 of castLib 1
        set movieRef = linkedMovieOrCast
        tell movieRef
          Progress.setSteps(movieMemberCount(True))
          put newCsvLine(getMovieInfo(movieRef)) after movieCsv
          exportCastCsv(getFileFolder(exportFolder))
          if decompile then decompileIfProtected(decompilerPath, movieFilePath(), exportFolder)
        end tell
      #castLib:
        set castNumber = the number of linkedMovieOrCast
        Progress.setSteps(the number of members of castLib castNumber)
        set memberRef = member 0 of castLib castNumber
      #void: -- Failed to link file
        if the frameLabel = "Export" then next repeat -- User chose to continue export
        else return True -- User chose to cancel
      otherwise: -- No more files to process
        if the number of lines of movieCsv > 1 then saveString(movieCsv, exportFolder & "Movies.csv")
        set movieRef = VOID
        set currFilename = EMPTY
        set movieCsv = EMPTY
        return False
    end case
    tell movieRef to set memberRef = nextMember(memberRef)
  end repeat
  
  tell movieRef
    set castLibRef = castLib (the castLibNum of memberRef)
    set currFilename = Files.getFilename(the fileName of castLibRef)
    set castFolder = getFileFolder(exportFolder, castLibRef)
    if prevCastNum < the number of castLibRef then
      exportMemberCsv(castLibRef, castFolder, exportOptions)
      if decompile and not isInternalCast(castLibRef) then
        decompileIfProtected(decompilerPath, the fileName of castLibRef, exportFolder)
      end if
    end if
    if memberTypes.getaProp(#script) and not voidP(script(memberRef)) then
      set currMemberId = getMemberIdString(memberRef, True)
      exportMemberScript(memberRef, castFolder, exportOptions)
    end if
    if memberTypes.getaProp(the type of memberRef) then
      set currMemberId = getMemberIdString(memberRef, False)
      exportMember(memberRef, castFolder, exportFormats, exportOptions)
    end if
  end tell
  return True
end

on getFileVersion
  set str = the fileVersion
  put "." before char (the number of chars of str) - 1 of str
  if the last char of str = "0" then delete the last char of str
  else put "." before char (the number of chars of str) of str
  return str
end

on memberCsvHeader
  return "Number,Type,Name,Registration Point,Filename"
end

on getMemberInfo memberRef
  return [the memberNum of memberRef, the type of memberRef, the name of memberRef, \
          Utils.pointToStr(the regPoint of memberRef), the fileName of memberRef]
end

on castCsvHeader
  return "Number,Name,Filename"
end

on getCastLibInfo castLibRef
  set fName = Files.getFilename(the fileName of castLibRef)
  if fName = the movieName then set fName = EMPTY
  return [the number of castLibRef, the name of castLibRef, fName]
end

on movieCsvHeader
  return "Filename,Director Version,Frames,Channels,Rect,About,Copyright,Created By,Modified By,Markers,Xtras"
end

on getMovieInfo
  return [the movieName, getFileVersion(), the lastFrame, the lastChannel, \
          Utils.getLinkedMovieRect(), the movieAboutInfo, the movieCopyrightInfo, \
          getMovieMoaProperty(#createName), getMovieMoaProperty(#modifyName), \
          the markerList, the movieXtraList]
end

on newCsvLine valsList
  global CRLF
  set csvLine = EMPTY
  repeat with val in valsList
    if csvLine <> EMPTY then put "," after csvLine
    put csvStringEscape(val) after csvLine
  end repeat
  return CRLF & csvLine
end

on csvStringEscape str
  if not stringP(str) then set str = string(str)
  set needsQuotes = False
  repeat with i = 1 to the number of chars in str
    case (char i of str) of:
      QUOTE:
        set needsQuotes = True
        put QUOTE before char i of str
        -- since we inserted a char, we have to jump forward one to stay in the same spot
        set i = i + 1
      RETURN, numToChar(10), ",":
        set needsQuotes = True
    end case
  end repeat
  if needsQuotes then
    put QUOTE before str
    put QUOTE after str
  end if
  return str
end

on isInternalCast castLibRef
  return movieFilePath() = the fileName of castLibRef
end

on getFileFolder containingFolder, castLibRef
  global fxObj, fileFolders
  if voidP(fileFolders) then set fileFolders = propList()
  if voidP(castLibRef) then set filePath = movieFilePath()
  else set filePath = the fileName of castLibRef
  set folderPath = fileFolders.getaProp(filePath)
  if folderPath starts containingFolder then -- VOID starts str is always false
    if fxObj.fx_FolderExists(folderPath) then return folderPath
  end if
  set folderPath = Files.createSubfolder(containingFolder, getFileBaseName(filePath))
  fileFolders.setaProp(filePath, folderPath)
  return folderPath
end

on getExternalCasts movieRef
  set casts = list()
  if not voidP(movieRef) then
    tell movieRef
      repeat with i = 1 to the number of castLibs
        if not isInternalCast(castLib i) then casts.append(the fileName of castLib i)
      end repeat
    end tell
  end if
  return casts
end

on internalCastCountOver num
  set iCastCount = 0
  repeat with i = 1 to the number of castLibs
    set iCastCount = iCastCount + isInternalCast(castLib i)
    if iCastCount > num then return True
  end repeat
  return False
end

on movieMemberCount includeExternal
  set numMembers = 0
  repeat with i = 1 to the number of castLibs
    if isInternalCast(castLib i) or includeExternal then
      set numMembers = numMembers + the number of members of castLib i
    end if
  end repeat
  return numMembers
end

on movieFilePath
  return the moviePath & the movieName
end

on canLoad dirFile
  -- preLoadMovie returns 0 if the file is successfully loaded
  -- This also works for cast files in Director 11 and below, but sadly not 11.5 or 12
  return preLoadMovie(dirFile) = 0 and unLoadMovie(dirFile) = 0
end

on linkMovie movieFilePath
  set linkedMember = member "Linked"
  set linkedMovieSprite = sprite "Linked"
  set errMsg = "The specified movie file could not be loaded:" && Files.getFilename(movieFilePath)
  set the visible of linkedMovieSprite to False
  
  if not canLoad(movieFilePath) then
    Logging.errorMsg(errMsg)
    return VOID
  end if
  
  if the type of linkedMember = #movie then
    set the sound of linkedMember to False
    set the scriptsEnabled of linkedMember to False
    set the fileName of linkedMember = movieFilePath
    set isValid = preLoadMember(linkedMember)
    if not isValid then
      Logging.errorMsg(errMsg)
      return VOID
    end if
    return linkedMovieSprite
  end if
end

on linkCast castFilePath
  set linkedCast = castLib "Linked"
  -- Since preLoadMovie doesn't work anymore in Dir11.5+, check the file header instead
  -- This isn't as reliable but it's better than nothing
  if Utils.directorVersion() < 11.5 then set isValid = canLoad(castFilePath)
  else set isValid = Files.isValidDirFile(castFilePath)
  if not isValid then
    set msg = "The specified cast file could not be loaded:" && Files.getFilename(castFilePath)
    Logging.errorMsg(msg)
    return VOID
  end if
  set the fileName of linkedCast = castFilePath
  return linkedCast
end

on unlink
  global pathSep
  set emptyFile = "Xtras" & pathSep & "empty"
  set the fileName of member "Linked" = emptyFile
  set the fileName of castLib "Linked" = emptyFile
end

on runAutoclicker
  global toolPaths
  set autoClicker = toolPaths.getaProp(#autoClicker)
  if stringP(autoClicker) then
    -- Pass the autoclicker a window title so we can find it later
    baRunProgram(autoClicker && "AutoClicker", "hidden", False) -- BuddyAPI function
  end if
end

on closeAutoclicker
  set winHandle = baFindWindow("ImlWinCls", "AutoClicker")
  if winHandle > 0 then baCloseWindow(winHandle)
end

on runDecompiler exePath, filePath, exportPath, isMovie
  global fxObj
  if isMovie then set unprotectedExt = "dir"
  else set unprotectedExt = "cst"
  set baseName = Files.getFileBaseName(filePath)
  set unprotectedPath = Files.getUniqueFile(exportPath, baseName, unprotectedExt)
  set args = "decompile" && quotePath(filePath) && "-o" && quotePath(unprotectedPath)
  baRunProgram(exePath && args, "hidden", True) -- BuddyAPI function
  if fxObj.fx_FileExists(unprotectedPath) then return unprotectedPath
  else Logging.warnMsg("Failed to decompile" && Files.getFilename(filePath))
end

on decompileIfProtected decompilerPath, dirFiles, toFolder
  if not listP(dirFiles) then set dirFiles = list(dirFiles)
  set protectedMovieExts = ["dxr", "dcr"]
  set protectedCastExts = ["cxt", "cct"]
  repeat with dirFile in dirFiles
    set ext = getFileExt(dirFile)
    if Utils.listContains(protectedMovieExts, ext) then
      runDecompiler(decompilerPath, dirFile, toFolder, True)
    else if Utils.listContains(protectedCastExts, ext) then
      runDecompiler(decompilerPath, dirFile, toFolder, False)
    end if
  end repeat
end

on synchronousExport
  global movieFiles, castFiles, exportFolder, memberTypes, exportFormats, exportOptions, toolPaths
  initExport()
  exportFromFiles(movieFiles, castFiles, exportFolder, memberTypes, exportFormats, exportOptions, toolPaths)
  if exportOptions.getaProp(#dismissDialogs) then closeAutoclicker()
  resetLog()
  infoMsg("Exported assets to" && exportFolder)
end

on initExport
  global movieFiles, castFiles, exportOptions
  if the debugPlaybackEnabled then logOptions()
  setTasks(the count of movieFiles + the count of castFiles)
  createLogFile()
  if exportOptions.getaProp(#dismissDialogs) then runAutoclicker()
end

-- Avoid processing the same external castLib multiple times
on shouldSkip castLibRef
  global fileFolders
  if the ilk of fileFolders = #propList then
    if not isInternalCast(castLibRef) then
      return fileFolders.findPos(the fileName of castLibRef) > 0
    end if
  end if
  return False
end

on nextMember memberRef
  set memberNumber = the memberNum of memberRef
  set castNumber = the castLibNum of memberRef
  repeat with i = (memberNumber + 1) to the number of members of castLib castNumber
    if i > 1 then Progress.finishStep()
    set nextMemberRef = member i of castLib castNumber
    if the type of nextMemberRef <> #empty then return nextMemberRef
  end repeat
  repeat with i = (castNumber + 1) to the number of castLibs
    if not shouldSkip(castLib i) then return nextMember(member 0 of castLib i)
  end repeat
end

on nextFile
  global movieFiles, castFiles
  if the count of movieFiles > 0 then
    set movieRef = linkMovie(movieFiles.getAt(1))
    movieFiles.deleteAt(1)
    set linkedCasts = getExternalCasts(movieRef)
    repeat with castFile in linkedCasts
      set dedupeCount = dedupeCount + castFiles.deleteOne(castFile)
    end repeat
    if dedupeCount then Progress.removeTasks(dedupeCount)
    return movieRef
  else if the count of castFiles > 0 then
    set castLibRef = linkCast(castFiles.getAt(1))
    castFiles.deleteAt(1)
    return castLibRef
  else
    return False
  end if
end

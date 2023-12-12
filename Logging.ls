global CRLF, consoleMode, cxObj

on initConsole
  set CRLF = RETURN & numToChar(10)
  set consoleMode = False
  set cxObj = new xtra("console")
  if cxObj.consoleExists() then
    if cxObj.consoleAttach() then
      cxObj.stdOut(CRLF)
      if the count of getCommandLineArgs() > 0 then set consoleMode = True
    end if
  end if
end

on createLogFile
  global exportFolder, logFile
  set fPath = getUniqueFile(exportFolder, "Export", "log")
  set result = writeLog(EMPTY, fPath)
  if result.code = 0 then set logFile = fPath
  else errorMsg(result.message)
  return result.code
end

on resetLog
  global logFile, numWarnings
  if stringP(logFile) and not numWarnings then deleteEmptyFile(logFile)
  set logFile = VOID
  set numWarnings = 0
end

on logMsg msg
  global logFile
  put msg
  put CRLF after msg
  if stringP(logFile) then
    set result = writeLog(msg, logFile)
    if result.code <> 0 then
      set logFile = False
      errorMsg(result.message)
    end if
  end if
end

on infoMsg msg
  cxObj.stdOut(msg & CRLF)
  logMsg(msg)
end

on warnMsg msg
  global numWarnings
  set numWarnings = numWarnings + 1
  cxObj.stdErr(msg & CRLF)
  logMsg(msg)
end

on errorMsg msg
  warnMsg(msg)
  if consoleMode then quit()
  else errorDialog(msg)
end

on logOptions
  global movieFiles, castFiles, exportFolder, memberTypes, exportFormats, exportOptions, toolPaths
  infoMsg("Movies:" && movieFiles)
  infoMsg("Casts:" && castFiles)
  infoMsg("Export folder:" && exportFolder)
  infoMsg("Member types:" && memberTypes)
  infoMsg("Export formats:" && exportFormats)
  infoMsg("Export options:" && exportOptions)
  infoMsg("Tool paths:" && toolPaths)
end

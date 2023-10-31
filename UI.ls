global nextBtn, backBtn

on initUI
  set nextBtn = sprite "NextButton"
  set backBtn = sprite "BackButton"
  repeat with btn in [nextBtn, backBtn]
    if the visible of btn then btn.setStyle("fontSize", 18)
  end repeat
  -- Setting Flash sprite properties does not work until after the first stage update
  updateStage()
  initScreen()
  updateScreen()
end

on initScreen
  case the frameLabel of
    "Choose Files": initFileChooserScreen()
    "Options": initOptionsScreen()
    "Export": initExportScreen()
  end case
end

on updateScreen
  case the frameLabel of
    "Choose Files": updateFileChooserScreen()
    "Options": updateOptionsScreen()
    "Export": updateExportScreen()
  end case
end

on nextScreen
  go next
  initScreen()
end

on prevScreen
  go previous
  initScreen()
end

on gotoScreen screenName
  go to screenName
  initScreen()
  updateScreen()
end

on initFileChooserScreen
  global movieFiles, castFiles
  set the visible of backBtn = False
  set the visible of nextBtn = True
  set the label of nextBtn = "Next >"
  
  addFiles(movieFiles)
  addFiles(castFiles)
end

on updateFileChooserScreen
  set listObj = sprite "FileList"
  set removeBtn = sprite "RemoveButton"
  set removeAllBtn = sprite "RemoveAllButton"
  
  -- Very ugly hack to check from Lingo whether a Flash variable is undefined
  set the enabled of removeBtn = not(voidP(listObj["selectedIndices"]))
  
  set notEmpty = listObj.length > 0
  set the enabled of removeAllBtn = notEmpty
  set the enabled of nextBtn = notEmpty
  if notEmpty then setSelectedFiles(the data of listObj)
end

on initOptionsScreen
  global exportFolder
  set the visible of backBtn = True
  set the label of backBtn = "< Back"
  set the visible of nextBtn = True
  set the label of nextBtn = "Export"
  
  setDefaultExportFolder()
  set the text of sprite "FolderPathBox" = exportFolder
  initCheckboxes()
end

on updateOptionsScreen
  updateCheckboxes()
  set the enabled of nextBtn = setExportFolder(the text of sprite "FolderPathBox")
end

on initExportScreen
  set the visible of nextBtn = False
  set the text of field "StatusHeading" = "Exporting..."
  initExport()
end

on updateExportScreen
  global currFilename, currMemberId
  if stringP(currFilename) and stringP(currMemberId) then
    if the text of field "CurrentFile" <> currFilename then
      set the text of field "CurrentFile" = currFilename
    end if
    if the text of field "CurrentMember" <> currMemberId then
      set the text of field "CurrentMember" = currMemberId
    end if
  end if
  updateProgressBar()
end

on showButtons
  if not voidP(backBtn) then set the visible of backBtn = True
  if not voidP(nextBtn) then set the visible of nextBtn = True
end

on clickButton buttonName
  case buttonName of
    "NextButton": nextScreen()
    "BackButton": prevScreen()
    "AddButton": addFiles()
    "RemoveButton": removeFiles()
    "RemoveAllButton": removeAllFiles()
    "BrowseButton": chooseFolder()
  end case
  updateScreen()
end

on clickCheckbox boxSprite
  global exportFormats, exportOptions
  set optName = the opt of boxSprite
  if the enabled of boxSprite then
    set boxState = the selected of boxSprite
    setOpt(optName, boxState)
    updateScreen()
  else
    case optName of
      #shockwave3d: missingToolAlert(#castRipper)
      #decompile: missingToolAlert(#projectorRays)
      otherwise: nothing
    end case
  end if
end

on initCheckboxes
  repeat with i = 1 to the lastChannel
    set sp = sprite i
    if the name of sp contains "Checkbox" then
      set the selected of sp = getOpt(the opt of sp)
    end if
  end repeat
end

on updateCheckboxes
  repeat with i = 1 to the lastChannel
    set sp = sprite i
    if the name of sp contains "Checkbox" then
      set the enabled of sp = canEnable(the opt of sp)
    end if
  end repeat
end

on getCheckbox opt
  if stringP(opt) then
    return sprite (opt & "Checkbox")
  else if symbolP(opt) then
    repeat with i = 1 to the lastChannel
      set sp = sprite i
      if the name of sp contains "Checkbox" then
        if the opt of sp = opt then return sp
      end if
    end repeat
  end if
end

on getCheckboxGroup groupName
  set sprites = list()
  set labelSprite = sprite (groupName & "Label")
  if not voidP(labelSprite) then
    set startNum = the spriteNum of labelSprite + 1
    repeat with i = startNum to the lastChannel
      set sp = sprite i
      if the name of sp contains "Checkbox" then
        sprites.append(sp)
      else
        exit repeat
      end if
    end repeat
  end if
  return sprites
end

on addFiles selectedFiles
  set listObj = sprite "FileList"
  set listData = the data of listObj
  set listLabels = the labels of listObj
  if not listP(selectedFiles) then set selectedFiles = fileMultiSelect()
  repeat with filePath in selectedFiles
    if listData.getPos(filePath) = 0 then 
      listData.add(filePath)
      listLabels.add(getFilename(filePath))
    end if
  end repeat
  set the data of listObj = listData
  set the labels of listObj = listLabels
end

on removeFiles
  set listObj = sprite "FileList"
  set listData = the data of listObj
  set listLabels = the labels of listObj
  -- Flash lists are zero-indexed but at least Lingo has a nice shorthand to fix it
  set highlighted = (the selectedIndices of listObj) + 1
  repeat with i in highlighted
    listData.setAt(i, EMPTY)
    listLabels.setAt(i, EMPTY)
  end repeat
  repeat while listData.deleteOne(EMPTY)
    listLabels.deleteOne(EMPTY)
  end repeat
  set the data of listObj = listData
  set the labels of listObj = listLabels
end

on removeAllFiles
  set listObj = sprite "FileList"
  set the data of listObj = list()
  set the labels of listObj = list()
end

on chooseFolder
  set folderPath = folderSelect()
  if folderPath <> EMPTY then set the text of sprite "FolderPathBox" to folderPath
end

on updateProgressBar
  set fraction = getProgress()
  set progBarRect = the rect of sprite "ProgressBar"
  -- Only fill the inner area of the progress bar, excluding the 1-pixel border
  set fillRect = rect(topLeft(progBarRect) + 1, bottomRight(progBarRect) - 1)
  set fillWidth = fraction * the width of fillRect
  set the right of fillRect = the left of fillRect + fillWidth
  set the rect of sprite "ProgBarFill" = fillRect
  updateStage()
end

on muiDialog muiOptions
  set muiObj = new xtra("mui")
  set choice = muiObj.Alert(muiOptions)
  set muiObj = 0
  return choice
end

on infoDialog title, message, icon
  set muiOptions = [#buttons: #Ok, #default: 1, #icon: icon, \
                    #message: message, #movable: True, #title: title]
  muiDialog(muiOptions)
end

on errorDialog message
  put RETURN & "Continue exporting?" after message
  set muiOptions = [#buttons: #YesNo, #default: 2, #icon: #error, \
                    #message: message, #movable: True, #title: "Export Error"]
  
  set choice = muiDialog(muiOptions)
  if choice = 2 then 
    if the frameLabel <> "Choose Files" then gotoScreen("Choose Files")
    else halt()
  end if
end

on missingToolAlert toolName
  set toolInfo = getaProp(the value of field "ToolInfo", toolName)
  set msg = toolInfo.getaProp(#msg) & RETURN & "Download it now?"
  set goURL = toolInfo.getaProp(#url)
  set muiOptions = [#buttons: #YesNo, #default: 1, #icon: #question, \
                    #message: msg, #movable: True, #title: "Software Download"]
  
  set choice = muiDialog(muiOptions)
  if choice = 1 then gotoNetPage goURL
end

on finishExport
  global numWarnings, exportFolder, exportOptions, fileFolders
  if exportOptions.getaProp(#dismissDialogs) then closeAutoclicker()
  unlink()
  -- Make sure the progress bar shows as full before the dialog appears
  updateScreen()
  updateStage()
  set title = "Finished"
  set message = "Export completed"
  if numWarnings then
    set icon = #caution
    put SPACE & "with warnings" after title
    put SPACE & "with" && numWarnings && "warnings. See the Export.log file for details." after message
  else
    set icon = #note
    put "!" after title
    put "." after message
  end if
  resetLog()
  set fileFolders = propList()
  infoDialog(title, message, icon)
  resetProgress()
  openPath(exportFolder)
  set exportFolder = VOID
  gotoScreen("Choose Files")
end

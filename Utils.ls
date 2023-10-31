on updateCategory category, enable
  global memberCategories, memberTypes
  set allCategories = the value of field "MemberCategories"
  set types = allCategories.getaProp(category)
  if listP(types) then
    memberCategories.setaProp(category, enable)
    repeat with t in types
      memberTypes.setaProp(t, enable)
    end repeat
  end if
end

on enableAllCategories
  set allCategories = getAllProps(the value of field "MemberCategories")
  repeat with category in allCategories
    if canEnable(category) then updateCategory(category, True)
  end repeat
end

on getOptGroup opt
  set allFormats = the value of field "ExportFormats"
  set allOptions = the value of field "ExportOptions"
  if allFormats.getPos(opt) then return #exportFormats
  else if allOptions.getPos(opt) then return #exportOptions
  else return #memberCategories
end

on canEnable opt
  global toolPaths
  case opt of
    #image: return objectP(xtra("SharpExport"))
    #sound: return objectP(xtra("MP3Xtra"))
    #flash: return objectP(xtra("SwfExport"))
    #shockwave3d: return directorVersion() >= 11.0
    #text: return True
    #png, #bmp: return isEnabled(#image) or isEnabled(#textToImages)
    #html, #rtf, #txt: return isEnabled(#text)
    #exportWithNames: return True
    #decompile: return stringP(toolPaths.getaProp(#projectorRays))
    #dismissDialogs: return stringP(toolPaths.getaProp(#autoClicker))
    #textToImages: return isEnabled(#text)
  end case
end

on isEnabled opt
  return canEnable(opt) and getOpt(opt)
end

on getOpt optName
  global memberCategories, exportFormats, exportOptions
  case getOptGroup(optName) of
    #memberCategories: return memberCategories.getaProp(optName)
    #exportFormats: return exportFormats.getaProp(optName)
    #exportOptions: return exportOptions.getaProp(optName)
  end case
end

on setOpt optName, enable
  global exportFormats, exportOptions
  case getOptGroup(optName) of
    #memberCategories: updateCategory(optName, enable)
    #exportFormats: exportFormats.setaProp(optName, enable)
    #exportOptions: exportOptions.setaProp(optName, enable)
  end case
end

on getLinkedMovieRect
  set r = the rect of member "Linked"
  return pointToStr(topLeft(r)) && "=>" && pointToStr(bottomRight(r))
end

on pointToStr p
  delete char 1 to (the number of chars in "point") of p
  return p
end

on topLeft rectangle
  return point(the left of rectangle, the top of rectangle)
end

on bottomRight rectangle
  return point(the right of rectangle, the bottom of rectangle)
end

on getAllProps pList
  set ret = list()
  repeat with i = 1 to the count of pList
    ret.append(pList.getPropAt(i))
  end repeat
  return ret
end

-- Check if val is present in list, case-insensitively
on listContains lst, val
  repeat with listItem in lst
    if listItem = val then return True
  end repeat
  return False
end

-- Append all itemsToAdd to targetList
on appendItems targetList, itemsToAdd
  repeat with listItem in itemsToAdd
    targetList.append(listItem)
  end repeat
  return targetList
end

on incrementString str
  set len = the number of chars of str
  repeat with i = len down to 1
    set maybeNum = integer(char i to len of str)
    if integerP(maybeNum) then set num = maybeNum
    else exit repeat
  end repeat
  
  if integerP(num) then put (num + 1) into char (i + 1) to len of str
  else put 2 after str
  return str
end

-- Since the "browser" is set to explorer.exe, we can open folders/files with it
on openPath location
  gotoNetPage location
end

on directorVersion
  set the itemDelimiter = "."
  return float(item 1 to 2 of the productversion)
end

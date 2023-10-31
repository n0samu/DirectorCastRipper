on exitFrame me
  updateScreen()
  go to the frame
end

on idle me
  if not incrementalExport() then finishExport()
end

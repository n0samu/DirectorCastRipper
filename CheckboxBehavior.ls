property opt

on getPropertyDescriptionList me
  list = [:]
  addProp list, #opt, [#comment: "The option that this checkbox corresponds to:", #format: #symbol, #default: #empty ]
  return list
end

on mouseUp me
  set cb = sprite (the spriteNum of me)
  clickCheckbox(cb)
end

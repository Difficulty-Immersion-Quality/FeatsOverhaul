--  Retrieves the name of an entity by GUID
function getNameFromGuid(entityGuid)
  local nameHandle = Osi.GetDisplayName(entityGuid) or Osi.TemplateGetDisplayString(entityGuid) or ""
  local nameString = Osi.ResolveTranslatedString(nameHandle) or ""
  return nameString
end

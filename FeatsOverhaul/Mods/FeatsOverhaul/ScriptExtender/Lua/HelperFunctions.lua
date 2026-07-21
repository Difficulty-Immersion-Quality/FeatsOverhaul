local H = {}

-- Ext.Entity.Get that also accepts a prefixed Osiris string (strips to the bare UUID first)
function H.GetEntity(raw)
    return Ext.Entity.Get(raw:sub(-36))
end

-- Grabs a display name straight off the entity, no Osiris so it works in any context (SessionLoaded included)
function H.GetDisplayName(uuid, fallback)
    local entity = H.GetEntity(uuid)
    if not entity then return fallback or uuid end
    if entity.CustomName then return entity.CustomName.Name end
    if entity.DisplayName then return entity.DisplayName.Name:Get() or fallback or uuid end
    return fallback or uuid
end

return H

local H = Ext.Require("HelperFunctions.lua")

Ext.Vars.RegisterModVariable(ModuleUUID, "WeaponPropertyTracker", {})

-- Apply any changes to weapon properties (i.e. Versatile being removed) on session load, as changes to weapon properties would otherwise by overwritten by the weapon's stats entry
local function initializeweaponProperties()
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    if (next(ModVars) ~= nil) then
        -- Apply stored weapon properties
        for uuid, data in pairs(ModVars) do
            local entity = H.GetEntity(uuid)
            if entity and entity.Weapon then
                entity.Weapon.WeaponProperties = data.WeaponProperties
                -- push it to clients too on load, otherwise they might keep the stats-default properties (untested, revisit)
                entity:Replicate("Weapon")
            end
        end
        -- -- Debugging
        -- _P(string.format("[FeatsOverhaul] [initializeweaponProperties()] ModVars Dump =>"))
        -- for uuid, data in pairs(ModVars) do
        --     local entity = H.GetEntity(uuid)
        --     _P(string.format("| Stored Weapon: '%s' | Stored UUID: '%s' | Stored Weapon Properties: '%s' | Stored Wielder: '%s'",
        --         H.GetDisplayName(uuid), uuid, data.WeaponProperties, tostring(data.Wielder)))
        -- end
    end
end

Ext.Events.SessionLoaded:Subscribe(initializeweaponProperties)

-- Remove Versatile property from weapon
local function removeVersatile(weapon)
    -- Returns as bit flags (decimal)
    local weaponProperties = weapon.Weapon.WeaponProperties
    -- Remove Versatile property (=2048 in decimal form under WeaponFlags)
    local weaponProperties_New = weaponProperties & ~2048
    weapon.Weapon.WeaponProperties = weaponProperties_New
    -- Stores the new properties to the weapon entity in the mod variable
    local entityUUID = weapon.Uuid.EntityUuid
    local wielderUUID = Osi.GetInventoryOwner(weapon.Uuid.EntityUuid)
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    ModVars[entityUUID] = {
        WeaponProperties = weaponProperties_New,
        Wielder = wielderUUID
    }
    Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")
    -- -- Debugging
    -- local displayName = H.GetDisplayName(entityUUID)
    -- _P(string.format("[FeatsOverhaul] [removeVersatile()] =>"))
    -- _P(string.format("| Weapon: '%s' ('%s')", displayName, entityUUID))
    -- _P(string.format("| Old Weapon Properties: '%s'", weaponProperties))
    -- _P(string.format("| New Weapon Properties: '%s'", weaponProperties_New))
    -- _P(string.format("| ModVars After removeVersatile()"))
    -- for uuid, data in pairs(ModVars) do
    --     _P(string.format("| -> Weapon: '%s' | UUID: '%s' | Stored Properties: '%s' | Stored Wielder: '%s'", 
    --     H.GetDisplayName(uuid), uuid, data.WeaponProperties, tostring(data.Wielder)))
    -- end
end

-- Restore Versatile property to weapon
local function restoreVersatile(weapon)
    -- Returns as bit flags (decimal)
    local weaponProperties = weapon.Weapon.WeaponProperties
    -- Add Versatile property (=2048 in decimal form under WeaponFlags)
    local weaponProperties_New = weaponProperties | 2048
    weapon.Weapon.WeaponProperties = weaponProperties_New
    -- Remove the weapon's entry in the mod variables table
    local entityUUID = weapon.Uuid.EntityUuid
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    ModVars[entityUUID] = nil
    Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")
    -- -- Debugging
    -- local displayName = H.GetDisplayName(entityUUID)
    -- _P(string.format("[FeatsOverhaul] [restoreVersatile()] =>"))
    -- _P(string.format("| Weapon: '%s' ('%s')", displayName, entityUUID))
    -- _P(string.format("| Old Weapon Properties: '%s'", weaponProperties))
    -- _P(string.format("| New Weapon Properties: '%s'", weaponProperties_New))
    -- _P(string.format("| ModVars After restoreVersatile()"))
    -- if next(ModVars) == nil then
    --     _P("| -> ModVars is empty")
    -- else
    --     for uuid, data in pairs(ModVars) do
    --         _P(string.format(
    --             "| -> Weapon: '%s' | UUID: '%s' | Stored Properties: '%s'", 
    --             H.GetDisplayName(uuid), uuid, data.WeaponProperties, tostring(data.Wielder)))
    --     end
    -- end
end

-- Listening for statuses being applied to the weapon
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(weapon, status, _, _)
    local weaponEntity = H.GetEntity(weapon)
    if not weaponEntity or not weaponEntity.Weapon then
        return
    end
    local entityUUID = weaponEntity.Uuid.EntityUuid
    -- Normal functionality: CHT_DUELIST_REMOVED_VERSATILE status applied; remove the Versatile property
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        removeVersatile(weaponEntity)
        return
    end
    -- Some other status restored Versatile while the CHT_DUELIST_REMOVED_VERSATILE status is still active, so re-remove Versatile
    if Osi.HasActiveStatus(entityUUID, "CHT_DUELIST_REMOVED_VERSATILE") == 1 and (weaponEntity.Weapon.WeaponProperties & 2048) ~= 0 then
        removeVersatile(weaponEntity)
        -- -- Debugging
        -- local displayName = H.GetDisplayName(entityUUID)
        -- _P(string.format(
        --     "[FeatsOverhaul] Weapon: '%s' ('%s') had its Versatile property restored by status '%s'; removing Versatile again",
        --     displayName, entityUUID, status))
    end
end)

-- Guard to prevent the StatusRemoved listener from being re-triggered when it directly removes the CHT_DUELIST_REMOVED_VERSATILE status
local suppressRestore = {}

-- Listening for the remove Versatile status being removed from the weapon (not listening for the restore Versatile helper status being applied, to also catch long rests which remove the main status but don't apply that helper status)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(weapon, status, _, _)
    local weaponEntity = H.GetEntity(weapon)
    if not weaponEntity or not weaponEntity.Weapon then
        return
    end
    local entityUUID = weaponEntity.Uuid.EntityUuid
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    -- Some other status restored Versatile while the CHT_DUELIST_REMOVED_VERSATILE status is still active, so remove CHT_DUELIST_REMOVED_VERSATILE
    if status ~= "CHT_DUELIST_REMOVED_VERSATILE" and Osi.HasActiveStatus(entityUUID, "CHT_DUELIST_REMOVED_VERSATILE") == 1 and (weaponEntity.Weapon.WeaponProperties & 2048) ~= 0 then
        -- Remove status from weapon and add weapon to the guard table to prevent the status removal from re-triggering this listener and triggering the restoreVersatile() function
        suppressRestore[weapon] = true
        Osi.RemoveStatus(weapon, "CHT_DUELIST_REMOVED_VERSATILE")
        -- Remove status from character
        local tracker = ModVars[entityUUID]
        if tracker and tracker.Wielder then
            Osi.RemoveStatus(tracker.Wielder,"CHT_DUELIST_REMOVED_VERSATILE_HELPER")
        end
        -- -- Debugging
        -- local displayName = H.GetDisplayName(entityUUID)
        -- _P(string.format(
        --     "[FeatsOverhaul] Weapon: '%s' ('%s') had its Versatile property restored by status '%s'; removing CHT_DUELIST_REMOVED_VERSATILE status",
        --     displayName, entityUUID, status))
        -- return
    end
    -- Normal functionality: CHT_DUELIST_REMOVED_VERSATILE status removed; restore the Versatile property
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        -- Prevent the restoreVersatile() function from running if the Versatile property is removed via the IF statement earlier in this listener
        if suppressRestore[weapon] then
            suppressRestore[weapon] = nil
            return
        end
        restoreVersatile(weaponEntity)
    end
end)


-- Ext_Enums.WeaponFlags = {
--     Light = 1,
--     Ammunition = 2,
--     Finesse = 4,
--     Heavy = 8,
--     Loading = 16,
--     Range = 32,
--     Reach = 64,
--     Lance = 128,
--     Net = 256,
--     Thrown = 512,
--     Twohanded = 1024,
--     Versatile = 2048,
--     Melee = 4096,
--     Dippable = 8192,
--     Torch = 16384,
--     NoDualWield = 32768,
--     Magical = 65536,
--     NeedDualWieldingBoost = 131072,
--     NotSheathable = 262144,
--     Unstowable = 524288,
--     AddToHotbar = 1048576,
-- }

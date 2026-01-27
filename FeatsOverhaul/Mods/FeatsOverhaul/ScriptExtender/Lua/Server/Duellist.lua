Ext.Vars.RegisterModVariable(ModuleUUID, "WeaponPropertyTracker", {})

-- Apply any changes to weapon properties (i.e. Versatile being removed) on session load, as changes to weapon properties would otherwise by overwritten by the weapon's stats entry
local function initializeweaponProperties()
    ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    if next(ModVars) ~= nil then
        -- Apply stored weapon properties
        for uuid, property in pairs(ModVars) do
            local entity = Ext.Entity.Get(uuid)
            entity.Weapon.WeaponProperties = property
        end
        -- -- Debugging (note: can't get display name since getNameFromGuid() uses Osiris calls but those are apparently not available on SessionLoaded))
        -- _P(string.format("[FeatsOverhaul] [initializeweaponProperties()] ModVars Dump =>"))
        -- for uuid, property in pairs(ModVars) do
        --     local entity = Ext.Entity.Get(uuid)
        --     _P(string.format("| Stored UUID: '%s' | Stored Weapon Properties: '%s'",
        --         uuid, property))
        -- end
    end
end

Ext.Events.SessionLoaded:Subscribe(initializeweaponProperties)

-- Remove Versatile property from weapon
local function removeVersatile(weapon)
    -- Returns as bit flags (decimal)
    local weaponProperties = weapon.Weapon.WeaponProperties
    local weaponProperties_New = {}
    -- Remove Versatile property (=2048 in decimal form under WeaponFlags)
    weaponProperties_New = weaponProperties & ~2048
    weapon.Weapon.WeaponProperties = weaponProperties_New
    -- Stores the new properties to the weapon entity in the mod variable
    local entityUUID = weapon.Uuid["EntityUuid"]
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    ModVars[entityUUID] = weaponProperties_New
    Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")
    -- -- Debugging
    -- local displayName = getNameFromGuid(entityUUID)
    -- _P(string.format("[FeatsOverhaul] [removeVersatile()] =>"))
    -- _P(string.format("| Weapon: '%s' ('%s')", displayName, entityUUID))
    -- _P(string.format("| Old Weapon Properties: '%s'", weaponProperties))
    -- _P(string.format("| New Weapon Properties: '%s'", weaponProperties_New))
    -- _P(string.format("| ModVars After RemoveVersatile()"))
    -- for uuid, property in pairs(ModVars) do
    --     _P(string.format("| -> Weapon: '%s' | UUID: '%s' | Stored Properties: '%s'", getNameFromGuid(uuid), uuid,
    --         property))
    -- end
end

-- Restore Versatile property to weapon
local function restoreVersatile(weapon)
    -- Returns as bit flags (decimal)
    local weaponProperties = weapon.Weapon.WeaponProperties
    local weaponProperties_New = {}
    -- Add Versatile property (=2048 in decimal form under WeaponFlags)
    weaponProperties_New = weaponProperties + 2048
    weapon.Weapon.WeaponProperties = weaponProperties_New
    -- Remove the weapon's entry in the mod variables table
    local entityUUID = weapon.Uuid["EntityUuid"]
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    for uuid, _ in pairs(ModVars) do
        function table.removekey(table, key)
            local element = table[key]
            table[key] = nil
            return element
        end

        if uuid == entityUUID then
            table.removekey(ModVars, uuid)
            Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
        end
    end
    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")
    -- -- Debugging
    -- local displayName = getNameFromGuid(entityUUID)
    -- _P(string.format("[FeatsOverhaul] [restoreVersatile()] =>"))
    -- _P(string.format("| Weapon: '%s' ('%s')", displayName, entityUUID))
    -- _P(string.format("| Old Weapon Properties: '%s'", weaponProperties))
    -- _P(string.format("| New Weapon Properties: '%s'", weaponProperties_New))
    -- _P(string.format("| ModVars After RestoreVersatile()"))
    -- if next(ModVars) == nil then
    --     _P("| -> ModVars is empty")
    -- else
    --     for uuid, property in pairs(ModVars) do
    --         _P(string.format(
    --             "| -> Weapon: '%s' | UUID: '%s' | Stored Properties: '%s'",
    --             getNameFromGuid(uuid), uuid, property
    --         ))
    --     end
    -- end
end

-- Listening for the remove Versatile status being applied to the weapon
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(weapon, status, _, _)
    local weaponEntity = Ext.Entity.Get(weapon)
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        removeVersatile(weaponEntity)
    end
end)

-- Listening for the remove Versatile status being removed from the weapon (not listening for the restore Versatile helper status being applied, to also catch long rests which remove the main status but don't apply that helper status)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(weapon, status, _, _)
    local weaponEntity = Ext.Entity.Get(weapon)
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
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

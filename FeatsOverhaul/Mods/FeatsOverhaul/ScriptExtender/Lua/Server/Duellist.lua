Ext.Vars.RegisterModVariable(ModuleUUID, "WeaponPropertyTracker", {})

-- Apply any changes to weapon properties (i.e. Versatile being removed) on session load, as changes to weapon properties would otherwise by overwritten by the weapon's stats entry
local function InitializeWeaponProperties()
    ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    if next(ModVars) ~= nil then
        -- Apply stored weapon properties
        for uuid, property in pairs(ModVars) do
            local entity = Ext.Entity.Get(uuid)
            if entity and entity.Weapon then
                entity.Weapon.WeaponProperties = property
            else
                Ext.Utils.Print("FeatsOverhaul: [InitializeWeaponProperties] Warning: UUID exists in ModVars but entity not found:", uuid)
            end
        end

        -- -- Debugging
        -- Ext.Utils.Print("=== FeatsOverhaul:InitializeWeaponProperties(): ModVars Dump ===")
        -- for uuid, property in pairs(ModVars) do
        --     Ext.Utils.Print("Stored UUID:", uuid, "Stored WeaponProperties:", property)
        --     local entity = Ext.Entity.Get(uuid)
        --     if entity and entity.Weapon then
        --         Ext.Utils.Print("  → Current in-game WeaponProperties:", entity.Weapon.WeaponProperties)
        --     else
        --         Ext.Utils.Print("  → Warning: Entity not found or has no Weapon component")
        --     end
        -- end
        -- Ext.Utils.Print("=== End ModVars Dump ===")
    end
end

Ext.Events.SessionLoaded:Subscribe(InitializeWeaponProperties)

-- Remove Versatile property from weapon
local function RemoveVersatile(weapon)
    -- Returns as bit flags (decimal)
    local WeaponProperties = weapon.Weapon.WeaponProperties
    local WeaponPropertiesNew = {}
    -- Remove Versatile property (=2048 in decimal form under WeaponFlags)
    WeaponPropertiesNew = WeaponProperties & ~2048
    weapon.Weapon.WeaponProperties = WeaponPropertiesNew
    -- Stores the new properties to the weapon entity in the mod variable
    EntityUUID = weapon.Uuid["EntityUuid"]
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    ModVars[EntityUUID] = WeaponPropertiesNew
    Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")

    -- -- Debugging
    -- Ext.Utils.Print("=== FeatsOverhaul: RemoveVersatile() Called ===")
    -- Ext.Utils.Print("Entity UUID:", EntityUUID)
    -- Ext.Utils.Print("Old WeaponProperties:", WeaponProperties)
    -- Ext.Utils.Print("New WeaponProperties:", WeaponPropertiesNew)
    -- Ext.Utils.Print("ModVars After RemoveVersatile")
    -- for uuid, prop in pairs(ModVars) do
    --     Ext.Utils.Print("UUID:", uuid, "Stored Properties:", prop)
    -- end
    -- Ext.Utils.Print("=== End RemoveVersatile ===")
end

-- Restore Versatile property to weapon
local function RestoreVersatile(weapon)
    -- Returns as bit flags (decimal)
    local WeaponProperties = weapon.Weapon.WeaponProperties
    local WeaponPropertiesNew = {}
    -- Add Versatile property (=2048 in decimal form under WeaponFlags)
    WeaponPropertiesNew = WeaponProperties + 2048
    weapon.Weapon.WeaponProperties = WeaponPropertiesNew
    -- Remove the weapon's entry in the mod variables table
    EntityUUID = weapon.Uuid["EntityUuid"]
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    for uuid, _ in pairs(ModVars) do
        function table.removekey(table, key)
            local element = table[key]
            table[key] = nil
            return element
        end

        if uuid == EntityUUID then
            table.removekey(ModVars, uuid)
            Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
        end
    end
    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")

    -- -- Debugging
    -- Ext.Utils.Print("=== FeatsOverhaul: RestoreVersatile() Called ===")
    -- Ext.Utils.Print("Entity UUID:", EntityUUID)
    -- Ext.Utils.Print("Old WeaponProperties:", WeaponProperties)
    -- Ext.Utils.Print("New WeaponProperties:", WeaponPropertiesNew)
    -- Ext.Utils.Print("ModVars After RestoreVersatile")
    -- for uuid, prop in pairs(ModVars) do
    --     Ext.Utils.Print("UUID:", uuid, "Stored Properties:", prop)
    -- end
    -- Ext.Utils.Print("=== End RestoreVersatile ===")
end

-- Listening for the remove Versatile status being applied to the weapon
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(weapon, status, _, _)
    local WeaponEntity = Ext.Entity.Get(weapon)
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        RemoveVersatile(WeaponEntity)
    end
end)

-- Listening for the remove Versatile status being removed from the weapon (not listening for the restore Versatile helper status being applied, to also catch long rests which remove the main status but don't apply that helper status)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(weapon, status, _, _)
    local WeaponEntity = Ext.Entity.Get(weapon)
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        RestoreVersatile(WeaponEntity)
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

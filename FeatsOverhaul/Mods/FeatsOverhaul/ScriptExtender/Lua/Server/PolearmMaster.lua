-- =========== Helper functions ===========

---@param weapon item
local function isPolearm(weapon)
    return Osi.IsEquipmentWithProficiency(weapon, "Glaives") == 1
        or Osi.IsEquipmentWithProficiency(weapon, "Halberds") == 1
        or Osi.IsEquipmentWithProficiency(weapon, "Javelins") == 1
        or Osi.IsEquipmentWithProficiency(weapon, "Pikes") == 1
        or Osi.IsEquipmentWithProficiency(weapon, "Quarterstaffs") == 1
        or Osi.IsEquipmentWithProficiency(weapon, "Spears") == 1
        or Osi.IsEquipmentWithProficiency(weapon, "Tridents") == 1
end

---@param weapon item
local function isVersatile(weapon)
    return (Ext.Entity.Get(weapon).Weapon.WeaponProperties & 2048 > 0)
end

-- =========== Applying and removing CHT_REACH_OVERWRITE status ===========

-- Applying CHT_REACH_OVERWRITE
Ext.Osiris.RegisterListener("Equipped", 2, "after", function(item, character)
    -- Listening for when a character without the PAM feat equips an item with the CHT_REACH_OVERWRITE status
    if Osi.HasActiveStatus(item, "CHT_REACH_OVERWRITE") and Osi.HasPassive(character, "PolearmMaster_AttackOfOpportunity") == 0 then
        Osi.RemoveStatus(item, "CHT_REACH_OVERWRITE")
    end
    -- Listening for when an off-hand melee slot is equipped on a character who already has a weapon with the CHT_REACH_OVERWRITE status active
    if Osi.GetEquipmentSlotForItem(item) == 4 then
        local mainHandWeapon = Osi.GetEquippedItem(character, "Melee Main Weapon")
        if Osi.HasActiveStatus(mainHandWeapon, "CHT_REACH_OVERWRITE") then
            Osi.RemoveStatus(mainHandWeapon, "CHT_REACH_OVERWRITE")
        end
    end
end)

-- Removing CHT_REACH_OVERWRITE
Ext.Osiris.RegisterListener("Unequipped", 2, "after", function(item, character)
    -- Listening for when a weapon with the CHT_REACH_OVERWRITE status is unequipped
    if Osi.HasActiveStatus(item, "CHT_REACH_OVERWRITE") then
        Osi.RemoveStatus(item, "CHT_REACH_OVERWRITE")
    end
    -- Listening for when an off-hand melee slot is unequipped when the character has the PAM feat and their main-hand weapon is eligible for the Reach status
    if Osi.GetEquipmentSlotForItem(item) == 4 then
        local mainHandWeapon = Osi.GetEquippedItem(character, "Melee Main Weapon")
        if mainHandWeapon and Osi.HasPassive(character, "PolearmMaster_AttackOfOpportunity") == 1 and isPolearm(mainHandWeapon) and isVersatile(mainHandWeapon) then
            Osi.ApplyStatus(mainHandWeapon, "CHT_REACH_OVERWRITE", -1, 0, character)
        end
    end
end)

-- =========== Dynamically adjusting weapon range when CHT_REACH_OVERWRITE status is applied ===========

statusAppliedHandler = Ext.Osiris.RegisterListener("StatusApplied", 4, "after",
    function(weapon, status, causee, storyId)
        if (status ~= "CHT_REACH_OVERWRITE") then
            return
        end
        entity = Ext.Entity.Get(weapon)
        -- If there's no entity found, or no weapon property, do nothing
        if (not entity or not entity["Weapon"]) then
            return
        end
        -- Update the WeaponRange property
        -- Note: Stats use hundreds e.g. 150, but calculated on entity it ends up as 1.50
        local defaultMeleeRange = tonumber(Ext.Stats.Get("_BaseWeapon")["WeaponRange"]) / 100 or 1.50
        local defaultReachRange = tonumber(Ext.Stats.Get("WPN_Pike")["WeaponRange"]) / 100 or 2.50
        local oldRange = entity["Weapon"]["WeaponRange"]
        entity["Weapon"]["WeaponRange"] = defaultReachRange
        entity:Replicate("Weapon") -- Update/sync clients
        -- -- Debugging
        -- local displayName = getNameFromGuid(weapon)
        -- _P(string.format("[FeatsOverhaul] '%s' Applied =>", status))
        -- _P(string.format("| Weapon: '%s' (%s)", displayName, weapon))
        -- _P(string.format("| WeaponRange: %s -> %s", oldRange, string.format("%.2f", entity["Weapon"]["WeaponRange"])))
    end)

statusRemovedHandler = Ext.Osiris.RegisterListener("StatusRemoved", 4, "after",
    function(weapon, status, causee, storyId)
        -- If it's not the relevant status, do nothing
        if (status ~= "CHT_REACH_OVERWRITE") then
            return
        end
        entity = Ext.Entity.Get(weapon)
        entityStatsId = entity["Data"]["StatsId"]
        -- If there's no entity found, or no weapon property, do nothing
        if (not entity or not entity["Weapon"]) then
            return
        end
        -- Update the WeaponRange property
        -- Note: Stats use hundreds e.g. 150, but calculated on entity it ends up as 1.50
        local defaultMeleeRange = tonumber(Ext.Stats.Get("_BaseWeapon")["WeaponRange"]) or 1.50
        local defaultReachRange = tonumber(Ext.Stats.Get("WPN_Pike")["WeaponRange"]) or 2.50
        local oldRange = entity["Weapon"]["WeaponRange"]
        local originalRange = tonumber(Ext.Stats.Get(entityStatsId)["WeaponRange"]) / 100 or defaultMeleeRange
        entity["Weapon"]["WeaponRange"] = originalRange
        entity:Replicate("Weapon") -- Update/sync clients
        -- -- Debugging
        -- local displayName = getNameFromGuid(weapon)
        -- _P(string.format("[FeatsOverhaul] '%s' Removed =>", status))
        -- _P(string.format("| Weapon: '%s' (%s)", displayName, weapon))
        -- _P(string.format("| WeaponRange: %s -> %s", oldRange, string.format("%.2f", entity["Weapon"]["WeaponRange"])))
    end)

---@alias EQUIPMENTSLOT
---| `0` # Helmet
---| `1` # Breast
---| `2` # Cloak
---| `3` # MeleeMainHand
---| `4` # MeleeOffHand
---| `5` # RangedMainHand
---| `6` # RangedOffHand
---| `7` # Ring
---| `8` # Underwear
---| `9` # Boots
---| `10` # Gloves
---| `11` # Amulet
---| `12` # Ring2
---| `13` # Wings
---| `14` # Horns
---| `15` # Overhead
---| `16` # MusicalInstrument
---| `17` # VanityBody
---| `18` # VanityBoots

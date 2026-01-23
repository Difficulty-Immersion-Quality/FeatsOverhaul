
---@param weapon item
local function IsPolearm(weapon)
    return Osi.IsEquipmentWithProficiency(weapon, "Glaives") == 1
    or Osi.IsEquipmentWithProficiency(weapon, "Halberds") == 1
    or Osi.IsEquipmentWithProficiency(weapon, "Javelins") == 1
    or Osi.IsEquipmentWithProficiency(weapon, "Pikes") == 1
    or Osi.IsEquipmentWithProficiency(weapon, "Quarterstaffs") == 1
    or Osi.IsEquipmentWithProficiency(weapon, "Spears") == 1
    or Osi.IsEquipmentWithProficiency(weapon, "Tridents") == 1
end

---@param weapon item
local function IsVersatile(weapon)
    return (Ext.Entity.Get(weapon).Weapon.WeaponProperties & 2048 > 0)
end

Ext.Osiris.RegisterListener("Unequipped", 2, "after", function(item, character)
    -- Listening for when a weapon with the CHT_REACH_OVERWRITE status is unequipped
    if Osi.HasActiveStatus(item, "CHT_REACH_OVERWRITE") then
        Osi.RemoveStatus(item, "CHT_REACH_OVERWRITE")
    end
    -- Listening for when an off-hand melee slot is unequipped when the character has the PAM feat and their main-hand weapon is eligible for the Reach status
    if Osi.GetEquipmentSlotForItem(item) == 4 then
        local MainHandWeapon = Osi.GetEquippedItem(character, "Melee Main Weapon")
        if MainHandWeapon and Osi.HasPassive(character, "PolearmMaster_AttackOfOpportunity") == 1 and IsPolearm(MainHandWeapon) and IsVersatile(MainHandWeapon) then
            Osi.ApplyStatus(MainHandWeapon, "CHT_REACH_OVERWRITE", -1, 0, character)
        end
    end
end)

Ext.Osiris.RegisterListener("Equipped", 2, "after", function(item, character)
    -- Listening for when a character without the PAM feat equips an item with the CHT_REACH_OVERWRITE status
    if Osi.HasActiveStatus(item, "CHT_REACH_OVERWRITE") and Osi.HasPassive(character, "PolearmMaster_AttackOfOpportunity") == 0 then
        Osi.RemoveStatus(item, "CHT_REACH_OVERWRITE")
    end
    -- Listening for when an off-hand melee slot is equipped on a character who already has a weapon with the CHT_REACH_OVERWRITE status active
    if Osi.GetEquipmentSlotForItem(item) == 4 then 
        local MainHandWeapon = Osi.GetEquippedItem(character, "Melee Main Weapon")
        if Osi.HasActiveStatus(MainHandWeapon, "CHT_REACH_OVERWRITE") then
            Osi.RemoveStatus(MainHandWeapon, "CHT_REACH_OVERWRITE")
        end
    end
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
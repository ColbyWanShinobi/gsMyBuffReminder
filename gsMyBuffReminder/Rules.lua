--[[
===============================================================================
 gsMyBuffReminder rule-authoring reference
===============================================================================

Classes use the non-localized UnitClass("player") file token shown below. The
numeric value is the classID returned as UnitClass's third result; rules should
use the token, not the number.

  1  WARRIOR       2  PALADIN       3  HUNTER        4  ROGUE
  5  PRIEST        6  DEATHKNIGHT   7  SHAMAN        8  MAGE
  9  WARLOCK      10  MONK         11  DRUID        12  DEMONHUNTER
 13  EVOKER

Specialization IDs (the first value returned by GetSpecializationInfo):

   71 Arms Warrior             72 Fury Warrior             73 Protection Warrior
   65 Holy Paladin             66 Protection Paladin       70 Retribution Paladin
  253 Beast Mastery Hunter    254 Marksmanship Hunter     255 Survival Hunter
  259 Assassination Rogue     260 Outlaw Rogue            261 Subtlety Rogue
  256 Discipline Priest       257 Holy Priest             258 Shadow Priest
  250 Blood Death Knight     251 Frost Death Knight      252 Unholy Death Knight
  262 Elemental Shaman       263 Enhancement Shaman      264 Restoration Shaman
   62 Arcane Mage              63 Fire Mage                64 Frost Mage
  265 Affliction Warlock     266 Demonology Warlock      267 Destruction Warlock
  268 Brewmaster Monk        269 Windwalker Monk         270 Mistweaver Monk
  102 Balance Druid          103 Feral Druid             104 Guardian Druid
  105 Restoration Druid
  577 Havoc Demon Hunter     581 Vengeance Demon Hunter
 1467 Devastation Evoker    1468 Preservation Evoker    1473 Augmentation Evoker

Starter-rule spell IDs:

  1126 Mark of the Wild           192106 Lightning Shield
 33757 Windfury Weapon            318038 Flametongue Weapon
   974 Earth Shield                   465 Devotion Aura
 32223 Crusader Aura              183435 Retribution Aura
317920 Concentration Aura

Weapon-enchant IDs used by GetWeaponEnchantInfo (not spell IDs):

 5401 Windfury Weapon             5400 Flametongue Weapon

To add a built-in rule, append a table to ns.DefaultRules. `classes`, `specs`,
and `races` are optional sets. Example:

  { name = "Example", spellID = 12345, classes = { MAGE = true },
    specs = { [62] = true }, races = { VoidElf = true } }
===============================================================================
]]

local ADDON_NAME, ns = ...

-- Add defaults here. All spell/aura matching is by numeric SpellID, never by
-- localized spell name. A rule may use spellID (normal aura), auraSpellIDs
-- (alternate displayed-aura IDs), weaponEnchant (main, off, or either), or
-- anySpellIDs (at least one active aura is required).
-- classes/specs/races are optional sets; omitting one applies to all of them.
ns.DefaultRules = {

	{
		key = "druid_mark_of_the_wild",
		name = "Mark of the Wild",
		spellID = 1126,
		classes = { DRUID = true },
	},
	{
		key = "shaman_lightning_shield",
		name = "Lightning Shield",
		spellID = 192106,
		auraSpellIDs = { 192106, 324 }, -- Retail and legacy displayed-aura IDs
		classes = { SHAMAN = true },
		specs = { [263] = true }, -- Enhancement
	},
	{
		key = "shaman_windfury_weapon",
		name = "Windfury Weapon",
		spellID = 33757,
		classes = { SHAMAN = true },
		specs = { [263] = true },
		weaponEnchant = { slot = "main", enchantID = 5401 },
	},
	{
		key = "shaman_flametongue_weapon",
		name = "Flametongue Weapon",
		spellID = 318038,
		classes = { SHAMAN = true },
		specs = { [263] = true },
		weaponEnchant = { slot = "off", enchantID = 5400 },
	},
	{
		key = "shaman_earth_shield",
		name = "Earth Shield",
		spellID = 974,
		-- Elemental Orbit has used a distinct self-aura ID on some client builds.
		auraSpellIDs = { 974, 383648 },
		classes = { SHAMAN = true },
		specs = { [263] = true },
		requiresKnownSpell = true,
	},
	{
		key = "paladin_aura",
		name = "Paladin Aura",
		anySpellIDs = { 465, 32223, 183435, 317920 }, -- Devotion, Crusader, Retribution, Concentration
		classes = { PALADIN = true },
		specs = { [65] = true, [66] = true }, -- Holy, Protection
	},
	{
		key = "retribution_devotion_aura",
		name = "Devotion Aura",
		spellID = 465,
		classes = { PALADIN = true },
		specs = { [70] = true }, -- Retribution
	},
}

function ns.RuleApplies(rule, class, specID, race)
	return (not rule.classes or rule.classes[class])
		and (not rule.specs or rule.specs[specID])
		and (not rule.races or rule.races[race])
end

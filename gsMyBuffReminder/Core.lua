local ADDON_NAME, ns = ...
local frame = CreateFrame("Frame")
ns.frame = frame

local defaults = {
	enabled = true,
	showVisual = true,
	playSound = true,
	alertSound = "raid_warning",
	flashIcons = false,
	includeToyBuffs = true,
	onlyOutOfCombat = false,
	customRules = {},
	editModePositions = {},
}

ns.AlertSounds = {
	{ key = "none", label = "None", soundID = nil },
	{ key = "raid_warning", label = "Raid Warning", soundID = SOUNDKIT.RAID_WARNING },
	{ key = "alarm_1", label = "Alarm Clock 1", soundID = SOUNDKIT.ALARM_CLOCK_WARNING_1 },
	{ key = "alarm_2", label = "Alarm Clock 2", soundID = SOUNDKIT.ALARM_CLOCK_WARNING_2 },
	{ key = "alarm_3", label = "Alarm Clock 3", soundID = SOUNDKIT.ALARM_CLOCK_WARNING_3 },
	{ key = "boss_emote", label = "Boss Emote Warning", soundID = SOUNDKIT.RAID_BOSS_EMOTE_WARNING },
	{ key = "boss_whisper", label = "Boss Whisper Warning", soundID = SOUNDKIT.UI_RAID_BOSS_WHISPER_WARNING },
	{ key = "quest_complete", label = "Quest Complete", soundID = SOUNDKIT.IG_QUEST_COMPLETE },
	{ key = "gm_warning", label = "GM Chat Warning", soundID = SOUNDKIT.GM_CHAT_WARNING },
}

function ns:GetAlertSound()
	for _, sound in ipairs(self.AlertSounds) do
		if sound.key == self.db.alertSound then return sound end
	end
	return self.AlertSounds[2]
end

local function CopyDefaults(target, source)
	for key, value in pairs(source) do
		if target[key] == nil then
			target[key] = type(value) == "table" and CopyTable(value) or value
		end
	end
end

local function RuleLabel(rule)
	if rule.name and rule.name ~= "" then return rule.name end
	if rule.spellID then return C_Spell.GetSpellName(rule.spellID) or ("Spell " .. rule.spellID) end
	return "Unnamed reminder"
end

local function RuleIcon(rule)
	local id = rule.spellID or (rule.anySpellIDs and rule.anySpellIDs[1])
	return id and C_Spell.GetSpellTexture(id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function AuraPresent(spellID)
	-- Have Blizzard perform the exact SpellID lookup. In Midnight, spellId fields
	-- from enumerated aura tables can be Secret Values and must not be compared
	-- in addon Lua.
	if C_Secrets and C_Secrets.ShouldSpellAuraBeSecret(spellID) then
		return nil -- Unknown: Blizzard has restricted this aura in the current state.
	end

	local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
	if (issecretvalue and issecretvalue(aura)) or (issecrettable and issecrettable(aura)) then
		return nil -- Unknown: do not coerce a Secret Value to "present".
	end
	return aura ~= nil
end

local function HasWeaponEnchant(requirement)
	local hasMain, _, _, mainEnchantID, hasOff, _, _, offEnchantID = GetWeaponEnchantInfo()
	if requirement.slot == "main" then return hasMain and mainEnchantID == requirement.enchantID end
	if requirement.slot == "off" then return hasOff and offEnchantID == requirement.enchantID end
	return (hasMain and mainEnchantID == requirement.enchantID) or (hasOff and offEnchantID == requirement.enchantID)
end

function ns:IsRuleAvailable(rule)
	local isKnown = C_SpellBook and C_SpellBook.IsSpellKnown or IsPlayerSpell
	if rule.requiresKnownSpell and not isKnown(rule.spellID) then return false end
	if rule.toyID and (not self.db.includeToyBuffs or not PlayerHasToy(rule.toyID)) then return false end
	return true
end

function ns:GetCurrentSpecID()
	local getSpecialization = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
	local getSpecializationInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo
	local specIndex = getSpecialization()
	return specIndex and getSpecializationInfo(specIndex) or nil
end

function ns:IsRuleSatisfied(rule)
	if rule.weaponEnchant then return HasWeaponEnchant(rule.weaponEnchant) end
	if rule.auraSpellIDs then
		local hasUnknownAura = false
		for _, spellID in ipairs(rule.auraSpellIDs) do
			local present = AuraPresent(spellID)
			if present == true then return true end
			if present == nil then hasUnknownAura = true end
		end
		if hasUnknownAura then return nil end
		return false
	end
	if rule.anySpellIDs then
		local hasUnknownAura = false
		for _, spellID in ipairs(rule.anySpellIDs) do
			local present = AuraPresent(spellID)
			if present == true then return true end
			if present == nil then hasUnknownAura = true end
		end
		if hasUnknownAura then return nil end
		return false
	end
	if rule.spellID then return AuraPresent(rule.spellID) end
	return true
end

function ns:GetMissingRules()
	local _, class = UnitClass("player")
	local specID = self:GetCurrentSpecID()
	local race = select(2, UnitRace("player"))
	local missing = {}
	for _, rule in ipairs(ns.DefaultRules) do
		if ns.RuleApplies(rule, class, specID, race) and self:IsRuleAvailable(rule) and self:IsRuleSatisfied(rule) == false then
			missing[#missing + 1] = rule
		end
	end
	for _, rule in ipairs(self.db.customRules) do
		if ns.RuleApplies(rule, class, specID, race) and self:IsRuleAvailable(rule) and self:IsRuleSatisfied(rule) == false then
			missing[#missing + 1] = rule
		end
	end
	return missing
end

local alert = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
alert:SetSize(280, 42)
local defaultAlertPosition = { point = "TOP", x = 0, y = -180 }
alert:SetPoint(defaultAlertPosition.point, UIParent, defaultAlertPosition.point, defaultAlertPosition.x, defaultAlertPosition.y)
alert:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
alert:SetBackdropColor(0.25, 0, 0, 0.92)
alert:Hide()
ns.alert = alert

alert.editModeLabel = alert:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alert.editModeLabel:SetPoint("CENTER")
alert.editModeLabel:SetText("gsMyBuffReminder")
alert.editModeLabel:Hide()

alert.icons = {}
local function GetIcon(index)
	local icon = alert.icons[index]
	if not icon then
		icon = CreateFrame("Button", nil, alert)
		icon:SetSize(34, 34)
		icon.texture = icon:CreateTexture(nil, "ARTWORK")
		icon.texture:SetAllPoints()
		icon:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetSpellByID(self.spellID); GameTooltip:Show() end)
		icon:SetScript("OnLeave", GameTooltip_Hide)
		alert.icons[index] = icon
	end
	return icon
end

function ns:StopIconFlashing()
	alert:SetScript("OnUpdate", nil)
	for _, icon in ipairs(alert.icons) do icon:SetAlpha(1) end
end

function ns:StartIconFlashing()
	if not self.db.flashIcons then
		self:StopIconFlashing()
		return
	end

	self:StopIconFlashing()
	self.flashElapsed = 0
	alert:SetScript("OnUpdate", function(_, elapsed)
		if not alert:IsShown() or not ns.db.flashIcons then
			ns:StopIconFlashing()
			return
		end
		ns.flashElapsed = ns.flashElapsed + elapsed
		-- A fixed 1.25 Hz sine wave gives a smooth, readable pulse.
		local alpha = 0.3 + 0.7 * ((math.sin(ns.flashElapsed * math.pi * 2 * 1.25) + 1) / 2)
		for _, icon in ipairs(alert.icons) do
			if icon:IsShown() then icon:SetAlpha(alpha) end
		end
	end)
end

function ns:Refresh()
	if self.editModeLib and self.editModeLib:IsInEditMode() then return end
	if not self.db or not self.db.enabled or (self.db.onlyOutOfCombat and InCombatLockdown()) then self:StopIconFlashing(); alert:Hide(); return end
	local missing = self:GetMissingRules()
	local missingKeys = {}
	local hasNewMissingRule = false
	for _, rule in ipairs(missing) do
		local key = rule.key or tostring(rule.spellID or (rule.auraSpellIDs and rule.auraSpellIDs[1]) or (rule.anySpellIDs and rule.anySpellIDs[1]))
		missingKeys[key] = true
		if not self.missingRuleKeys or not self.missingRuleKeys[key] then
			hasNewMissingRule = true
		end
	end
	if not self.db.showVisual or #missing == 0 then self:StopIconFlashing(); alert:Hide() else
		alert:SetWidth(math.max(48, #missing * 40 + 12))
		for i, rule in ipairs(missing) do
			local icon = GetIcon(i); icon:SetPoint("LEFT", alert, "LEFT", 7 + (i - 1) * 40, 0); icon.texture:SetTexture(RuleIcon(rule)); icon.spellID = rule.spellID or rule.anySpellIDs[1]; icon:Show()
		end
		for i = #missing + 1, #alert.icons do alert.icons[i]:Hide() end
		alert:Show()
		self:StartIconFlashing()
	end
	local alertSound = self:GetAlertSound()
	if self.db.playSound and hasNewMissingRule and alertSound.soundID then PlaySound(alertSound.soundID, "Master") end
	self.missingRuleKeys = missingKeys
end

function ns:ApplyEditModePosition(layoutName)
	local position = self.db.editModePositions[layoutName] or defaultAlertPosition
	alert:ClearAllPoints()
	alert:SetPoint(position.point, UIParent, position.point, position.x, position.y)
end

function ns:RegisterEditMode()
	local lib = LibStub and LibStub("LibEditMode", true)
	if not lib then return end

	self.editModeLib = lib
	lib:AddFrame(alert, function(_, layoutName, point, x, y)
		ns.db.editModePositions[layoutName] = { point = point, x = x, y = y }
	end, defaultAlertPosition, "gsMyBuffReminder")
	lib:RegisterCallback("layout", function(layoutName)
		ns:ApplyEditModePosition(layoutName)
	end)
	lib:RegisterCallback("enter", function()
		alert.editModeLabel:Show()
		alert:Show()
	end)
	lib:RegisterCallback("exit", function()
		alert.editModeLabel:Hide()
		ns:Refresh()
	end)
end

function ns:ScheduleRefresh()
	if ns.refreshQueued then return end
	ns.refreshQueued = true
	C_Timer.After(0.05, function()
		ns.refreshQueued = false
		ns:Refresh()
	end)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LOGIN" then
		gsMyBuffReminderDB = gsMyBuffReminderDB or {}; CopyDefaults(gsMyBuffReminderDB, defaults); ns.db = gsMyBuffReminderDB
		ns:RegisterEditMode()
		if ns.CreateOptions then ns:CreateOptions() end
	end
	if (event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED") and unit ~= "player" then return end
	ns:ScheduleRefresh()
end)

SLASH_GSMYBUFFREMINDER1 = "/gsb"
SLASH_GSMYBUFFREMINDER2 = "/gsmybuffreminder"
local function PrintRuleStatus()
	local _, class = UnitClass("player")
	local specID = ns:GetCurrentSpecID()
	print(string.format("gsMyBuffReminder: class=%s, specID=%s", tostring(class), tostring(specID)))
	for _, rule in ipairs(ns.DefaultRules) do
		if not rule.classes or rule.classes[class] then
			local satisfied = ns:IsRuleSatisfied(rule)
			local state = satisfied == nil and "unknown (restricted)" or tostring(satisfied)
			print(string.format("  %s: applies=%s, available=%s, satisfied=%s", RuleLabel(rule), tostring(ns.RuleApplies(rule, class, specID, select(2, UnitRace("player")))), tostring(ns:IsRuleAvailable(rule)), state))
		end
	end
end

SlashCmdList.GSMYBUFFREMINDER = function(message)
	if message and message:lower() == "status" then
		PrintRuleStatus()
		return
	end
	if message and message:lower() == "refresh" then
		ns:Refresh()
		print("gsMyBuffReminder: refreshed")
		return
	end
	if Settings and Settings.OpenToCategory and ns.categoryID then Settings.OpenToCategory(ns.categoryID) end
end

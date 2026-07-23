local ADDON_NAME, ns = ...

local function CheckButton(parent, text, y, get, set)
	local button = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	button:SetPoint("TOPLEFT", 16, y)
	button.Text:SetText(text)
	button:SetScript("OnShow", function(self) self:SetChecked(get()) end)
	button:SetScript("OnClick", function(self) set(self:GetChecked()); ns:Refresh() end)
	return button
end

function ns:CreateOptions()
	local panel = CreateFrame("Frame")
	panel.name = ADDON_NAME
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16); title:SetText("gsMyBuffReminder")
	local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8); help:SetText("Missing buffs display their normal spell icon.  /gsb opens this page.")

	CheckButton(panel, "Enable reminders", -56, function() return ns.db.enabled end, function(v) ns.db.enabled = v end)
	CheckButton(panel, "Show visual reminder", -82, function() return ns.db.showVisual end, function(v) ns.db.showVisual = v end)
	CheckButton(panel, "Play sound when a new reminder appears", -108, function() return ns.db.playSound end, function(v) ns.db.playSound = v end)

	local soundLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	soundLabel:SetPoint("TOPLEFT", 16, -142); soundLabel:SetText("Alert sound")
	local soundDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
	soundDropdown:SetPoint("TOPLEFT", 2, -156)
	UIDropDownMenu_SetWidth(soundDropdown, 180)
	local function RefreshSoundDropdown()
		UIDropDownMenu_SetText(soundDropdown, ns:GetAlertSound().label)
	end
	UIDropDownMenu_Initialize(soundDropdown, function(_, level)
		for _, sound in ipairs(ns.AlertSounds) do
			local option = UIDropDownMenu_CreateInfo()
			option.text = sound.label
			option.checked = ns.db.alertSound == sound.key
			option.func = function()
				ns.db.alertSound = sound.key
				RefreshSoundDropdown()
				if sound.soundID then PlaySound(sound.soundID, "Master") end
			end
			UIDropDownMenu_AddButton(option, level)
		end
	end)

	CheckButton(panel, "Include configured toy-created buffs (only if the toy is owned)", -194, function() return ns.db.includeToyBuffs end, function(v) ns.db.includeToyBuffs = v end)
	CheckButton(panel, "Only remind me out of combat", -220, function() return ns.db.onlyOutOfCombat end, function(v) ns.db.onlyOutOfCombat = v end)
	CheckButton(panel, "Flash missing-buff icons", -246, function() return ns.db.flashIcons end, function(v) ns.db.flashIcons = v end)

	local addTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	addTitle:SetPoint("TOPLEFT", 16, -280); addTitle:SetText("Add a custom buff for this class / spec / race")
	local spellBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	spellBox:SetSize(90, 22); spellBox:SetPoint("TOPLEFT", 16, -305); spellBox:SetAutoFocus(false); spellBox:SetNumeric(true); spellBox:SetTextInsets(6, 6, 0, 0)
	local toyBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	toyBox:SetSize(90, 22); toyBox:SetPoint("LEFT", spellBox, "RIGHT", 55, 0); toyBox:SetAutoFocus(false); toyBox:SetNumeric(true); toyBox:SetTextInsets(6, 6, 0, 0)
	local spellLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall"); spellLabel:SetPoint("BOTTOMLEFT", spellBox, "TOPLEFT", 0, 2); spellLabel:SetText("Aura spell ID")
	local toyLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall"); toyLabel:SetPoint("BOTTOMLEFT", toyBox, "TOPLEFT", 0, 2); toyLabel:SetText("Toy ID (optional)")
	local list = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	list:SetPoint("TOPLEFT", 16, -347); list:SetJustifyH("LEFT")
	local function RefreshList()
		local rows = { "Custom buffs (remove them below by aura spell ID):" }
		for i, rule in ipairs(ns.db.customRules) do rows[#rows + 1] = string.format("|cff66ccff[%d]|r %s%s", i, C_Spell.GetSpellName(rule.spellID) or ("Spell " .. rule.spellID), rule.toyID and (" (toy " .. rule.toyID .. ")") or "") end
		list:SetText(table.concat(rows, "\n"))
	end
	local add = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	add:SetSize(80, 22); add:SetPoint("LEFT", toyBox, "RIGHT", 12, 0); add:SetText("Add")
	add:SetScript("OnClick", function()
		local spellID, toyID = tonumber(spellBox:GetText()), tonumber(toyBox:GetText())
		if spellID and C_Spell.GetSpellName(spellID) then
			local _, class = UnitClass("player")
			local specID = ns:GetCurrentSpecID()
			local race = select(2, UnitRace("player"))
			table.insert(ns.db.customRules, { spellID = spellID, toyID = toyID, classes = { [class] = true }, specs = { [specID] = true }, races = { [race] = true } })
			spellBox:SetText(""); toyBox:SetText(""); RefreshList(); ns:Refresh()
		end
	end)
	local remove = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	remove:SetSize(150, 22); remove:SetPoint("TOPLEFT", 16, -465); remove:SetText("Remove custom spell ID")
	local removeBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	removeBox:SetSize(90, 22); removeBox:SetPoint("LEFT", remove, "RIGHT", 10, 0); removeBox:SetAutoFocus(false); removeBox:SetNumeric(true)
	remove:SetScript("OnClick", function()
		local id = tonumber(removeBox:GetText()); for i = #ns.db.customRules, 1, -1 do if ns.db.customRules[i].spellID == id then table.remove(ns.db.customRules, i) end end; RefreshList(); ns:Refresh()
	end)
	panel:SetScript("OnShow", function() RefreshList(); RefreshSoundDropdown() end)
	local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
	Settings.RegisterAddOnCategory(category)
	ns.categoryID = category:GetID()
end

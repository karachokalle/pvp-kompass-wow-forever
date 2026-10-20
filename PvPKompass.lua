local DATA = PvPKompassData
local currentClass, currentTree, currentTab

local tabs = {
    { key = "stats", label = "Werte" },
    { key = "consumables", label = "Verbrauch" },
    { key = "gear", label = "BiS / Ausrüstung" },
    { key = "talents", label = "Kern-Talente" },
    { key = "vendors", label = "PvP-Händler" },
}

local frame = CreateFrame("Frame", "PvPKompassFrame", UIParent, "BackdropTemplate")
frame:SetSize(950, 700)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("DIALOG")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(0.035, 0.045, 0.07, 0.97)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -16)
title:SetText("PvP-Kompass · WoW Forever")

local classLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
classLine:SetPoint("TOPLEFT", 22, -45)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -4, -4)

local updateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
updateButton:SetSize(154, 24)
updateButton:SetPoint("TOPRIGHT", -48, -12)
updateButton:SetText("Daten aktualisieren")
updateButton:SetScript("OnClick", function()
    PvPKompass_UpdateRequested = true
    print("|cff33ff99PvP-Kompass:|r Update vorgemerkt. Spiel vollständig schließen und danach den externen PvP-Kompass-Updater starten.")
end)

local classButtons, treeButtons, tabButtons = {}, {}, {}

local classHeading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
classHeading:SetPoint("TOPLEFT", 24, -77)
classHeading:SetText("Klasse")

local classList = CreateFrame("Frame", nil, frame)
classList:SetPoint("TOPLEFT", 20, -96)
classList:SetSize(150, 400)

local classContent = CreateFrame("Frame", nil, frame)
classContent:SetPoint("TOPLEFT", classList, "TOPRIGHT", 10, 0)
classContent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)

local treeHeading = classContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
treeHeading:SetPoint("TOPLEFT", 10, -1)
treeHeading:SetText("Talentbaum")

local tabRow = CreateFrame("Frame", nil, classContent)
tabRow:SetPoint("TOPLEFT", 4, -26)
tabRow:SetSize(740, 32)

local scroll = CreateFrame("ScrollFrame", nil, classContent, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 8, -70)
scroll:SetPoint("BOTTOMRIGHT", -30, 45)
local scrollChild = CreateFrame("Frame", nil, scroll)
scrollChild:SetSize(590, 800)
scroll:SetScrollChild(scrollChild)

local body = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
body:SetPoint("TOPLEFT", 0, 0)
body:SetWidth(570)
body:SetJustifyH("LEFT")
body:SetJustifyV("TOP")
body:SetWordWrap(true)
body:SetSpacing(2)

local sourceLabel = classContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sourceLabel:SetPoint("BOTTOMLEFT", 12, 20)
sourceLabel:SetText("Quelle (markieren und kopieren):")

local sourceBox = CreateFrame("EditBox", nil, classContent, "InputBoxTemplate")
sourceBox:SetSize(540, 24)
sourceBox:SetPoint("BOTTOMLEFT", 12, 0)
sourceBox:SetAutoFocus(false)
sourceBox:SetTextInsets(6, 6, 0, 0)
sourceBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
sourceBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)

local gearStage = CreateFrame("Frame", nil, classContent)
gearStage:SetPoint("TOPLEFT", 8, -70)
gearStage:SetPoint("BOTTOMRIGHT", -22, 30)
gearStage:Hide()
local gearModeButtons = {}
local gearWidgets = {}
local gearLabels = {}
local gearMode = "BiS"
local consumableWidgets = {}
local consumableLabels = {}

local GEAR_SLOTS = {
    { key = "Head", label = "Kopf", token = "HeadSlot", column = 1, row = 1 },
    { key = "Neck", label = "Hals", token = "NeckSlot", column = 1, row = 2 },
    { key = "Shoulder", label = "Schultern", token = "ShoulderSlot", column = 1, row = 3 },
    { key = "Back", label = "Rücken", token = "BackSlot", column = 1, row = 4 },
    { key = "Chest", label = "Brust", token = "ChestSlot", column = 1, row = 5 },
    { key = "Shirt", label = "Hemd", token = "ShirtSlot", column = 1, row = 6 },
    { key = "Tabard", label = "Wappenrock", token = "TabardSlot", column = 1, row = 7 },
    { key = "Wrist", label = "Handgelenke", token = "WristSlot", column = 1, row = 8 },
    { key = "Finger1", label = "Ring 1", token = "Finger0Slot", column = 1, row = 9 },
    { key = "Finger2", label = "Ring 2", token = "Finger1Slot", column = 1, row = 10 },
    { key = "Hands", label = "Hände", token = "HandsSlot", column = 2, row = 1 },
    { key = "Waist", label = "Taille", token = "WaistSlot", column = 2, row = 2 },
    { key = "Legs", label = "Beine", token = "LegsSlot", column = 2, row = 3 },
    { key = "Feet", label = "Füße", token = "FeetSlot", column = 2, row = 4 },
    { key = "Trinket1", label = "Schmuckstück 1", token = "Trinket0Slot", column = 2, row = 5 },
    { key = "Trinket2", label = "Schmuckstück 2", token = "Trinket1Slot", column = 2, row = 6 },
    { key = "MainHand", label = "Waffenhand", token = "MainHandSlot", column = 2, row = 7 },
    { key = "OffHand", label = "Nebenhand", token = "SecondaryHandSlot", column = 2, row = 8 },
    { key = "Ranged", label = "Distanzwaffe", token = "RangedSlot", column = 2, row = 9 },
}

local function ClearWidgets(widgets, labels)
    for _, widget in ipairs(widgets) do widget:Hide(); widget:SetParent(nil) end
    for i = #widgets, 1, -1 do widgets[i] = nil end
    for i = #labels, 1, -1 do labels[i]:Hide(); labels[i]:SetParent(nil); labels[i] = nil end
end

local function SlotIcon(slot)
    if GetInventorySlotInfo then
        local _, texture = GetInventorySlotInfo(slot.token)
        if texture then return texture end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function CreateGearCard(slot, item, parent)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(232, 38)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", slot.column == 1 and 0 or 496, -45 - (slot.row - 1) * 42)
    card:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    card:SetBackdropColor(0.06, 0.07, 0.09, 0.88)
    card:EnableMouse(true)
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 3, 0)
    local itemID = item and tonumber(item.itemID)
    local itemName, itemLink, quality, _, _, _, _, _, _, texture
    if itemID and GetItemInfo then itemName, itemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(itemID) end
    if itemID and not texture and C_Item and C_Item.GetItemIconByID then
        local ok, iconID = pcall(C_Item.GetItemIconByID, itemID)
        if ok then texture = iconID end
    end
    icon:SetTexture(texture or (item and item.icon) or SlotIcon(slot))
    local slotText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slotText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -2)
    slotText:SetWidth(188)
    slotText:SetText(slot.label)
    local name = item and (itemName or item.name or (itemID and ("Gegenstand #" .. itemID)) or "Gegenstand nicht bestätigt") or "Keine Daten hinterlegt"
    if item and quality and GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        if r and g and b then name = ("|cff%02x%02x%02x%s|r"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), name) end
    elseif not item then name = "|cff888888" .. name .. "|r" end
    local itemText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -2)
    itemText:SetWidth(188)
    itemText:SetText(name)
    card:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if itemLink then GameTooltip:SetHyperlink(itemLink)
        elseif itemID then GameTooltip:SetHyperlink("item:" .. itemID)
        else GameTooltip:SetText(slot.label) end
        if item then
            if item.source then GameTooltip:AddLine("Quelle: " .. tostring(item.source), 0.75, 0.85, 1, true) end
            if item.stats then GameTooltip:AddLine(tostring(item.stats), 0.85, 0.85, 0.85, true) end
            GameTooltip:AddLine("Shift + Linksklick: am Charakter anprobieren", 0.7, 0.85, 1, true)
        else
            GameTooltip:AddLine("Für diesen Platz sind noch keine bestätigten PvP-Gegenstandsdaten hinterlegt.", 1, 0.8, 0.3, true)
        end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" or not IsShiftKeyDown() or not item then return end
        local link = itemLink or (itemID and ("item:" .. itemID))
        if link and DressUpItemLink then DressUpItemLink(link) elseif itemID and DressUpItem then DressUpItem(itemID) end
    end)
    return card
end

local function RefreshGearStage()
    ClearWidgets(gearWidgets, gearLabels)
    local class = DATA.classes[currentClass]
    local tree = class.trees[currentTree]
    local title = gearStage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 2, -2)
    title:SetText(class.name .. " · " .. tree.name .. " · " .. gearMode)
    gearLabels[#gearLabels + 1] = title
    local hint = gearStage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 4, -23)
    hint:SetText("PvP-Ausrüstung · Gegenstand für Details überfahren")
    gearLabels[#gearLabels + 1] = hint
    local itemsBySlot = {}
    for _, item in ipairs(tree.gear or {}) do if item.slot then itemsBySlot[item.slot] = item end end
    for _, slot in ipairs(GEAR_SLOTS) do
        gearWidgets[#gearWidgets + 1] = CreateGearCard(slot, itemsBySlot[slot.key], gearStage)
    end
    local modelTitle = gearStage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modelTitle:SetPoint("TOP", gearStage, "TOPLEFT", 370, -24)
    modelTitle:SetText("Charaktervorschau")
    gearLabels[#gearLabels + 1] = modelTitle
    local model = CreateFrame("DressUpModel", nil, gearStage, "BackdropTemplate")
    model:SetSize(224, 410)
    model:SetPoint("TOPLEFT", 258, -45)
    model:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 10, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    model:SetBackdropColor(0.025, 0.03, 0.045, 0.72)
    model:SetKeepModelOnHide(true)
    model:SetUnit("player")
    if model.SetSheathed then model:SetSheathed(false) end
    if model.SetFacing then model:SetFacing(0) end
    model:EnableMouse(true)
    model:Show()
    gearWidgets[#gearWidgets + 1] = model
    local footer = gearStage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("TOPLEFT", 4, -465)
    footer:SetWidth(710)
    footer:SetJustifyH("LEFT")
    footer:SetText("Für WoW Forever gibt es derzeit keine bestätigten PvP-" .. gearMode .. "-Gegenstandslisten. Die Slots bleiben als Platzhalter sichtbar, bis belastbare Forever-Empfehlungen vorliegen.")
    gearLabels[#gearLabels + 1] = footer
end

local function RefreshConsumableCards()
    ClearWidgets(gearWidgets, gearLabels)
    local heading = gearStage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 5, -4)
    heading:SetText("PvP-Verbrauchsgegenstände · Beta Stufe " .. DATA.betaLevel)
    gearLabels[#gearLabels + 1] = heading
    for i, item in ipairs(DATA.common.consumables) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local card = CreateFrame("Button", nil, gearStage, "BackdropTemplate")
        card:SetSize(345, 78)
        card:SetPoint("TOPLEFT", 4 + col * 355, -38 - row * 86)
        card:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        card:SetBackdropColor(0.06, 0.07, 0.09, 0.88)
        card:EnableMouse(true)
        card:RegisterForClicks("LeftButtonUp")
        local itemID = tonumber(item.itemID)
        local itemName, itemLink, quality, _, _, _, _, _, _, texture
        if itemID and GetItemInfo then itemName, itemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(itemID) end
        if itemID and not texture and C_Item and C_Item.GetItemIconByID then
            local ok, iconID = pcall(C_Item.GetItemIconByID, itemID)
            if ok then texture = iconID end
        end
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(42, 42)
        icon:SetPoint("LEFT", 8, 0)
        icon:SetTexture(texture or (item.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
        local itemLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemLabel:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
        itemLabel:SetWidth(275)
        itemLabel:SetText(itemName or item.name)
        local detail = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        detail:SetPoint("TOPLEFT", itemLabel, "BOTTOMLEFT", 0, -4)
        detail:SetWidth(275)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(true)
        detail:SetText(item.note)
        card:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if itemLink then GameTooltip:SetHyperlink(itemLink) elseif itemID then GameTooltip:SetHyperlink("item:" .. itemID) else GameTooltip:SetText(item.name) end
            GameTooltip:AddLine(item.category or "PvP-Verbrauch", 0.75, 0.85, 1, true)
            GameTooltip:AddLine(item.note or "", 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function() GameTooltip:Hide() end)
        card:SetScript("OnClick", function(_, button)
            if button == "LeftButton" and IsShiftKeyDown() and itemLink and ChatEdit_InsertLink then
                ChatEdit_InsertLink(itemLink)
            end
        end)
        gearWidgets[#gearWidgets + 1] = card
    end
    local source = gearStage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    source:SetPoint("BOTTOMLEFT", 5, 5)
    source:SetText("Die angezeigten Symbole kommen aus den Client-Itemdaten; Hinweise und Beta-Zahlen: PvP-Vorbereitungs-Guide.")
    gearLabels[#gearLabels + 1] = source
end

for i, mode in ipairs({ "Pre-BiS", "BiS" }) do
    local button = CreateFrame("Button", nil, gearStage, "UIPanelButtonTemplate")
    button:SetSize(86, 24)
    button:SetPoint("TOPLEFT", 520 + (i - 1) * 90, -1)
    button:SetText(mode)
    button.mode = mode
    button:SetScript("OnClick", function(self)
        gearMode = self.mode
        RefreshGearStage()
    end)
    gearModeButtons[i] = button
end

local function SetSource(url)
    sourceBox:SetText(url or "")
end

local vendorPanel = PvPKompassVendors.CreatePanel(classContent, SetSource)
local talentPanel = PvPKompassTalents.CreatePanel(classContent)

local function RefreshClassButtons()
    for _, button in ipairs(classButtons) do
        button:SetEnabled(button.classToken ~= currentClass)
    end
end

local function RefreshTreeButtons()
    local class = DATA.classes[currentClass]
    for i, button in ipairs(treeButtons) do
        local tree = class.trees[i]
        if tree then
            button:SetText(tree.name)
            button:Show()
            button:SetEnabled(i ~= currentTree)
        else
            button:Hide()
        end
    end
end

local function RefreshTabs()
    for _, button in ipairs(tabButtons) do
        button:SetEnabled(button.tabKey ~= currentTab)
    end
end

local function GetPageText()
    local class = DATA.classes[currentClass]
    local tree = class.trees[currentTree]
    if currentTab == "stats" then
        return "|cffffd100Werte · " .. tree.name .. "|r\n\n" .. tree.stats .. "\n\n|cffb9c9dcHinweis|r\n" .. DATA.common.statsNote
    end
    return "|cffffd100Kern-Talente · " .. tree.name .. "|r\n|cffb9c9dcRolle: " .. tree.role .. "|r\n\n" .. tree.talents .. "\n\n|cffb9c9dcTalentpunkte|r\n" .. DATA.common.talentNote
end

local function Refresh()
    if not currentClass then return end
    local class = DATA.classes[currentClass]
    local tree = class.trees[currentTree]
    classLine:SetText("|cffffd100" .. class.name .. "|r  ·  |cffaaaaaa" .. DATA.build .. "|r")
    RefreshClassButtons()
    RefreshTreeButtons()
    RefreshTabs()
    local useCards = currentTab == "gear" or currentTab == "consumables"
    gearStage:SetShown(useCards)
    scroll:SetShown(not useCards and currentTab ~= "vendors" and currentTab ~= "talents")
    vendorPanel:SetShown(currentTab == "vendors")
    talentPanel:SetShown(currentTab == "talents")
    for _, button in ipairs(gearModeButtons) do button:SetShown(currentTab == "gear") end
    if currentTab == "gear" then
        RefreshGearStage()
    elseif currentTab == "consumables" then
        RefreshConsumableCards()
    elseif currentTab == "talents" then
        talentPanel:Refresh(currentClass, currentTree)
    elseif currentTab ~= "vendors" then
        body:SetText(GetPageText())
    end
    if currentTab ~= "vendors" then SetSource(currentTab == "consumables" and DATA.sources.prep
        or currentTab == "gear" and DATA.sources.gear
        or currentTab == "stats" and "https://wow-forever.gg/talents/"
        or class.url) end
    scroll:SetVerticalScroll(0)
end

for index, token in ipairs(DATA.classOrder) do
    local class = DATA.classes[token]
    local button = CreateFrame("Button", nil, classList, "UIPanelButtonTemplate")
    button:SetSize(138, 30)
    button:SetPoint("TOPLEFT", 0, -((index - 1) * 36))
    button:SetText(class.name)
    button.classToken = token
    button:SetScript("OnClick", function(self)
        currentClass = self.classToken
        currentTree = DATA.classes[currentClass].defaultTree
        Refresh()
    end)
    classButtons[#classButtons + 1] = button
end

for i = 1, 3 do
    local button = CreateFrame("Button", nil, classContent, "UIPanelButtonTemplate")
    button:SetSize(150, 28)
    button:SetPoint("TOPLEFT", 95 + ((i - 1) * 158), -1)
    button:SetScript("OnClick", function(self)
        currentTree = self.treeIndex
        Refresh()
    end)
    button.treeIndex = i
    treeButtons[i] = button
end

for i, tab in ipairs(tabs) do
    local button = CreateFrame("Button", nil, tabRow, "UIPanelButtonTemplate")
    button:SetSize(140, 28)
    button:SetPoint("TOPLEFT", (i - 1) * 145, 0)
    button:SetText(tab.label)
    button.tabKey = tab.key
    button:SetScript("OnClick", function(self)
        currentTab = self.tabKey
        Refresh()
    end)
    tabButtons[i] = button
end

local function Toggle()
    if frame:IsShown() then
        frame:Hide()
        return
    end
    local _, token = UnitClass("player")
    currentClass = DATA.classes[token] and token or "WARRIOR"
    currentTree = DATA.classes[currentClass].defaultTree
    currentTab = currentTab or "talents"
    Refresh()
    frame:Show()
end

PvPKompassDB = PvPKompassDB or { minimapAngle = 220 }
PvPKompass_UpdateRequested = PvPKompass_UpdateRequested or false
local minimapButton = CreateFrame("Button", "PvPKompassMinimapButton", Minimap, "BackdropTemplate")
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
minimapIcon:SetSize(24, 24)
minimapIcon:SetPoint("CENTER")
minimapButton.icon = minimapIcon

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("CENTER", 10, -10)

local function PositionMinimapButton()
    local angle = math.rad(tonumber(PvPKompassDB.minimapAngle) or 220)
    local radius = (Minimap:GetWidth() / 2) + 4
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function UpdateMinimapButtonPosition()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local mapX, mapY = Minimap:GetCenter()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    PvPKompassDB.minimapAngle = math.deg(math.atan2(cursorY - mapY, cursorX - mapX))
    PositionMinimapButton()
end

minimapButton:SetScript("OnMouseDown", function(self)
    self.wasDragged = false
end)
minimapButton:SetScript("OnDragStart", function(self)
    self.wasDragged = true
    self:SetScript("OnUpdate", UpdateMinimapButtonPosition)
end)
minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdateMinimapButtonPosition()
end)
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" and not self.wasDragged then Toggle() end
    self.wasDragged = false
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("PvP-Kompass")
    GameTooltip:AddLine("Linksklick: Fenster öffnen/schließen", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Ziehen: Position am Minimaprand ändern", 0.65, 0.8, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
PositionMinimapButton()

SLASH_PVPKOMPASS1 = "/pvpkompass"
SLASH_PVPKOMPASS2 = "/pvpk"
SlashCmdList.PVPKOMPASS = Toggle

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    PositionMinimapButton()
    print("|cff33ff99PvP-Kompass|r für WoW: Forever geladen. Öffnen mit |cffffff00/pvpkompass|r.")
    if PvPKompass_UpdateRequested then
        print("|cffffcc00PvP-Kompass:|r Update angefordert. Starte den externen Updater, wenn das Spiel geschlossen ist.")
    end
end)

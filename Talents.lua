-- Read-only talent browser. Positions and ranks always come from this client.
PvPKompassTalents = {}
local M = PvPKompassTalents
local aliases = {
    WARRIOR = {{"Improved Tactical Mastery", "Verbesserte Taktikbeherrschung", "Spearing Strike", "Mortal Strike", "Tödlicher Stoß"}, {"Raging Blows", "Death Wish", "Todeswunsch"}, {"Iron Will", "Eiserner Wille", "Improved Disarm", "Verbesserte Entwaffnung", "Vanguard"}},
    HUNTER = {{"Intimidation", "Einschüchterung", "Summon Hawk"}, {"Lone Wolf", "Einsamer Wolf"}, {"Entrapment", "Fallen stellen", "Surefooted", "Sicherer Stand", "Strider Kick", "Counterattack", "Gegenangriff"}},
    ROGUE = {{}, {"Endurance", "Durchhaltevermögen", "Hack and Slash"}, {"Premeditation", "Konzentration", "Dirty Tricks", "Schmutzige Tricks", "Initiative"}},
    PRIEST = {{"Soul Warding", "Seelenwehr", "Penance", "Sühne", "Mental Agility", "Mentale Beweglichkeit"}, {"Binding Heal", "Verbindende Heilung", "Twilight Focus"}, {"Silence", "Stille"}},
    SHAMAN = {{"Elemental Alacrity", "Earthbound", "Lava Burst", "Lavaeruption"}, {"Stormstrike", "Sturmschlag", "Improved Ghost Wolf", "Verbesserter Geisterwolf"}, {"Water Shield", "Wasserschild", "Riptide", "Springflut", "Earth Shield", "Erdschild"}},
    MAGE = {{"Improved Counterspell", "Verbesserter Gegenzauber", "Arcane Blast", "Arkanschlag"}, {"Heating Up", "Impact", "Einschlag", "Blast Wave", "Druckwelle"}, {"Ice Lance", "Eislanze", "Ice Block", "Eisblock", "Cold Snap", "Kälteeinbruch"}},
    WARLOCK = {{"Curse of Exhaustion", "Fluch der Erschöpfung", "Malediction", "Verhängnis", "Soul Siphon", "Seelenentzug"}, {"Demonic Sacrifice", "Dämonische Opferung", "Fel Domination", "Teufelsbeherrschung", "Soul Link", "Seelenverbindung"}, {"Bane", "Verderben"}},
    DRUID = {{"Improved Entangling Roots", "Verbesserte Wucherwurzeln", "Overgrowth", "Insect Swarm", "Insektenschwarm"}, {"Feral Charge", "Wilde Attacke", "Shifting Power", "Leader of the Pack", "Rudelführer"}, {"Gift of the Earthmother", "Gabe der Erdenmutter", "Swiftmend", "Rasche Heilung"}},
}
local function normalized(value)
    return (string.lower(value or ""):gsub("[%s%p]", ""))
end
local function isCore(class, tree, name)
    for _, alias in ipairs(aliases[class] and aliases[class][tree] or {}) do
        if normalized(alias) == normalized(name) then return true end
    end
    -- Also recognize the localized names explicitly named in the existing guide.
    local text = PvPKompassData.classes[class].trees[tree].talents
    return #name > 5 and string.find(text, name, 1, true) ~= nil
end
local function call(fn, ...)
    if type(fn) ~= "function" then return end
    local results = {pcall(fn, ...)}
    if results[1] then return unpack(results, 2) end
end
local function readNode(tree, index)
    local info = C_SpecializationInfo and call(C_SpecializationInfo.GetTalentInfo,
        {specializationIndex = tree, talentIndex = index, isInspect = false, isPet = false})
    if type(info) ~= "table" or not info.name then
        local name, icon, tier, column, rank, maxRank = call(GetTalentInfo, tree, index, false, false)
        if not name then return end
        info = {name = name, icon = icon, tier = tier, column = column, rank = rank, maxRank = maxRank}
    end
    if type(info.tier) ~= "number" or type(info.column) ~= "number"
        or info.tier < 1 or info.tier > 20 or info.column < 1 or info.column > 4 then return end
    local prereqs = {call(GetTalentPrereqs, tree, index, false, false)}
    return {name = info.name, icon = info.icon, tier = info.tier, column = info.column,
        rank = info.rank or 0, maxRank = info.maxRank, spellID = info.spellID,
        index = index, tree = tree, prereqs = prereqs}
end
local function signature()
    local version, build, _, interface = GetBuildInfo()
    return tostring(version) .. ":" .. tostring(build) .. ":" .. tostring(interface) .. ":" .. GetLocale()
end
local loadStatus
local requestedPlayerSpells
local function captureTraits()
    if not C_Traits or not C_Traits.GetNodeInfo then return end
    local configID = C_ClassTalents and call(C_ClassTalents.GetActiveConfigID)
    if not configID and C_SpecializationInfo then
        local group = call(C_SpecializationInfo.GetActiveSpecGroup) or 1
        configID = call(C_SpecializationInfo.GetCombatConfigIDForSpecGroup, group)
    end
    if not configID and not requestedPlayerSpells and not (InCombatLockdown and InCombatLockdown()) then
        requestedPlayerSpells = true
        call(C_AddOns and C_AddOns.LoadAddOn or LoadAddOn, "Blizzard_PlayerSpells")
        configID = C_ClassTalents and call(C_ClassTalents.GetActiveConfigID)
        if not configID and C_SpecializationInfo then
            configID = call(C_SpecializationInfo.GetCombatConfigIDForSpecGroup, call(C_SpecializationInfo.GetActiveSpecGroup) or 1)
        end
    end
    if not configID then loadStatus = "Forever-Talentkonfiguration noch nicht verfügbar."; return end
    local config = call(C_Traits.GetConfigInfo, configID)
    if not config or not config.treeIDs then loadStatus = "Forever-Talentkonfiguration wird geladen."; return end
    local result = {signature = signature(), date = date("%d.%m.%Y"), trees = {{}, {}, {}}, backgrounds = {}, format = "traits"}
    local count, seen = 0, {}
    for _, treeID in ipairs(config.treeIDs) do
        local groups = call(C_Traits.GetGroupDisplayInfoByTreeID, treeID) or {}
        table.sort(groups, function(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end)
        local groupMap = {}
        for i, group in ipairs(groups) do if i <= 3 then groupMap[group.groupID] = i end end
        for _, nodeID in ipairs(call(C_Traits.GetTreeNodes, treeID) or {}) do
            local info = call(C_Traits.GetNodeInfo, configID, nodeID)
            if info and info.isVisible ~= false and not seen[nodeID] then
                local tree
                for _, groupID in ipairs(info.groupIDs or {}) do tree = groupMap[groupID] or tree end
                if tree and type(info.posX) == "number" and type(info.posY) == "number" then
                    local entryID = info.activeEntry and info.activeEntry.entryID or (info.entryIDs and info.entryIDs[1])
                    local entry = entryID and call(C_Traits.GetEntryInfo, configID, entryID)
                    local definition = entry and entry.definitionID and call(C_Traits.GetDefinitionInfo, entry.definitionID)
                    if definition then
                        local spell = definition.spellID and C_Spell and call(C_Spell.GetSpellInfo, definition.spellID)
                        local name, _, icon = call(GetSpellInfo, definition.spellID)
                        name = definition.overrideName or (spell and spell.name) or name
                        icon = definition.overrideIcon or (spell and spell.iconID) or icon
                        if name then
                            seen[nodeID], count = true, count + 1
                            result.trees[tree][#result.trees[tree] + 1] = {name = name, icon = icon,
                                spellID = definition.spellID, rank = info.currentRank or info.ranksPurchased or 0,
                                maxRank = info.maxRanks or entry.maxRanks, tree = tree, nodeID = nodeID,
                                configID = configID, entryID = entryID, posX = info.posX, posY = info.posY,
                                edges = info.visibleEdges or {}, description = definition.overrideDescription}
                        end
                    end
                end
            end
        end
    end
    if count == 0 then loadStatus = "Noch keine Forever-Talentknoten geladen. Talentfenster im Spiel einmal öffnen."; return end
    for _, nodes in ipairs(result.trees) do
        if #nodes == 0 then loadStatus = "Forever liefert noch nicht alle drei Talentgruppen. Bitte erneut laden."; return end
        local minX, maxX, minY = math.huge, -math.huge, math.huge
        for _, node in ipairs(nodes) do minX = math.min(minX, node.posX); maxX = math.max(maxX, node.posX); minY = math.min(minY, node.posY) end
        local scale = maxX > minX and 153 / (maxX - minX) or 1
        for _, node in ipairs(nodes) do
            node.x, node.y = 15 + (node.posX - minX) * scale, 44 + (node.posY - minY) * scale
        end
    end
    loadStatus = nil
    return result
end
local function capture()
    local _, token = UnitClass("player")
    if not PvPKompassData.classes[token] then return end
    if C_Traits and C_Traits.GetNodeInfo then
        local traits = captureTraits()
        if not traits then return end
        PvPKompassDB = PvPKompassDB or {}
        PvPKompassDB.talentTrees = PvPKompassDB.talentTrees or {}
        PvPKompassDB.talentTrees[token] = traits
        return traits
    end
    local result = {signature = signature(), date = date("%d.%m.%Y"), trees = {}, backgrounds = {}}
    for tree = 1, 3 do
        local _, _, _, _, _, _, _, background = call(C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo, tree, false, false)
        if not background then
            local a, _, _, _, b, c = call(GetTalentTabInfo, tree, false, false)
            background = type(a) == "number" and c or b
            -- New compatibility wrapper returns background as its sixth value.
        end
        if type(background) == "string" and background ~= "" then result.backgrounds[tree] = background end
        local nodes, occupied, misses = {}, {}, 0
        for index = 1, 100 do
            local node = readNode(tree, index)
            if node then
                local key = node.tier .. ":" .. node.column
                if occupied[key] then break end -- Reject APIs which ignore talentIndex.
                occupied[key], misses = true, 0
                nodes[#nodes + 1] = node
            else
                misses = misses + 1
                if misses >= 5 then break end
            end
        end
        if #nodes < 2 then return end -- Never replace a complete snapshot with an unloaded tree.
        result.trees[tree] = nodes
    end
    PvPKompassDB = PvPKompassDB or {}
    PvPKompassDB.talentTrees = PvPKompassDB.talentTrees or {}
    PvPKompassDB.talentTrees[token] = result
    return result
end
local function font(parent, size, x, y, width)
    local text = parent:CreateFontString(nil, "OVERLAY", size)
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    return text
end
local function tooltip(button)
    local node = button.node
    if not node or not GameTooltip then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local _, ownClass = UnitClass("player")
    local live = button.class == ownClass and button.live
    if live and node.index then call(GameTooltip.SetTalent, GameTooltip, node.tree, node.index, false, false) end
    if GameTooltip:NumLines() == 0 and node.spellID and node.spellID > 0 then
        call(GameTooltip.SetSpellByID, GameTooltip, node.spellID)
    end
    if GameTooltip:NumLines() == 0 then
        GameTooltip:AddLine(node.name, 1, .82, 0)
        GameTooltip:AddLine("Beschreibung derzeit nicht vom Client verfügbar.", 1, 1, 1, true)
    end
    if node.description then GameTooltip:AddLine(node.description, 1, 1, 1, true) end
    GameTooltip:AddLine("Talent-Rang: " .. node.rank .. "/" .. (node.maxRank or "?"), .8, .8, .8)
    if button.core then GameTooltip:AddLine("PvP-Kern-Talent · Empfehlung aus dem Klassenguide", 1, .2, .2, true) end
    if not live then GameTooltip:AddLine("Gespeicherter Baum: Ränge stammen vom zuletzt erfassten Charakter.", .7, .7, .7, true) end
    GameTooltip:Show()
end
function M.CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", 8, -70)
    panel:SetPoint("BOTTOMRIGHT", -12, 40)
    local legend = font(panel, "GameFontHighlightSmall", 4, 0, 710)
    legend:SetText("|cffff4444Roter Rahmen: PvP-Kern-Talent|r · Maus über ein Talent: Tooltip · Zahlen: belegter / maximaler Rang")
    local status = font(panel, "GameFontHighlightSmall", 4, -24, 565)
    local reload = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reload:SetPoint("TOPRIGHT", -24, -18)
    reload:SetSize(120, 22)
    reload:SetText("Neu laden")
    reload:SetScript("OnClick", function() if panel.class then panel:Refresh(panel.class, panel.selected) end end)
    local scroller = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroller:SetPoint("TOPLEFT", 0, -48)
    scroller:SetPoint("BOTTOMRIGHT", -26, 100)
    local content = CreateFrame("Frame", nil, scroller)
    content:SetSize(690, 430)
    scroller:SetScrollChild(content)
    local guideScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    guideScroll:SetPoint("BOTTOMLEFT", 4, 0)
    guideScroll:SetPoint("BOTTOMRIGHT", -26, 0)
    guideScroll:SetHeight(90)
    local guideContent = CreateFrame("Frame", nil, guideScroll)
    guideContent:SetSize(680, 180)
    guideScroll:SetScrollChild(guideContent)
    local guide = font(guideContent, "GameFontHighlightSmall", 0, 0, 675)
    guide:SetSpacing(3)
    local headers, buttons, backgrounds, lines = {}, {}, {}, {}
    for tree = 1, 3 do
        local background = content:CreateTexture(nil, "BACKGROUND")
        background:SetPoint("TOPLEFT", (tree - 1) * 230, 0)
        background:SetSize(224, 1000)
        background:SetColorTexture(.06, .075, .10, .9)
        backgrounds[tree] = {}
        for part = 1, 4 do
            local texture = content:CreateTexture(nil, "BACKGROUND", nil, 1)
            texture:SetPoint("TOPLEFT", (tree - 1) * 230 + ((part - 1) % 2) * 112, -30 - math.floor((part - 1) / 2) * 215)
            texture:SetSize(112, 215)
            texture:SetAlpha(.5)
            backgrounds[tree][part] = texture
        end
        headers[tree] = font(content, "GameFontNormal", (tree - 1) * 230 + 8, -8, 215)
    end
    function panel:Refresh(class, selected)
        self.class, self.selected = class, selected
        if GameTooltip then GameTooltip:Hide() end
        local _, ownClass = UnitClass("player")
        local fresh = class == ownClass and capture() or nil
        self.needsData = class == ownClass and not fresh
        local snapshot = fresh or (PvPKompassDB and PvPKompassDB.talentTrees and PvPKompassDB.talentTrees[class])
        if snapshot and snapshot.signature ~= signature() then snapshot = nil end
        status:SetText(snapshot and ((fresh and "Aktuelle Clientdaten" or "Gespeicherte Clientdaten") .. " · " .. snapshot.date)
            or (class == ownClass and (loadStatus or "Client liefert noch keine Talentdaten. Talentfenster einmal öffnen.") or "Noch keine Baumdaten: Mit dieser Klasse einloggen und das Talentfenster im Spiel öffnen."))
        local classData = PvPKompassData.classes[class]
        guide:SetText("|cffffd100" .. classData.trees[selected].name .. " · PvP-Empfehlung|r\n" .. classData.trees[selected].talents .. "\n\n" .. PvPKompassData.common.talentNote)
        guideContent:SetHeight(math.max(90, guide:GetStringHeight() + 12))
        guideScroll:SetVerticalScroll(0)
        for _, button in ipairs(buttons) do button:Hide() end
        for _, line in ipairs(lines) do line:Hide() end
        local count, maxTier, lineCount, maxBottom = 0, 7, 0, 400
        local function segment(x1, y1, x2, y2)
            lineCount = lineCount + 1
            local line = lines[lineCount] or content:CreateTexture(nil, "BORDER")
            lines[lineCount] = line
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", math.min(x1, x2), -math.min(y1, y2))
            line:SetSize(math.max(2, math.abs(x1 - x2)), math.max(2, math.abs(y1 - y2)))
            line:SetColorTexture(.65, .55, .25, .85)
            line:Show()
        end
        for tree = 1, 3 do
            headers[tree]:SetText((tree == selected and "|cffffd100" or "|cffb9c9dc") .. classData.trees[tree].name .. "|r")
            local bg = snapshot and snapshot.backgrounds and snapshot.backgrounds[tree]
            local suffixes = {"-TopLeft", "-TopRight", "-BottomLeft", "-BottomRight"}
            for part, texture in ipairs(backgrounds[tree]) do
                if bg then texture:SetTexture("Interface/TalentFrame/" .. bg .. suffixes[part]); texture:Show()
                else texture:Hide() end
            end
            local byID = {}
            for _, node in ipairs(snapshot and snapshot.trees[tree] or {}) do if node.nodeID then byID[node.nodeID] = node end end
            for _, node in ipairs(snapshot and snapshot.trees[tree] or {}) do
                for _, edge in ipairs(node.edges or {}) do
                    local target = byID[edge.targetNode]
                    if target then
                        local x1, y1 = (tree - 1) * 230 + node.x + 18, node.y + 18
                        local x2, y2 = (tree - 1) * 230 + target.x + 18, target.y + 18
                        segment(x1, y1, x1, (y1 + y2) / 2)
                        segment(x1, (y1 + y2) / 2, x2, (y1 + y2) / 2)
                        segment(x2, (y1 + y2) / 2, x2, y2)
                    end
                end
                for p = 1, #(node.prereqs or {}), 3 do
                    local row, col = node.prereqs[p], node.prereqs[p + 1]
                    if type(row) == "number" and type(col) == "number" and row >= 1 and row <= 20 and col >= 1 and col <= 4 then
                        local x1, y1 = (tree - 1) * 230 + 33 + (col - 1) * 51, 62 + (row - 1) * 51
                        local x2, y2 = (tree - 1) * 230 + 33 + (node.column - 1) * 51, 62 + (node.tier - 1) * 51
                        segment(x1, y1, x1, (y1 + y2) / 2)
                        segment(x1, (y1 + y2) / 2, x2, (y1 + y2) / 2)
                        segment(x2, (y1 + y2) / 2, x2, y2)
                    end
                end
                count = count + 1
                maxTier = math.max(maxTier, node.tier or 1)
                maxBottom = math.max(maxBottom, (node.y or 0) + 55)
                local button = buttons[count]
                if not button then
                    button = CreateFrame("Button", nil, content, "BackdropTemplate")
                    button:SetSize(36, 36)
                    button:SetBackdrop({edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2})
                    button.icon = button:CreateTexture(nil, "ARTWORK")
                    button.icon:SetPoint("TOPLEFT", 3, -3)
                    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
                    button.rank = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    button.rank:SetPoint("BOTTOMRIGHT", 2, -8)
                    button:SetScript("OnEnter", tooltip)
                    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
                    button:SetScript("OnHide", function(self) if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
                    buttons[count] = button
                end
                button.node, button.class, button.live = node, class, fresh ~= nil
                button.core = isCore(class, tree, node.name)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", (tree - 1) * 230 + (node.x or (15 + (node.column - 1) * 51)), -(node.y or (44 + (node.tier - 1) * 51)))
                button.icon:SetTexture(node.icon or "Interface/Icons/INV_Misc_QuestionMark")
                button.icon:SetDesaturated(node.rank == 0)
                if button.core then button:SetBackdropBorderColor(1, .12, .12, 1)
                elseif node.rank > 0 then button:SetBackdropBorderColor(.2, 1, .2, 1)
                else button:SetBackdropBorderColor(.5, .5, .5, 1) end
                button.rank:SetText(node.rank .. "/" .. (node.maxRank or "?"))
                button:Show()
            end
        end
        content:SetHeight(math.max(maxBottom, 50 + maxTier * 51))
        scroller:SetVerticalScroll(0)
    end
    panel:SetScript("OnEvent", function(self)
        capture()
        if self:IsShown() and self.class then self:Refresh(self.class, self.selected) end
    end)
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "ACTIVE_COMBAT_CONFIG_CHANGED", "SPELLS_CHANGED"}) do
        pcall(panel.RegisterEvent, panel, event)
    end
    local elapsed = 0
    panel:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed > 3 then
            elapsed = 0
            if self.class and self.needsData then self:Refresh(self.class, self.selected) end
        end
    end)
    panel:Hide()
    return panel
end

local API = {}
PvPKompassVendors = API
local catalog = PvPKompassVendorData
local panel, selectedKey, refreshPanel
local merchantOpen, refreshPending = false, false
local factionFilter

-- Forever uses the structured API; older clients expose a tuple instead.
local function MerchantItemInfo(index)
    if C_MerchantFrame and type(C_MerchantFrame.GetItemInfo) == "function" then
        local info = C_MerchantFrame.GetItemInfo(index)
        if info then
            return info.name, info.texture, info.price, info.stackCount,
                info.numAvailable, info.isUsable, info.hasExtendedCost
        end
        return
    end
    if type(GetMerchantItemInfo) == "function" then
        local function Normalize(...)
            local name, texture, price, quantity, stock, sixth, seventh, eighth = ...
            if select("#", ...) >= 8 then
                -- isPurchasable, isUsable, extendedCost
                return name, texture, price, quantity, stock, seventh, eighth
            end
            return name, texture, price, quantity, stock, sixth, seventh
        end
        return Normalize(GetMerchantItemInfo(index))
    end
end

local function Cache()
    PvPKompassDB = PvPKompassDB or {}
    PvPKompassDB.vendors = PvPKompassDB.vendors or {}
    return PvPKompassDB.vendors
end

local function MerchantKey()
    if not merchantOpen then return end
    local guid = UnitGUID("npc")
    local id = guid and tonumber((select(6, strsplit("-", guid))))
    local name = UnitName("npc")
    if not id or not name then return end
    for _, vendor in ipairs(catalog.vendors) do
        if vendor.npcID == id or vendor.name == name then return vendor.key, vendor, id, name end
    end
    return tostring(id), nil, id, name
end

local function MatchesFormat(text, format)
    if not format or format == "" then return false end
    local pattern = format:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    pattern = pattern:gsub("%%%%s", ".+"):gsub("%%%%d", "%%d+")
    return text:match("^" .. pattern .. "$") ~= nil
end

local scanTip = CreateFrame("GameTooltip", "PvPKompassVendorScanTooltip", UIParent, "GameTooltipTemplate")
local function ReadRequirements(index)
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetMerchantItem(index)
    local requirements, reputation = {}, nil
    for i = 2, scanTip:NumLines() do
        local line = _G["PvPKompassVendorScanTooltipTextLeft" .. i]
        local text = line and line:GetText()
        if text then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            if MatchesFormat(text, ITEM_REQ_REPUTATION) then
                reputation = text
                requirements[#requirements + 1] = text
            elseif MatchesFormat(text, ITEM_MIN_LEVEL) or MatchesFormat(text, ITEM_REQ_PVP_RANK)
                or MatchesFormat(text, ITEM_REQ_RANK) or MatchesFormat(text, ITEM_CLASSES_ALLOWED) then
                requirements[#requirements + 1] = text
            end
        end
    end
    scanTip:Hide()
    return requirements, reputation
end

function API.Capture(manual)
    local key, seed, id, name = MerchantKey()
    if not key then return false, "Bitte zuerst das Handelsfenster eines PvP-Händlers öffnen." end
    if not seed and not Cache()[key] and not manual then return false end
    local hasInfo = (C_MerchantFrame and type(C_MerchantFrame.GetItemInfo) == "function")
        or type(GetMerchantItemInfo) == "function"
    if type(GetMerchantNumItems) ~= "function" or not hasInfo then
        local _, build = GetBuildInfo()
        return false, "Händler-Schnittstelle fehlt (Build " .. tostring(build) .. "). Bitte PvP-Kompass aktualisieren."
    end
    local total = GetMerchantNumItems()
    if not total or total < 1 then return false, "Das Sortiment wurde noch nicht vom Client geladen." end
    local items, seen = {}, {}
    local known = {}
    for _, item in ipairs(seed and seed.items or {}) do known[item.itemID] = item end
    local _, build = GetBuildInfo()
    local observedAt = date("%d.%m.%Y %H:%M")
    for index = 1, total do
        local itemName, texture, price, quantity, stock, usable, extended = MerchantItemInfo(index)
        local link = GetMerchantItemLink and GetMerchantItemLink(index)
        local itemID = (link and tonumber(link:match("item:(%d+)")))
            or (GetMerchantItemID and GetMerchantItemID(index))
        if itemName and itemID then
            local requirements, reputation = ReadRequirements(index)
            local costs, costComplete = {}, true
            if extended then
                local count = GetMerchantItemCostInfo and GetMerchantItemCostItem and GetMerchantItemCostInfo(index)
                if not count or count < 1 then costComplete = false end
                for costIndex = 1, (count or 0) do
                    local icon, amount, costLink, currencyName = GetMerchantItemCostItem(index, costIndex)
                    if not amount then costComplete = false end
                    costs[#costs + 1] = { icon = icon, amount = amount, link = costLink, name = currencyName }
                end
            end
            items[#items + 1] = {
                itemID = itemID, name = itemName, link = link, icon = texture,
                money = price, quantity = quantity or 1, stock = stock, costs = costs,
                costComplete = costComplete and price ~= nil, requirements = requirements,
                reputationText = reputation, observed = true, observedAt = observedAt, build = build,
                reputationStanding = known[itemID] and known[itemID].reputationStanding,
                reputationFaction = known[itemID] and known[itemID].reputationFaction,
            }
            seen[itemID] = true
        end
    end
    if #items == 0 then return false, "Gegenstände sind noch nicht geladen. Bitte kurz warten und erneut erfassen." end
    local complete = #items == total and GetMerchantFilter and LE_LOOT_FILTER_ALL ~= nil
        and GetMerchantFilter() == LE_LOOT_FILTER_ALL or false
    -- Preserve known rows when a partial response arrives; only a complete scan replaces the inventory.
    if not complete then
        for _, item in ipairs((Cache()[key] or seed or {}).items or {}) do
            if not seen[item.itemID] then items[#items + 1] = item end
        end
    end
    Cache()[key] = {
        key = key, npcID = id, name = name, faction = UnitFactionGroup("player"),
        location = (GetZoneText() or "") .. " · " .. (GetSubZoneText() or ""),
        reputation = seed and seed.reputation, items = items, complete = complete,
        observedAt = observedAt, build = build, locale = GetLocale(),
        source = "Client · Händlerfenster",
    }
    if manual then selectedKey = key end
    if panel and panel:IsShown() then refreshPanel() end
    return true, #items .. " Gegenstände von " .. name .. " lokal gespeichert."
end

local function AllVendors()
    local vendors, seen = {}, {}
    for _, seed in ipairs(catalog.vendors) do
        local cached = Cache()[seed.key]
        vendors[#vendors + 1] = cached or seed
        seen[seed.key] = true
    end
    for key, cached in pairs(Cache()) do
        if not seen[key] then vendors[#vendors + 1] = cached end
    end
    local own = UnitFactionGroup("player")
    table.sort(vendors, function(a, b)
        if (a.faction == own) ~= (b.faction == own) then return a.faction == own end
        return (a.name or "") < (b.name or "")
    end)
    return vendors
end

local function CostText(item)
    if not item.observed then return "Kosten: noch nicht bestätigt" end
    local parts = {}
    if item.money and item.money > 0 then
        parts[#parts + 1] = GetCoinTextureString and GetCoinTextureString(item.money) or (item.money .. " Kupfer")
    end
    for _, cost in ipairs(item.costs or {}) do
        local name = cost.name or (cost.link and cost.link:match("%[(.-)%]")) or "Währung/Marke"
        local icon = cost.icon and ("|T" .. tostring(cost.icon) .. ":14|t ") or ""
        parts[#parts + 1] = icon .. tostring(cost.amount or "?") .. " " .. name
    end
    if not item.costComplete then parts[#parts + 1] = "Weitere Kosten noch nicht geladen" end
    if #parts == 0 then return "Kosten: " .. (item.costComplete and "kostenlos" or "nicht bekannt") end
    return table.concat(parts, " · ")
end

local function ReputationText(item)
    if item.reputationText then return item.reputationText end
    if item.reputationStanding then
        return "Ruf: " .. (item.reputationFaction or "Fraktion") .. " – " .. (_G["FACTION_STANDING_LABEL" .. item.reputationStanding] or "?")
    end
    -- An empty or not-yet-loaded tooltip is not proof of no reputation requirement.
    return "Ruf: siehe Gegenstands-Tooltip"
end

local function Label(parent, x, y, width, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    return label
end

function API.CreatePanel(parent, setSource)
    panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", 8, -70)
    panel:SetPoint("BOTTOMRIGHT", -22, 34)
    panel:Hide()
    local filter = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    filter:SetSize(174, 24)
    filter:SetPoint("TOPLEFT", 0, 0)
    local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    search:SetSize(290, 24)
    search:SetPoint("TOPLEFT", 196, 0)
    search:SetAutoFocus(false)
    search:SetTextInsets(6, 6, 0, 0)
    search:SetScript("OnEscapePressed", search.ClearFocus)
    local capture = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    capture:SetSize(194, 24)
    capture:SetPoint("TOPRIGHT", 0, 0)
    capture:SetText("Händler vor Ort erfassen")
    capture:SetScript("OnClick", function()
        local _, message = API.Capture(true)
        if message then print("|cff33ff99PvP-Kompass:|r " .. message) end
    end)
    local searchHint = Label(panel, 196, -27, 500, "GameFontDisableSmall")
    searchHint:SetText("Suche nach Händler, Ort, Gegenstand oder Item-ID")
    local directory = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    directory:SetPoint("TOPLEFT", 0, -48)
    directory:SetPoint("BOTTOMLEFT", 0, 32)
    directory:SetWidth(156)
    local directoryChild = CreateFrame("Frame", nil, directory)
    directoryChild:SetSize(156, 1)
    directory:SetScrollChild(directoryChild)
    local vendorTitle = Label(panel, 196, -46, 510, "GameFontNormal")
    local vendorInfo = Label(panel, 196, -66, 510)
    vendorInfo:SetHeight(38)
    local itemScroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    itemScroll:SetPoint("TOPLEFT", 196, -111)
    itemScroll:SetPoint("BOTTOMRIGHT", -26, 32)
    local itemChild = CreateFrame("Frame", nil, itemScroll)
    itemChild:SetSize(496, 1)
    itemScroll:SetScrollChild(itemChild)
    local empty = Label(itemChild, 4, -4, 478)
    local footer = Label(panel, 0, -1, 715, "GameFontDisableSmall")
    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT", 0, 0)
    footer:SetText("Teilbestand · Kosten beim Händler inkl. persönlichem Rabatt · Shift-Klick: anprobieren")
    local vendorButtons, cards = {}, {}

    local function Card(index)
        if cards[index] then return cards[index] end
        local card = CreateFrame("Button", nil, itemChild, "BackdropTemplate")
        card:SetSize(242, 133)
        card:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 8 })
        card:SetBackdropColor(0.06, 0.07, 0.09, 0.95)
        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(36, 36)
        card.icon:SetPoint("TOPLEFT", 5, -6)
        card.slot = card:CreateTexture(nil, "OVERLAY")
        card.slot:SetTexture("Interface/Buttons/UI-Quickslot2")
        card.slot:SetSize(62, 62)
        card.slot:SetPoint("CENTER", card.icon, "CENTER", 0, 0)
        card.name = Label(card, 47, -7, 188, "GameFontNormalSmall")
        card.name:SetHeight(30)
        card.cost = Label(card, 6, -45, 228)
        card.cost:SetHeight(38)
        card.rep = Label(card, 6, -85, 228)
        card.rep:SetHeight(32)
        card.bundle = Label(card, 6, -118, 228, "GameFontDisableSmall")
        card:SetScript("OnEnter", function(self)
            local item = self.item
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(item.link or ("item:" .. item.itemID))
            GameTooltip:AddLine(CostText(item), 1, 0.82, 0, true)
            GameTooltip:AddLine(ReputationText(item), 0.75, 0.85, 1, true)
            for _, text in ipairs(item.requirements or {}) do GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true) end
            GameTooltip:AddLine("Händler: " .. (self.vendor.name or "?"), 0.75, 0.85, 1, true)
            GameTooltip:AddLine(item.observed and ("Vor Ort erfasst: " .. (item.observedAt or self.vendor.observedAt or "?") .. " · Build " .. tostring(item.build or self.vendor.build)) or ("Online-Teilbestand · Stand " .. catalog.updated .. " · Kosten nicht bestätigt"), 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function() GameTooltip:Hide() end)
        card:SetScript("OnClick", function(self)
            local link = self.item.link or ("item:" .. self.item.itemID)
            if IsShiftKeyDown() and DressUpItemLink then DressUpItemLink(link) end
        end)
        cards[index] = card
        return card
    end

    refreshPanel = function()
        factionFilter = factionFilter or UnitFactionGroup("player") or "Alle"
        filter:SetText("Fraktion: " .. (factionFilter == "Alliance" and "Allianz" or factionFilter))
        for _, button in ipairs(vendorButtons) do button:Hide() end
        for _, card in ipairs(cards) do card:Hide() end
        local query = string.lower(search:GetText() or "")
        local visible, selected = {}, nil
        for _, vendor in ipairs(AllVendors()) do
            if factionFilter == "Alle" or vendor.faction == factionFilter then
                local match = query == "" or string.find(string.lower((vendor.name or "") .. " " .. (vendor.location or "")), query, 1, true)
                if not match then
                    for _, item in ipairs(vendor.items or {}) do
                        local name = GetItemInfo(item.itemID) or item.name or ""
                        if string.find(string.lower(name .. " " .. item.itemID), query, 1, true) then match = true; break end
                    end
                end
                if match then visible[#visible + 1] = vendor end
            end
        end
        for i, vendor in ipairs(visible) do
            if vendor.key == selectedKey then selected = vendor end
            local button = vendorButtons[i]
            if not button then
                button = CreateFrame("Button", nil, directoryChild, "UIPanelButtonTemplate")
                button:SetSize(152, 46)
                button:SetScript("OnClick", function(self) selectedKey = self.key; itemScroll:SetVerticalScroll(0); refreshPanel() end)
                vendorButtons[i] = button
            end
            button:SetPoint("TOPLEFT", 0, -(i - 1) * 49)
            button:SetText(vendor.name)
            button.key = vendor.key
            button:Show()
        end
        directoryChild:SetHeight(math.max(1, #visible * 49))
        selected = selected or visible[1]
        selectedKey = selected and selected.key
        for _, button in ipairs(vendorButtons) do button:SetEnabled(button.key ~= selectedKey) end
        if not selected then
            vendorTitle:SetText("Keine passenden Händler")
            vendorInfo:SetText("")
            empty:SetText("Suche oder Fraktionsfilter ändern.")
            empty:Show()
            itemChild:SetHeight(80)
            itemScroll:SetVerticalScroll(0)
            return
        end
        vendorTitle:SetText(selected.name)
        vendorInfo:SetText((selected.location or "") .. "\n" .. (selected.observedAt and ((selected.complete and "Sortiment erfasst: " or "Teilweise erfasst: ") .. selected.observedAt) or "Online-Teilbestand · Händlerbesuch ergänzt Preise und Sortiment"))
        if setSource then setSource(selected.source or (selected.npcID and ("https://www.wowhead.com/forever/npc=" .. selected.npcID)) or catalog.source) end
        local count = 0
        local vendorMatches = query == "" or string.find(string.lower((selected.name or "") .. " " .. (selected.location or "")), query, 1, true)
        for _, item in ipairs(selected.items or {}) do
            local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(item.itemID)
            if vendorMatches or string.find(string.lower((name or item.name or "") .. " " .. item.itemID), query, 1, true) then
                count = count + 1
                local card = Card(count)
                card:SetPoint("TOPLEFT", ((count - 1) % 2) * 248, -math.floor((count - 1) / 2) * 139)
                card.item, card.vendor = item, selected
                card.icon:SetTexture(icon or item.icon or "Interface/Icons/INV_Misc_QuestionMark")
                card.name:SetText(name or item.name or ("Gegenstand #" .. item.itemID))
                local r, g, b = 1, 0.82, 0
                if quality then r, g, b = GetItemQualityColor(quality) end
                card.name:SetTextColor(r, g, b)
                card.cost:SetText(CostText(item))
                card.rep:SetText(ReputationText(item))
                card.bundle:SetText("Pro Kauf: " .. tostring(item.quantity or 1) .. " · ID " .. item.itemID)
                card:Show()
                if not name and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item.itemID) end
            end
        end
        empty:SetText("Noch kein bestätigtes Sortiment hinterlegt.\n\nÖffne diesen PvP-Händler im Spiel. Bekannte Händler werden automatisch erfasst; weitere lassen sich über „Händler vor Ort erfassen“ hinzufügen.\n\nDie Erfassung speichert alle vom Händler angebotenen Gegenstände einschließlich Gold, Ehre, Marken und Anforderungen, soweit vom Client geliefert.")
        empty:SetShown(count == 0)
        itemChild:SetHeight(math.max(180, math.ceil(count / 2) * 139))
        local maximum = math.max(0, itemChild:GetHeight() - itemScroll:GetHeight())
        if itemScroll:GetVerticalScroll() > maximum then itemScroll:SetVerticalScroll(maximum) end
    end
    filter:SetScript("OnClick", function()
        factionFilter = factionFilter == "Alliance" and "Horde" or factionFilter == "Horde" and "Alle" or "Alliance"
        selectedKey = nil
        directory:SetVerticalScroll(0)
        itemScroll:SetVerticalScroll(0)
        refreshPanel()
    end)
    search:SetScript("OnTextChanged", function() directory:SetVerticalScroll(0); itemScroll:SetVerticalScroll(0); refreshPanel() end)
    panel:SetScript("OnShow", refreshPanel)
    return panel
end

local events = CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_UPDATE")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
local function QueueRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.3, function()
        refreshPending = false
        if merchantOpen then API.Capture(false) end
        if panel and panel:IsShown() then refreshPanel() end
    end)
end
events:SetScript("OnEvent", function(_, event, _, success)
    if event == "MERCHANT_CLOSED" then merchantOpen = false; return end
    if event == "MERCHANT_SHOW" then merchantOpen = true end
    if event == "GET_ITEM_INFO_RECEIVED" and not success then return end
    if merchantOpen or (panel and panel:IsShown()) then QueueRefresh() end
end)

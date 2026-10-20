-- Forever sources checked 2026-10-20. No Classic inventories/prices imported.
-- Nil costs/requirements mean unknown, never zero or no requirement.
PvPKompassVendorData = {
    updated = "2026-10-20",
    source = "https://www.wowhead.com/forever/guide/pvp-overview-ranking-rewards",
    vendors = {
        { key = "263569", npcID = 263569, name = "Bryanna Embreeze", faction = "Alliance", location = "Brachland · bei Northwatch Hold", reputation = "Theramore Expeditionary Force", items = {} },
        { key = "263570", npcID = 263570, name = "Creeg Bothunk", faction = "Horde", location = "Brachland · Merchant Coast", reputation = "Darkspear Raiders", items = {} },
        { key = "12782", npcID = 12782, name = "Captain O'Neal", faction = "Alliance", location = "Sturmwind · Halle der Champions", items = {} },
        { key = "15126", npcID = 15126, name = "Rutherford Twing", faction = "Horde", location = "Arathihochland", reputation = "Die Entweihten", items = {} },
        { key = "15127", npcID = 15127, name = "Samuel Hawke", faction = "Alliance", location = "Arathihochland · Refuge Pointe", reputation = "Der Bund von Arathor", items = {} },
        { key = "14753", npcID = 14753, name = "Illiyana Moonblaze", faction = "Alliance", location = "Ashenvale", reputation = "Silberschwingen", items = {} },
        { key = "14754", npcID = 14754, name = "Kelm Hargunth", faction = "Horde", location = "Brachland", reputation = "Kriegshymnenklan", items = {} },
        { key = "13217", npcID = 13217, name = "Thanthaldis Snowgleam", faction = "Alliance", location = "Alteracgebirge", reputation = "Stormpikegarde", items = {} },
        { key = "13219", npcID = 13219, name = "Jekyll Flandring", faction = "Horde", location = "Alteracgebirge", reputation = "Frostwolfklan", items = {} },
        { key = "13216", npcID = 13216, name = "Gaelden Hammersmith", faction = "Alliance", location = "Alteractal", reputation = "Stormpikegarde", items = {} },
        { key = "13218", npcID = 13218, name = "Grunnda Wolfheart", faction = "Horde", location = "Alteractal", reputation = "Frostwolfklan", items = {} },
        { key = "12795", npcID = 12795, name = "First Sergeant Hola'mahi", faction = "Horde", location = "PvP-Versorgung · Standort im Client prüfen", items = {} },
        { key = "dalaran-accessories", name = '"Dapper" Danik Blackshaft', faction = "Alliance", location = "Dalaran · Die Schattenseite · Zubehör", items = {} },
        { key = "dalaran-weapons", name = "Nixi Fireclaw", faction = "Alliance", location = "Dalaran · Die Schattenseite · Waffen", items = {} },
        { key = "dalaran-armor", name = "Blazik Fireclaw", faction = "Alliance", location = "Dalaran · Die Schattenseite · Rüstung", items = {} },
        { key = "stormwind", name = "Sturmwind · weitere PvP-Händler", faction = "Alliance", location = "Halle der Champions · Händler einzeln erfassen", group = true, items = {} },
        { key = "orgrimmar", name = "Orgrimmar · PvP-Händler", faction = "Horde", location = "Halle der Legenden · Händler einzeln erfassen", group = true, items = {} },
    },
}

-- Item IDs and required standing from Wowhead's Forever PvP overview.
-- Some names occur at multiple levels: retain each independently verified ID.
local rewards = {
    { 271905, "Enriched Seal", 272059, "Darkspear Voodoo Seal", 5 },
    { 271904, "Volunteer's Lucky Seal", 272062, "Relentless Raider's Seal", 5 },
    { 271923, "Expeditionary's Cape", 272078, "Darkspear Raider's Cloak", 6 },
    { 271916, "Militant's Band", 272071, "Darkspear Signet", 6 },
    { 271911, "Theramore Signet", 272067, "Insurgent's Band", 6 },
    { 271920, "Seal of the Expedition", 272075, "Darkspear Warding Pendant", 6 },
    { 271935, "Insurgent's Manifesto", 272090, "Tome of the Darkspear Prophecy", 7 },
    { 271931, "Clever Expeditionary's Spellblade", 272086, "Darkspear Insurgent's Spellblade", 7 },
    { 271939, "Guerrilla's Jagged Mace", 272094, "Darkspear Skirmisher's Bludgeon", 7 },
    { 271927, "Rebels' Rugged Reaper", 272082, "Darkspear Raider's Reaper", 7 },
    { 271946, "Theramore Handwraps", 272098, "Raider Handwraps", 8 },
    { 271949, "Theramore Gloves", 272100, "Raider Gloves", 8 },
    { 271951, "Theramore Handguards", 272102, "Raider Handguards", 8 },
    { 271941, "Theramore Gauntlets", 272096, "Raider Gauntlets", 8 },
    { 271953, "Theramore Shoulderpads", 272103, "Darkspear Shoulderpads", 8 },
    { 271955, "Theramore Pauldrons", 272105, "Darkspear Pauldrons", 8 },
    { 271954, "Theramore Shoulders", 272104, "Darkspear Shoulders", 8 },
    { 271956, "Theramore Epaulets", 272106, "Darkspear Epaulets", 8 },
    { 272957, "Theramore Shoulderguards", 272958, "Darkspear Shoulderguards", 8 },
    { 271957, "Theramore Mantle", 272107, "Darkspear Mantle", 8 },
    { 271959, "Theramore Spaulders", 272108, "Darkspear Spaulders", 8 },
}
for _, reward in ipairs(rewards) do
    for side = 1, 2 do
        local vendor = PvPKompassVendorData.vendors[side]
        vendor.items[#vendor.items + 1] = {
            itemID = reward[side == 1 and 1 or 3], name = reward[side == 1 and 2 or 4],
            reputationStanding = reward[5], reputationFaction = vendor.reputation,
            source = PvPKompassVendorData.source,
        }
    end
end

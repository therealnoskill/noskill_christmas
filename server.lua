-- SERVER-SIDE
local QBCore = exports['qb-core']:GetCoreObject()

-- Belohnungen
local rewards = {
    {item = "weihnachtsmann", label = "Weihnachtsmann", chance = 85}, 
    {item = "zuckerstangen", label = "Zuckerstangen", chance = 55}, 
    {item = "zuckerwatte", label = "Zuckerwatte", chance = 40}, 
    {item = "mutzen", label = "Mutzen", chance = 35}, 
    {item = "gluehwein", label = "Gluehwein", chance = 35}, 
    {item = "lebkuchenherz", label = "Lebkuchenherz", chance = 57}, 
    {item = "champinons", label = "Champinons", chance = 25}, 
    {item = "phone", label = "Smartphone", chance = 6}, 
    {item = "tablet", label = "Tablet", chance = 4}, 
    {item = "digitalwaage", label = "Feinwaage", chance = 20}, 
    {item = "packaged_dosidos", label = "Dosidos-Packung", chance = 20}, 
    {item = "trojan_usb", label = "Trojan USB", chance = 10}, 
    {item = "advancedrepairkit", label = "Erweitertes Reparaturkit", chance = 40}, 
    {item = "nitrous", label = "Nitro", chance = 10}, 
    {item = "radio", label = "Radio", chance = 10}, 
    {item = "heavyarmor", label = "Schwere Rüstung", chance = 5}, 
    {item = "powerbank", label = "Powerbank", chance = 25}, 
    {item = "noskill_repairkit", label = "Standard-Reparaturkit", chance = 15}, 
    {item = "wheel_ticket", label = "Goldenes Ticket", chance = 4}, 
    {item = "kq_winch", label = "Seilwinde", chance = 12}, 
    {item = "random_keys", label = "Zufälliger Fahrzeugschlüssel", chance = 1}, 
}

local harvestedTrees = {} -- Speichert geplünderte Baum-Positionen

-- Hilfsfunktion zur gewichteten Auswahl
local function getRandomReward()
    local totalWeight = 0
    for _, reward in ipairs(rewards) do
        totalWeight = totalWeight + reward.chance
    end

    local random = math.random() * totalWeight
    local cumulativeWeight = 0

    for _, reward in ipairs(rewards) do
        cumulativeWeight = cumulativeWeight + reward.chance
        if random <= cumulativeWeight then
            return reward
        end
    end
end

-- Event: Baum plündern
RegisterNetEvent('christmas_trees:harvestTree', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local treeKey = tostring(coords)

    -- Prüfen, ob der Baum bereits geplündert wurde
    if harvestedTrees[treeKey] then
        TriggerClientEvent('QBCore:Notify', src, "Dieser Baum wurde bereits geplündert.", "error")
        return
    end

    -- Baum als geplündert markieren
    harvestedTrees[treeKey] = {coords = coords, isHarvested = true}

    -- Belohnung auswählen
    local reward = getRandomReward()
    if reward then
        Player.Functions.AddItem(reward.item, 1)
        TriggerClientEvent('QBCore:Notify', src, "Du hast einen " .. reward.label .. " gefunden!", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Du hast nichts gefunden. Versuch es nochmal!", "error")
    end

    -- Synchronisation mit Clients
    TriggerClientEvent('christmas_trees:updateTreeStatus', -1, coords)
end)

-- Callback für initiale Synchronisierung
QBCore.Functions.CreateCallback('christmas_trees:getHarvestedTrees', function(source, cb)
    cb(harvestedTrees)
end)
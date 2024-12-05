local QBCore = exports['qb-core']:GetCoreObject()

-- Belohnungen
local rewards = {
    {item = "weihnachtsmann", label = "Weihnachtsmann", chance = 85}, 
    {item = "zuckerstangen", label = "Zuckerstangen", chance = 65}, 
    {item = "zuckerwatte", label = "Zuckerwatte", chance = 63}, 
    {item = "mutzen", label = "Mutzen", chance = 61}, 
    {item = "gluehwein", label = "Gluehwein", chance = 69}, 
    {item = "lebkuchenherz", label = "Lebkuchenherz", chance = 57}, 
    {item = "krakauer", label = "Krakauer", chance = 35}, 
    {item = "champinons", label = "Champinons", chance = 25}, 
    {item = "phone", label = "Smartphone", chance = 6}, 
    {item = "tablet", label = "Tablet", chance = 4}, 
    {item = "digitalwaage", label = "Feinwaage", chance = 20}, 
    {item = "xtcbaggy", label = "XTC-Baggy", chance = 15}, 
    {item = "packaged_dosidos", label = "Dosidos-Packung", chance = 20}, 
    {item = "trojan_usb", label = "Trojan USB", chance = 10}, 
    {item = "advancedrepairkit", label = "Erweitertes Reparaturkit", chance = 40}, 
    {item = "nitrous", label = "Nitro", chance = 10}, 
    {item = "radio", label = "Radio", chance = 10}, 
    {item = "heavyarmor", label = "Schwere Rüstung", chance = 5}, 
    {item = "powerbank", label = "Powerbank", chance = 25}, 
    {item = "noskill_repairkit", label = "Standard-Reparaturkit", chance = 15}, 
    {item = "wheel_ticket", label = "Goldenes Ticket", chance = 2}, 
    {item = "ayran", label = "Ayran", chance = 24}, 
    {item = "kq_winch", label = "Seilwinde", chance = 12}, 
    {item = "meth_bag", label = "Meth-Beutel", chance = 15}, 
    {item = "random_keys", label = "Zufälliger Fahrzeugschlüssel", chance = 1}, 
}

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

RegisterNetEvent('christmas_trees:harvestTree', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    -- Belohnung auswählen
    local reward = getRandomReward()
    if reward then
        Player.Functions.AddItem(reward.item, 1)
        TriggerClientEvent('QBCore:Notify', src, "Du hast einen " .. reward.label .. " gefunden!", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Du hast nichts gefunden. Versuch es nochmal!", "error")
    end
end)

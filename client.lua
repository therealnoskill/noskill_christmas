-- CLIENT-SIDE
local QBCore = exports['qb-core']:GetCoreObject()

-- Weihnachtsbaum-Prop-Model
local treeModel = `prop_xmas_tree_int`
local interactDistance = 2.0 -- Distanz, in der der Spieler interagieren kann
local drawDistance = 10.0 -- Entfernungsbereich für das Zeichnen des Texts
local harvesting = false -- Status, ob aktuell ein Baum geplündert wird
local harvestedTrees = {} -- Tabelle zum Speichern der geplünderten Baum-Positionen

-- Wenn die Weihnachts-Wetteroption aktiviert ist, wird das Wetter und andere Effekte angepasst
if Config.XmasWeather then
    SetWeatherTypeNowPersist('xmas')
    SetForceVehicleTrails(true)
    SetForcePedFootstepsTracks(true)
end

-- Funktion zum Finden aller Weihnachtsbaum-Props in der Welt
local function findActiveTrees()
    local handle, object = FindFirstObject()
    local success
    repeat
        if GetEntityModel(object) == treeModel then
            -- Koordinaten des gefundenen Objekts abrufen
            local treeCoords = GetEntityCoords(object)
            local treeKey = tostring(treeCoords) -- Konvertieren der Koordinaten in einen eindeutigen Schlüssel
            -- Baum nur hinzufügen, wenn er noch nicht bekannt ist und nicht geplündert wurde
            if not harvestedTrees[treeKey] then
                harvestedTrees[treeKey] = {coords = vector3(treeCoords.x, treeCoords.y, treeCoords.z), isHarvested = false}
            end
        end
        success, object = FindNextObject(handle) -- Nächstes Objekt finden
    until not success
    EndFindObject(handle) -- Suche beenden
end

-- Funktion zum Abspielen der Ernteanimation
local function playHarvestAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@prop_human_bum_bin@idle_b"  -- Animation: Beispiel
    local animName = "idle_d"

    -- Animationsdatei laden
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0) -- Warten, bis die Animation geladen ist
    end
    -- Animation abspielen
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, 5000, 1, 0, false, false, false)
    Wait(5000) -- Warten, bis die Animation endet
    ClearPedTasks(playerPed) -- Animation abbrechen
end

-- Funktion zum Anzeigen von 3D-Text im Spiel
local function Draw3DText(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Event: Spieler betritt den Server
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print('Im a client and I just loaded into your server! noskill_christmas')

    -- Thread zur Interaktion mit Weihnachtsbäumen
    CreateThread(function()
        while true do
            local sleep = 1000 -- Standardmäßig lange Wartezeit
            local playerCoords = GetEntityCoords(PlayerPedId()) -- Spielerposition abrufen

            for _, tree in pairs(harvestedTrees) do
                -- Konvertieren der gespeicherten Koordinaten in einen Vector3
                local treeCoords = vector3(tree.coords.x, tree.coords.y, tree.coords.z)
                local distance = #(playerCoords - treeCoords) -- Abstand zwischen Spieler und Baum

                if distance < drawDistance then
                    sleep = 0 -- Reduzieren der Wartezeit, wenn ein Baum in der Nähe ist

                    if not tree.isHarvested then
                        -- Interaktionstext anzeigen
                        Draw3DText(treeCoords.x, treeCoords.y, treeCoords.z + 1.5, "[E] Um zu plündern")

                        if distance < interactDistance and IsControlJustPressed(0, 38) and not harvesting then
                            harvesting = true -- Interaktionsstatus setzen
                            playHarvestAnimation() -- Animation abspielen
                            tree.isHarvested = true -- Baum als geplündert markieren
                            harvestedTrees[tostring(treeCoords)] = tree

                            -- Synchronisierung über Server
                            TriggerServerEvent('christmas_trees:harvestTree', treeCoords)
                            harvesting = false -- Interaktionsstatus zurücksetzen
                        end
                    else
                        -- Hinweistext für bereits geplünderte Bäume anzeigen
                        Draw3DText(treeCoords.x, treeCoords.y, treeCoords.z + 1.5, "Dieser Baum wurde bereits geplündert")
                    end
                end
            end

            Wait(sleep) -- Warten, um Ressourcen zu schonen
        end
    end)

    -- Thread zum regelmäßigen Scannen der Welt nach Bäumen
    CreateThread(function()
        while true do
            findActiveTrees()
            Wait(10000) -- Alle 10 Sekunden scannen
        end
    end)
end)

-- Initiale Synchronisierung der geplünderten Bäume mit dem Server
CreateThread(function()
    Wait(1000) -- Kurze Verzögerung zur Sicherheit
    QBCore.Functions.TriggerCallback('christmas_trees:getHarvestedTrees', function(serverTrees)
        for treeKey, data in pairs(serverTrees) do
            harvestedTrees[treeKey] = {coords = vector3(data.coords.x, data.coords.y, data.coords.z), isHarvested = data.isHarvested}
        end
    end)
end)

-- Event: Aktualisierung eines Baumes durch den Server
RegisterNetEvent('christmas_trees:updateTreeStatus', function(coords)
    print("Status von Baum auf Client aktualisiert: ", coords)
    local treeKey = tostring(coords)
    if harvestedTrees[treeKey] then
        harvestedTrees[treeKey].isHarvested = true -- Baum als geplündert markieren
    end
end)
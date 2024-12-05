local QBCore = exports['qb-core']:GetCoreObject()

-- Weihnachtsbaum-Prop-Model
local treeModel = `prop_xmas_tree_int`
local interactDistance = 2.0 -- Distanz, in der der Spieler interagieren kann
local drawDistance = 10.0 -- Entfernungsbereich für das Zeichnen des Texts
local harvesting = false
local harvestedTrees = {} -- Tabelle zum Speichern der geplünderten Baum-Positionen

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
            local treeCoords = GetEntityCoords(object)
            -- Baum-Position als Key verwenden, um das Array zu markieren
            if not harvestedTrees[tostring(treeCoords)] then
                -- Speichern der Koordinaten als Key (String-Format)
                harvestedTrees[tostring(treeCoords)] = {coords = treeCoords, isHarvested = false}
            end
        end
        success, object = FindNextObject(handle)
    until not success
    EndFindObject(handle)
end

-- Funktion zum Abspielen der Ernteanimation
local function playHarvestAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@prop_human_bum_bin@idle_b"  -- Beispiel-Animation
    local animName = "idle_d"

    -- Animation laden und abspielen
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, 5000, 1, 0, false, false, false)

    Wait(5000) -- Warten, bis die Animation endet
    ClearPedTasks(playerPed)
end

-- Text beim Interagieren anzeigen
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

-- Interaktion mit Weihnachtsbäumen
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        -- Alle Bäume durchgehen
        for _, tree in pairs(harvestedTrees) do
            local treeCoords = tree.coords -- Verwende den gespeicherten `coords`-Wert
            local distance = #(playerCoords - treeCoords)
            
            -- Wenn Baum in Interaktionsbereich
            if distance < drawDistance then
                sleep = 0

                if not tree.isHarvested then
                    -- Baum ist noch nicht geplündert
                    Draw3DText(treeCoords.x, treeCoords.y, treeCoords.z + 1.5, "[E] Um zu plündern")

                    -- Interaktionsabfrage bei sehr naher Entfernung
                    if distance < interactDistance and IsControlJustPressed(0, 38) and not harvesting then
                        harvesting = true
                        playHarvestAnimation()  -- Animation abspielen

                        -- Markiere den Baum als geplündert
                        tree.isHarvested = true
                        harvestedTrees[tostring(treeCoords)] = tree

                        TriggerServerEvent('christmas_trees:harvestTree', treeCoords)

                        -- Lösche den Baum, wenn Config.DeleteTrees aktiv ist
                        if Config.DeleteTrees then
                            Wait(2000)  -- Warte 2 Sekunden
                            DeleteObject(tree) -- Lösche das Baum-Objekt
                            harvestedTrees[tostring(treeCoords)] = nil  -- Entferne Baum aus der Liste
                        end

                        harvesting = false
                    end
                else
                    -- Baum wurde bereits geplündert, zeige eine Nachricht an
                    Draw3DText(treeCoords.x, treeCoords.y, treeCoords.z + 1.5, "Dieser Baum wurde bereits geplündert")
                end
            end
        end

        Wait(sleep)
    end
end)

-- Scannt alle Objekte regelmäßig nach Weihnachtsbäumen
CreateThread(function()
    while true do
        findActiveTrees()  -- Aktualisiere die Liste der Weihnachtsbäume
        Wait(10000)  -- Alle 10 Sekunden nach neuen Bäumen suchen
    end
end)

Citizen.CreateThread(function()
    
    local showHelp = true
    local loaded = false
    
    while true do
        if enableWeatherControl then
            SetWeatherTypeNowPersist('XMAS')
        end
        Citizen.Wait(0) -- prevent crashing
        if IsNextWeatherType('XMAS') then -- check for xmas weather type
            -- enable frozen water effect (water isn't actually ice, just looks like there's an ice layer on top of the water)
            N_0xc54a08c85ae4d410(3.0)
            -- preview: https://vespura.com/hi/i/2eb901ad4b1.gif
            
            SetForceVehicleTrails(true)
            SetForcePedFootstepsTracks(true)
            
            if not loaded then
                RequestScriptAudioBank("ICE_FOOTSTEPS", false)
                RequestScriptAudioBank("SNOW_FOOTSTEPS", false)
                RequestNamedPtfxAsset("core_snow")
                while not HasNamedPtfxAssetLoaded("core_snow") do
                    Citizen.Wait(0)
                end
                UseParticleFxAssetNextCall("core_snow")
                loaded = true
            end
            RequestAnimDict('anim@mp_snowball') -- pre-load the animation
            if IsControlJustReleased(0, 119) and not IsPedInAnyVehicle(GetPlayerPed(-1), true) and not IsPlayerFreeAiming(PlayerId()) and not IsPedSwimming(PlayerPedId()) and not IsPedSwimmingUnderWater(PlayerPedId()) and not IsPedRagdoll(PlayerPedId()) and not IsPedFalling(PlayerPedId()) and not IsPedRunning(PlayerPedId()) and not IsPedSprinting(PlayerPedId()) and GetInteriorFromEntity(PlayerPedId()) == 0 and not IsPedShooting(PlayerPedId()) and not IsPedUsingAnyScenario(PlayerPedId()) and not IsPedInCover(PlayerPedId(), 0) then -- check if the snowball should be picked up
                TaskPlayAnim(PlayerPedId(), 'anim@mp_snowball', 'pickup_snowball', 8.0, -1, -1, 0, 1, 0, 0, 0) -- pickup the snowball
                Citizen.Wait(1950) -- wait 1.95 seconds to prevent spam clicking and getting a lot of snowballs without waiting for animatin to finish.
                GiveWeaponToPed(GetPlayerPed(-1), GetHashKey('WEAPON_SNOWBALL'), 1, false, true) -- get 2 snowballs each time.
            end
            if not IsPedInAnyVehicle(GetPlayerPed(-1), true) --[[and not IsPlayerFreeAiming(PlayerId())]] then
                if showHelp then
                    showHelpNotification()
                end
                showHelp = false
            else
                showHelp = true
            end
        else
            -- disable frozen water effect
            if loaded then N_0xc54a08c85ae4d410(0.0) end
            loaded = false
            RemoveNamedPtfxAsset("core_snow")
            ReleaseNamedScriptAudioBank("ICE_FOOTSTEPS")
            ReleaseNamedScriptAudioBank("SNOW_FOOTSTEPS")
            SetForceVehicleTrails(false)
            SetForcePedFootstepsTracks(false)
        end
        if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey('WEAPON_SNOWBALL') then
            SetPlayerWeaponDamageModifier(PlayerId(), 0.0)
        end
    end
end)

function showHelpNotification()
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName("Drücke ~INPUT_VEH_FLY_VERTICAL_FLIGHT_MODE~, während du zu Fuß bist, um Schneebälle aufzuheben!")
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

-- S82 Coords | client/main.lua
-- Cong cu lay toa do, vector, luu diem yeu thich va cong cu laser can chinh

local isOpen = false
local laserEnabled = false
local laserSmooth = nil -- toa do laser da lam min, chong nhay
local kvpKey = 's82coords_favorites'

-------------------------------------------------
-- Tien ich
-------------------------------------------------

local function round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

local function hasPermission()
    if not Config.RequireAce then return true end
    return IsAceAllowed(Config.AcePermission)
end

local function loadFavorites()
    local raw = GetResourceKvpString(kvpKey)
    if raw then
        local ok, decoded = pcall(json.decode, raw)
        if ok and decoded then
            return decoded
        end
    end
    return Config.DefaultFavorites or {}
end

local function saveFavorites(list)
    SetResourceKvp(kvpKey, json.encode(list))
end

-------------------------------------------------
-- Mo / dong giao dien
-------------------------------------------------

local function closeUI()
    if not isOpen then return end
    isOpen = false
    laserEnabled = false
    laserSmooth = nil
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'toggle', open = false })
end

local function openUI()
    if isOpen then
        closeUI()
        return
    end

    if not hasPermission() then
        -- Khong du quyen, khong lam gi ca
        return
    end

    isOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true) -- van co the di chuyen (WASD) trong khi bang dang mo
    SendNUIMessage({
        action = 'toggle',
        open = true,
        favorites = loadFavorites(),
    })
end

RegisterCommand(Config.Command, function()
    openUI()
end, false)

if Config.EnableKeybind then
    RegisterKeyMapping(Config.Command, 'Mo S82 Coords', 'keyboard', Config.DefaultKey)
end

-------------------------------------------------
-- Vong lap cap nhat toa do khi UI dang mo
-------------------------------------------------

CreateThread(function()
    while true do
        local wait = Config.RefreshRate
        if isOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            SendNUIMessage({
                action = 'update',
                x = round(coords.x, Config.Decimals),
                y = round(coords.y, Config.Decimals),
                z = round(coords.z, Config.Decimals),
                heading = round(heading, Config.Decimals),
            })
        else
            wait = 500
        end
        Wait(wait)
    end
end)

-------------------------------------------------
-- Cong cu laser: chieu tia tu camera, tra ve toa do diem cham
-------------------------------------------------

local function getAimCoords()
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()

    local radX = (math.pi / 180) * camRot.x
    local radZ = (math.pi / 180) * camRot.z

    local dirX = -math.sin(radZ) * math.abs(math.cos(radX))
    local dirY = math.cos(radZ) * math.abs(math.cos(radX))
    local dirZ = math.sin(radX)

    local destination = vector3(
        camCoord.x + dirX * Config.Laser.maxDistance,
        camCoord.y + dirY * Config.Laser.maxDistance,
        camCoord.z + dirZ * Config.Laser.maxDistance
    )

    local rayHandle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        destination.x, destination.y, destination.z,
        -1, PlayerPedId(), 0
    )
    local _, hit, endCoords = GetShapeTestResult(rayHandle)

    return camCoord, hit == 1 and endCoords or destination
end

CreateThread(function()
    while true do
        Wait(0)
        if laserEnabled then
            local _, rawCoord = getAimCoords()
            local c = Config.Laser.color

            -- Lam min toa do de tranh nhay lung tung do raycast thay doi lien tuc
            if not laserSmooth then
                laserSmooth = rawCoord
            else
                local factor = 0.35
                laserSmooth = vector3(
                    laserSmooth.x + (rawCoord.x - laserSmooth.x) * factor,
                    laserSmooth.y + (rawCoord.y - laserSmooth.y) * factor,
                    laserSmooth.z + (rawCoord.z - laserSmooth.z) * factor
                )
            end

            DrawMarker(
                28, laserSmooth.x, laserSmooth.y, laserSmooth.z,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.18, 0.18, 0.18,
                c.r, c.g, c.b, 220,
                false, false, 2, true, nil, nil, false
            )

            if isOpen then
                SendNUIMessage({
                    action = 'laserUpdate',
                    x = round(laserSmooth.x, Config.Decimals),
                    y = round(laserSmooth.y, Config.Decimals),
                    z = round(laserSmooth.z, Config.Decimals),
                })
            end
        else
            Wait(250)
        end
    end
end)

-------------------------------------------------
-- NUI Callbacks
-------------------------------------------------

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb({ ok = true })
end)

RegisterNUICallback('toggleLaser', function(data, cb)
    laserEnabled = data and data.enabled or false
    if not laserEnabled then
        laserSmooth = nil -- reset diem lam min khi tat laser
    end
    cb({ ok = true, enabled = laserEnabled })
end)

RegisterNUICallback('saveFavorites', function(data, cb)
    if data and data.favorites then
        saveFavorites(data.favorites)
    end
    cb({ ok = true })
end)

RegisterNUICallback('gotoFavorite', function(data, cb)
    if not data or not data.coords then
        cb({ ok = false })
        return
    end

    if not hasPermission() then
        cb({ ok = false })
        return
    end

    local ped = PlayerPedId()
    local c = data.coords

    SetEntityCoordsNoOffset(ped, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false)
    if c.w then
        SetEntityHeading(ped, c.w + 0.0)
    end

    cb({ ok = true })
end)

-------------------------------------------------
-- Dong UI bang phim ESC
-------------------------------------------------

CreateThread(function()
    while true do
        Wait(0)
        if isOpen then
            if IsControlJustReleased(0, 322) then -- ESC / INPUT_FRONTEND_PAUSE
                closeUI()
            end
        else
            Wait(250)
        end
    end
end)
--[[ pizza - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local enterPos, exitPos, counterPos = nil, nil, nil
local carrying = false
local dropPos = nil
local boxesLeft, deliveries = 0, 0
local boxObj = nil
local dropBlip = nil
local eHold, eHoldStart = false, 0
local HOLD_MS = 450
local eMode = nil

---------------------
-- KUTU (elde görünür)
---------------------
local function destroyBox()
    if isElement(boxObj) then destroyElement(boxObj) end
    boxObj = nil
end

local function attachBox()
    destroyBox()
    boxObj = createObject(1582, 0, 0, 0)
    if not boxObj then
        boxObj = createObject(2814, 0, 0, 0)
    end
    if not boxObj then return end

    setElementCollisionsEnabled(boxObj, false)
    setObjectScale(boxObj, 0.85)
    setElementInterior(boxObj, getElementInterior(localPlayer))
    setElementDimension(boxObj, getElementDimension(localPlayer))

    local ok = pcall(function()
        exports.bone_attach:attachElementToBone(boxObj, localPlayer, 12, 0.12, 0.08, 0.06, 0, 270, 0)
    end)
    if ok then return end

    ok = pcall(function()
        exports.pAttach:attach(boxObj, localPlayer, 12, 0.12, 0.08, 0.06, 0, 270, 0)
    end)
    if ok then return end

    attachElements(boxObj, localPlayer, 0.18, 0.40, 0.12, -90, 0, 0)
end

---------------------
-- EVENTS
---------------------
addEvent("pizza:setup", true)
addEventHandler("pizza:setup", root, function(data)
    if type(data) ~= "table" then return end
    enterPos = data.enter
    exitPos = data.exit
    counterPos = data.counter
end)

addEvent("pizza:carry", true)
addEventHandler("pizza:carry", root, function(state)
    carrying = state and true or false
    if carrying then attachBox() else destroyBox() end
end)

addEvent("pizza:drop", true)
addEventHandler("pizza:drop", root, function(pos)
    dropPos = pos
    if isElement(dropBlip) then destroyElement(dropBlip) dropBlip = nil end
    if pos then
        dropBlip = createBlip(pos.x, pos.y, pos.z, 0, 2, 255, 140, 40, 255, 0, 99999.0)
    end
end)

addEvent("pizza:info", true)
addEventHandler("pizza:info", root, function(b, d)
    boxesLeft = b or 0
    deliveries = d or 0
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("pizza:ask", localPlayer)
    outputChatBox("#FF7832[Pizza] #FFFFFFF2→Pizza | Dükkan F | Kasa E | /pizzadur", 255, 255, 255, true)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    destroyBox()
    if isElement(dropBlip) then destroyElement(dropBlip) end
end)

---------------------
-- MESAFE
---------------------
local function distTo(pos)
    if not pos then return 9999 end
    local px, py, pz = getElementPosition(localPlayer)
    local pint, pdim = getElementInterior(localPlayer), getElementDimension(localPlayer)
    if pos.int ~= nil and pos.dim ~= nil then
        if pint ~= pos.int or pdim ~= pos.dim then return 9999 end
    end
    return getDistanceBetweenPoints3D(px, py, pz, pos.x, pos.y, pos.z)
end

local function nearBike()
    local px, py, pz = getElementPosition(localPlayer)
    local mySerial = getPlayerSerial(localPlayer)
    for _, veh in ipairs(getElementsByType("vehicle", root, true)) do
        if getElementData(veh, "pizza:bike") == mySerial then
            local x, y, z = getElementPosition(veh)
            if getDistanceBetweenPoints3D(px, py, pz, x, y, z) < 4 then
                return true, x, y, z + 1
            end
        end
    end
    return false
end

---------------------
-- TUŞLAR
---------------------
bindKey("f", "down", function()
    if enterPos and getElementInterior(localPlayer) == 0 and distTo(enterPos) < 2.5 then
        triggerServerEvent("pizza:enter", localPlayer)
        return
    end
    if exitPos and distTo(exitPos) < 2.8 then
        triggerServerEvent("pizza:exitShop", localPlayer)
    end
end)

bindKey("e", "down", function()
    eMode = nil
    if counterPos and distTo(counterPos) < 2.2 then
        eMode = "counter"
        eHold = true
        eHoldStart = getTickCount()
        return
    end
    local nb = nearBike()
    if nb and not carrying and boxesLeft > 0 and not isPedInVehicle(localPlayer) then
        eMode = "bike"
        eHold = true
        eHoldStart = getTickCount()
        return
    end
    if dropPos and carrying and distTo(dropPos) < 3.5 then
        eMode = "deliver"
        eHold = true
        eHoldStart = getTickCount()
        return
    end
end)

bindKey("e", "up", function()
    eHold = false
    eMode = nil
end)

---------------------
-- RENDER
---------------------
local function drawE(sx2, sy2, label, active)
    local size = 36 * scale
    local a = active and 230 or 120
    dxDrawRectangle(sx2 - size/2, sy2 - size/2, size, size, active and tocolor(255, 120, 40, a) or tocolor(40, 25, 10, a))
    dxDrawText("E", sx2 - size/2, sy2 - size/2, sx2 + size/2, sy2 + size/2, tocolor(255, 255, 255, a), 1.3 * scale, "default-bold", "center", "center")
    if label then
        dxDrawText(label, sx2 - 50, sy2 + size/2 + 4, sx2 + 50, sy2 + size/2 + 22, tocolor(255, 200, 120, a), 0.9 * scale, "default", "center", "top")
    end
    if eHold and active then
        local prog = math.min(1, (getTickCount() - eHoldStart) / HOLD_MS)
        dxDrawRectangle(sx2 - 25*scale, sy2 + size/2 + 24, 50*scale, 6, tocolor(0, 0, 0, 180))
        dxDrawRectangle(sx2 - 25*scale, sy2 + size/2 + 24, 50*scale * prog, 6, tocolor(255, 140, 40))
    end
end

addEventHandler("onClientRender", root, function()
    -- kutu int/dim takibi
    if isElement(boxObj) then
        local i, d = getElementInterior(localPlayer), getElementDimension(localPlayer)
        if getElementInterior(boxObj) ~= i then setElementInterior(boxObj, i) end
        if getElementDimension(boxObj) ~= d then setElementDimension(boxObj, d) end
    end

    -- E tutma bitince aksiyon
    if eHold and eMode and getTickCount() - eHoldStart >= HOLD_MS then
        if eMode == "counter" then triggerServerEvent("pizza:takeBoxes", localPlayer)
        elseif eMode == "bike" then triggerServerEvent("pizza:takeFromBike", localPlayer)
        elseif eMode == "deliver" then triggerServerEvent("pizza:deliver", localPlayer)
        end
        eHold = false
        eMode = nil
    end

    -- Kapı
    if enterPos and getElementInterior(localPlayer) == 0 then
        local d = distTo(enterPos)
        if d < 18 then
            local sx2, sy2 = getScreenFromWorldPosition(enterPos.x, enterPos.y, enterPos.z + 1)
            if sx2 then
                local s, a = 48 * scale, d < 2.5 and 240 or 140
                dxDrawRectangle(sx2 - s/2, sy2 - s/2, s, s, tocolor(50, 25, 10, a))
                dxDrawText("P", sx2 - s/2, sy2 - s/2, sx2 + s/2, sy2 + s/2, tocolor(255, 140, 40, a), 1.5 * scale, "default-bold", "center", "center")
            end
        end
        if d < 2.5 then
            dxDrawText("Pizza dükkanı — F (meslek: Pizza Kurye)", 0, sy - 70 * scale, sx, sy - 30 * scale, tocolor(255, 160, 60, 240), 1.2 * scale, "default-bold", "center", "center", false, false, true)
        end
    end

    if exitPos and distTo(exitPos) < 2.8 then
        dxDrawText("Çıkmak için F", 0, sy - 70 * scale, sx, sy - 30 * scale, tocolor(255, 160, 60, 240), 1.2 * scale, "default-bold", "center", "center", false, false, true)
    end

    -- Kasa
    if counterPos then
        local d = distTo(counterPos)
        if d < 12 then
            local sx2, sy2 = getScreenFromWorldPosition(counterPos.x, counterPos.y, counterPos.z)
            if sx2 then drawE(sx2, sy2, "Pizza al", d < 2.2 and eMode == "counter") end
        end
    end

    -- Motor
    local nb, bx, by, bz = nearBike()
    if nb and not carrying and boxesLeft > 0 and not isPedInVehicle(localPlayer) then
        local sx2, sy2 = getScreenFromWorldPosition(bx, by, bz)
        if sx2 then drawE(sx2, sy2, "Paket al", eMode == "bike") end
    end

    -- Teslimat
    if dropPos then
        local d = distTo(dropPos)
        local sx2, sy2 = getScreenFromWorldPosition(dropPos.x, dropPos.y, dropPos.z + 1)
        if sx2 and d < 60 then
            dxDrawText("PIZZA", sx2 - 40, sy2 - 28, sx2 + 40, sy2, tocolor(255, 140, 40, 220), 1.1 * scale, "default-bold", "center", "center")
            if carrying and d < 3.5 then
                drawE(sx2, sy2 + 10, "Teslim et", eMode == "deliver")
            end
        end
    end

    -- HUD
    if boxesLeft > 0 or carrying then
        local level = 1 + math.floor(deliveries / 5)
        if level > 5 then level = 5 end
        dxDrawRectangle(sx - 220 * scale, 20 * scale, 200 * scale, 70 * scale, tocolor(20, 12, 8, 200))
        dxDrawText("PIZZA KURYE", sx - 220 * scale, 22 * scale, sx - 20 * scale, 42 * scale, tocolor(255, 140, 40), 1.0 * scale, "default-bold", "center", "center")
        dxDrawText("Kutu: " .. boxesLeft .. " | Teslim: " .. deliveries .. " | Sv: " .. level, sx - 220 * scale, 44 * scale, sx - 20 * scale, 70 * scale, tocolor(255, 220, 180), 0.9 * scale, "default", "center", "center")
    end
end)
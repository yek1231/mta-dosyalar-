--[[ arac - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local signalSide = "off"
local signalBlink = false
local activeSignals = {}

local menuOpen = false
local menuMode = "mech"
local menuCost, menuFuel, menuHp = 0, 50, 1000
local FUEL_PRICE = 6

local function isDriver()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh or getVehicleController(veh) ~= localPlayer then return false, nil end
    return true, veh
end

bindKey("z", "down", function() if isDriver() then triggerServerEvent("arac:toggleEngine", localPlayer) end end)
bindKey("l", "down", function() if isDriver() then triggerServerEvent("arac:toggleLights", localPlayer) end end)
bindKey("g", "down", function() if isDriver() then triggerServerEvent("arac:toggleHandbrake", localPlayer) end end)
bindKey("h", "down", function() if isDriver() then setPedControlState(localPlayer, "horn", true) end end)
bindKey("h", "up", function() setPedControlState(localPlayer, "horn", false) end)

bindKey("mouse1", "down", function()
    if not isDriver() then return end
    signalSide = (signalSide == "left") and "off" or "left"
    triggerServerEvent("arac:signal", localPlayer, signalSide)
end)
bindKey("mouse2", "down", function()
    if not isDriver() then return end
    signalSide = (signalSide == "right") and "off" or "right"
    triggerServerEvent("arac:signal", localPlayer, signalSide)
end)

addEventHandler("onClientPlayerVehicleExit", localPlayer, function()
    signalSide = "off"
    setPedControlState(localPlayer, "horn", false)
    menuOpen = false
    showCursor(false)
end)

addEvent("arac:signalFX", true)
addEventHandler("arac:signalFX", root, function(veh, side)
    if not isElement(veh) then return end
    if side == "off" then
        activeSignals[veh] = nil
        for i = 0, 3 do setVehicleLightState(veh, i, 0) end
        return
    end
    activeSignals[veh] = side
end)

setTimer(function()
    signalBlink = not signalBlink
    for veh, side in pairs(activeSignals) do
        if isElement(veh) then
            if signalBlink then
                if side == "left" then
                    setVehicleLightState(veh, 0, 0); setVehicleLightState(veh, 1, 1)
                    setVehicleLightState(veh, 2, 0); setVehicleLightState(veh, 3, 1)
                else
                    setVehicleLightState(veh, 0, 1); setVehicleLightState(veh, 1, 0)
                    setVehicleLightState(veh, 2, 1); setVehicleLightState(veh, 3, 0)
                end
            else
                for i = 0, 3 do setVehicleLightState(veh, i, 1) end
            end
        else
            activeSignals[veh] = nil
        end
    end
end, 400, 0)

addEvent("arac:mechMenu", true)
addEventHandler("arac:mechMenu", root, function(cost, f, hp, mode)
    menuCost = cost or 0
    menuFuel = f or 50
    menuHp = hp or 1000
    menuMode = mode or "mech"
    menuOpen = true
    showCursor(true)
end)

local function closeMenu()
    menuOpen = false
    showCursor(false)
end

bindKey("escape", "down", function()
    if menuOpen then closeMenu() cancelEvent() end
end)

local function box(x, y, w, h, t)
    dxDrawRectangle(x, y, w, h, tocolor(40, 40, 50, 240))
    dxDrawText(t, x, y, x + w, y + h, tocolor(255, 255, 255), 1.05 * scale, "default-bold", "center", "center")
end

local function hit(cx, cy, x, y, w, h)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not menuOpen or btn ~= "left" or state ~= "down" then return end
    local w, h = 400 * scale, 300 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    local bw, bx = w - 50 * scale, x + 25 * scale
    if menuMode == "mech" then
        if hit(cx, cy, bx, y + 100 * scale, bw, 48 * scale) then
            triggerServerEvent("arac:mechRepair", localPlayer)
            closeMenu()
        elseif hit(cx, cy, bx, y + 160 * scale, bw, 48 * scale) then
            triggerServerEvent("arac:mechFuel", localPlayer, 25)
        elseif hit(cx, cy, bx, y + 220 * scale, bw, 48 * scale) then
            closeMenu()
        end
    else
        if hit(cx, cy, bx, y + 100 * scale, bw, 48 * scale) then
            triggerServerEvent("arac:mechFuel", localPlayer, 25)
        elseif hit(cx, cy, bx, y + 160 * scale, bw, 48 * scale) then
            triggerServerEvent("arac:mechFuel", localPlayer, 100)
        elseif hit(cx, cy, bx, y + 220 * scale, bw, 48 * scale) then
            closeMenu()
        end
    end
end)

local function drawSpeedo(veh)
    local vx, vy, vz = getElementVelocity(veh)
    local speed = math.floor(math.sqrt(vx * vx + vy * vy + vz * vz) * 180)
    local f = tonumber(getElementData(veh, "arac:fuel")) or 0
    local hp = getElementHealth(veh)
    local hpPct = math.max(0, math.min(100, (hp - 250) / 7.5))
    local eng = getVehicleEngineState(veh)
    local w, h = 220 * scale, 130 * scale
    local x, y = sx - w - 24 * scale, sy - h - 24 * scale
    dxDrawRectangle(x, y, w, h, tocolor(10, 12, 18, 210))
    dxDrawRectangle(x, y, w, 3, tocolor(80, 160, 255, 220))
    dxDrawText(tostring(speed), x, y + 8 * scale, x + w, y + 55 * scale, tocolor(255, 255, 255), 2.0 * scale, "default-bold", "center", "center")
    dxDrawText("km/h", x, y + 48 * scale, x + w, y + 68 * scale, tocolor(140, 160, 180), 0.95 * scale, "default", "center", "center")
    local bx, by, bw, bh = x + 14 * scale, y + 78 * scale, w - 28 * scale, 12 * scale
    dxDrawRectangle(bx, by, bw, bh, tocolor(30, 30, 40, 255))
    local fcol = f < 25 and tocolor(255, 80, 60) or (f < 50 and tocolor(255, 180, 40) or tocolor(40, 180, 255))
    dxDrawRectangle(bx, by, bw * (f / 100), bh, fcol)
    dxDrawText(string.format("Yakıt  %.0f%%", f), bx, by - 16 * scale, bx + bw, by, tocolor(180, 200, 220), 0.85 * scale, "default", "left", "center")
    local by2 = by + 22 * scale
    dxDrawRectangle(bx, by2, bw, bh, tocolor(30, 30, 40, 255))
    local hcol = hpPct < 30 and tocolor(255, 70, 50) or (hpPct < 60 and tocolor(255, 160, 40) or tocolor(80, 220, 120))
    dxDrawRectangle(bx, by2, bw * (hpPct / 100), bh, hcol)
    dxDrawText(string.format("Sağlık  %.0f%%", hpPct), bx, by2 - 16 * scale, bx + bw, by2, tocolor(180, 200, 220), 0.85 * scale, "default", "left", "center")
    dxDrawText(eng and "● MOTOR" or "○ MOTOR", x + 10 * scale, y + h - 22 * scale, x + w / 2, y + h - 4 * scale, eng and tocolor(80, 255, 140) or tocolor(120, 120, 130), 0.85 * scale, "default-bold", "left", "center")
    local sig = signalSide == "off" and "" or (signalSide == "left" and "◀ SİNYAL" or "SİNYAL ▶")
    dxDrawText(sig, x + w / 2, y + h - 22 * scale, x + w - 10 * scale, y + h - 4 * scale, tocolor(255, 200, 60), 0.85 * scale, "default-bold", "right", "center")
end

addEventHandler("onClientRender", root, function()
    local ok, veh = isDriver()
    if ok then drawSpeedo(veh) end
    if not menuOpen then return end
    local w, h = 400 * scale, 300 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    local bw, bx = w - 50 * scale, x + 25 * scale
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 150))
    dxDrawRectangle(x, y, w, h, tocolor(16, 16, 22, 250))
    dxDrawRectangle(x, y, w, 56 * scale, tocolor(30, 30, 40, 255))
    dxDrawRectangle(x, y + 54 * scale, w, 3, menuMode == "fuel" and tocolor(40, 160, 255) or tocolor(255, 160, 40))
    dxDrawText(menuMode == "fuel" and "BENZİN İSTASYONU" or "TAMİRCİ", x, y + 10 * scale, x + w, y + 50 * scale, tocolor(255, 255, 255), 1.3 * scale, "default-bold", "center", "center")
    dxDrawText(string.format("Yakıt: %.0f%%   |   Sağlık: %.0f", menuFuel, menuHp), x, y + 68 * scale, x + w, y + 92 * scale, tocolor(180, 180, 190), 1.0 * scale, "default", "center", "center")
    if menuMode == "mech" then
        box(bx, y + 100 * scale, bw, 48 * scale, "TAMİR ET  ($" .. menuCost .. ")")
        box(bx, y + 160 * scale, bw, 48 * scale, "+25% YAKIT  ($" .. (25 * FUEL_PRICE) .. ")")
        box(bx, y + 220 * scale, bw, 48 * scale, "KAPAT")
    else
        box(bx, y + 100 * scale, bw, 48 * scale, "+25% YAKIT  ($" .. (25 * FUEL_PRICE) .. ")")
        box(bx, y + 160 * scale, bw, 48 * scale, "DEPOLU DOLDUR")
        box(bx, y + 220 * scale, bw, 48 * scale, "KAPAT")
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("#80C0FF[Araç] #FFFFFFZ Kontak L Far G El freni H Korna | Turuncu=Tamir Mavi=Benzin", 255, 255, 255, true)
end)
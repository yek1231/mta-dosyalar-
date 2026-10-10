--[[ banka - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local points = {}
local doorPoint, exitPoint = nil, nil
local nearInteract = nil
local nearDoor, nearExit = false, false

local open = false
local bankBal, cashBal = 0, 0
local mode = "menu"
local inputText, transferName = "", ""
local typingField = "amount"

local eHold, eHoldStart = false, 0
local HOLD_MS = 450

---------------------
-- NOKTALAR
---------------------
addEvent("bank:setPoints", true)
addEventHandler("bank:setPoints", root, function(list, door, exit)
    points = list or {}
    doorPoint = door
    exitPoint = exit
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("bank:askPoints", localPlayer)
    outputChatBox("#30B45A[Banka] #FFFFFFKapı: yeşil daire + F  |  ATM/NPC: [E] basılı tut", 255, 255, 255, true)
end)

local function dist3(x1, y1, z1, x2, y2, z2)
    return getDistanceBetweenPoints3D(x1, y1, z1, x2, y2, z2)
end

local function getNearestInteract()
    local px, py, pz = getElementPosition(localPlayer)
    local pint, pdim = getElementInterior(localPlayer), getElementDimension(localPlayer)
    local best, bestD
    for _, pt in ipairs(points) do
        if (pt.int or 0) == pint and (pt.dim or 0) == pdim then
            local d = dist3(px, py, pz, pt.x, pt.y, pt.z)
            if d < 2.2 and (not bestD or d < bestD) then
                best, bestD = pt, d
            end
        end
    end
    return best
end

---------------------
-- F = GİR / ÇIK
---------------------
bindKey("f", "down", function()
    if open then return end
    local px, py, pz = getElementPosition(localPlayer)
    local pint, pdim = getElementInterior(localPlayer), getElementDimension(localPlayer)

    if doorPoint and pint == 0 and pdim == 0 then
        if dist3(px, py, pz, doorPoint.x, doorPoint.y, doorPoint.z) < 2.5 then
            triggerServerEvent("bank:enter", localPlayer)
            return
        end
    end

    if exitPoint and pint == (exitPoint.int or 0) and pdim == (exitPoint.dim or 0) then
        if dist3(px, py, pz, exitPoint.x, exitPoint.y, exitPoint.z) < 2.8 then
            triggerServerEvent("bank:exit", localPlayer)
            return
        end
    end
end)

---------------------
-- E = ATM / NPC
---------------------
bindKey("e", "down", function()
    if open then return end
    nearInteract = getNearestInteract()
    if nearInteract then
        eHold = true
        eHoldStart = getTickCount()
    end
end)

bindKey("e", "up", function()
    eHold = false
end)

---------------------
-- MENÜ
---------------------
local function closeBank()
    open = false
    mode = "menu"
    inputText, transferName = "", ""
    showCursor(false)
    guiSetInputEnabled(false)
end

local function openBank()
    if open then return end
    open = true
    mode = "menu"
    eHold = false
    showCursor(true)
    triggerServerEvent("bank:request", localPlayer)
end

addEvent("bank:sync", true)
addEventHandler("bank:sync", root, function(bank, cash)
    bankBal = tonumber(bank) or 0
    cashBal = tonumber(cash) or 0
end)

bindKey("escape", "down", function()
    if open then closeBank() cancelEvent() end
end)

addEventHandler("onClientCharacter", root, function(ch)
    if not open or mode == "menu" then return end
    if typingField == "amount" then
        if ch:match("%d") and #inputText < 9 then inputText = inputText .. ch end
    else
        if #transferName < 24 then transferName = transferName .. ch end
    end
end)

addEventHandler("onClientKey", root, function(btn, press)
    if not open or not press then return end
    if btn == "backspace" and mode ~= "menu" then
        if typingField == "amount" then inputText = inputText:sub(1, -2)
        else transferName = transferName:sub(1, -2) end
    end
end)

local function uiBox(x, y, w, h, label)
    dxDrawRectangle(x, y, w, h, tocolor(28, 48, 40, 240))
    dxDrawText(label, x, y, x + w, y + h, tocolor(255, 255, 255), 1.05 * scale, "default-bold", "center", "center")
end

local function hit(cx, cy, x, y, w, h)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not open or btn ~= "left" or state ~= "down" then return end
    local w, h = 460 * scale, 420 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    local bw, bx = w - 60 * scale, x + 30 * scale

    if mode == "menu" then
        if hit(cx, cy, bx, y + 130 * scale, bw, 48 * scale) then
            mode = "deposit"; inputText = ""; typingField = "amount"; guiSetInputEnabled(true)
        elseif hit(cx, cy, bx, y + 190 * scale, bw, 48 * scale) then
            mode = "withdraw"; inputText = ""; typingField = "amount"; guiSetInputEnabled(true)
        elseif hit(cx, cy, bx, y + 250 * scale, bw, 48 * scale) then
            mode = "transfer"; inputText = ""; transferName = ""; typingField = "name"; guiSetInputEnabled(true)
        elseif hit(cx, cy, bx, y + 320 * scale, bw, 48 * scale) then
            closeBank()
        end
        return
    end

    if mode == "transfer" then
        if hit(cx, cy, bx, y + 150 * scale, bw, 40 * scale) then typingField = "name" end
        if hit(cx, cy, bx, y + 210 * scale, bw, 40 * scale) then typingField = "amount" end
    end

    if hit(cx, cy, bx, y + 280 * scale, bw, 48 * scale) then
        local amount = tonumber(inputText) or 0
        if mode == "deposit" then triggerServerEvent("bank:deposit", localPlayer, amount)
        elseif mode == "withdraw" then triggerServerEvent("bank:withdraw", localPlayer, amount)
        elseif mode == "transfer" then triggerServerEvent("bank:transfer", localPlayer, transferName, amount)
        end
        mode = "menu"; inputText, transferName = "", ""; guiSetInputEnabled(false)
        return
    end

    if hit(cx, cy, bx, y + 340 * scale, bw, 48 * scale) then
        mode = "menu"; inputText, transferName = "", ""; guiSetInputEnabled(false)
    end
end)

---------------------
-- BANKA İKONU (kapı üstü)
---------------------
local function drawBankIcon(sx2, sy2, alpha)
    local s = 52 * scale
    local x, y = sx2 - s / 2, sy2 - s / 2

    if fileExists("img/bank.png") then
        dxDrawImage(x, y, s, s, "img/bank.png", 0, 0, 0, tocolor(255, 255, 255, alpha))
        return
    end

    -- PNG yoksa çizim: yeşil daire + $ 
    dxDrawRectangle(x, y, s, s, tocolor(20, 50, 40, alpha))
    dxDrawRectangle(x, y, s, 3, tocolor(40, 200, 120, alpha))
    dxDrawRectangle(x, y + s - 3, s, 3, tocolor(40, 200, 120, alpha))
    dxDrawRectangle(x, y, 3, s, tocolor(40, 200, 120, alpha))
    dxDrawRectangle(x + s - 3, y, 3, s, tocolor(40, 200, 120, alpha))
    dxDrawText("$", x, y, x + s, y + s, tocolor(80, 255, 160, alpha), 1.6 * scale, "default-bold", "center", "center")
end

---------------------
-- RENDER
---------------------
addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    local pint, pdim = getElementInterior(localPlayer), getElementDimension(localPlayer)

    nearDoor, nearExit = false, false
    nearInteract = not open and getNearestInteract() or nil

    -- E tutma
    if not open and eHold and nearInteract then
        if getTickCount() - eHoldStart >= HOLD_MS then
            openBank()
        end
    end

    -- Kapı yakınlığı + alt yazı
    if not open and doorPoint and pint == 0 and pdim == 0 then
        local d = dist3(px, py, pz, doorPoint.x, doorPoint.y, doorPoint.z)
        if d < 18 then
            local sx2, sy2 = getScreenFromWorldPosition(doorPoint.x, doorPoint.y, doorPoint.z)
            if sx2 then
                drawBankIcon(sx2, sy2 - 10 * scale, d < 2.5 and 240 or 140)
            end
        end
        if d < 2.5 then
            nearDoor = true
            dxDrawText("Girmek için F'ye bas", 0, sy - 70 * scale, sx, sy - 30 * scale, tocolor(80, 255, 160, 240), 1.35 * scale, "default-bold", "center", "center", false, false, true)
        end
    end

    -- Çıkış yazısı (içeride)
    if not open and exitPoint and pint == (exitPoint.int or 0) and pdim == (exitPoint.dim or 0) then
        local d = dist3(px, py, pz, exitPoint.x, exitPoint.y, exitPoint.z)
        if d < 2.8 then
            nearExit = true
            dxDrawText("Çıkmak için F'ye bas", 0, sy - 70 * scale, sx, sy - 30 * scale, tocolor(80, 255, 160, 240), 1.35 * scale, "default-bold", "center", "center", false, false, true)
        end
    end

    -- ATM / NPC [E] kutuları
    if not open then
        for _, pt in ipairs(points) do
            if (pt.int or 0) == pint and (pt.dim or 0) == pdim then
                local d = dist3(px, py, pz, pt.x, pt.y, pt.z)
                if d < 12 then
                    local sx2, sy2 = getScreenFromWorldPosition(pt.x, pt.y, pt.z)
                    if sx2 then
                        local size = 36 * scale
                        local alpha = d < 2.2 and 230 or 120
                        local active = (nearInteract == pt)
                        dxDrawRectangle(sx2 - size / 2, sy2 - size / 2, size, size, active and tocolor(40, 200, 120, alpha) or tocolor(20, 30, 25, alpha))
                        local edge = tocolor(80, 255, 160, alpha)
                        dxDrawRectangle(sx2 - size / 2, sy2 - size / 2, size, 2, edge)
                        dxDrawRectangle(sx2 - size / 2, sy2 + size / 2 - 2, size, 2, edge)
                        dxDrawRectangle(sx2 - size / 2, sy2 - size / 2, 2, size, edge)
                        dxDrawRectangle(sx2 + size / 2 - 2, sy2 - size / 2, 2, size, edge)
                        dxDrawText("E", sx2 - size / 2, sy2 - size / 2, sx2 + size / 2, sy2 + size / 2, tocolor(255, 255, 255, alpha), 1.3 * scale, "default-bold", "center", "center")
                        if d < 2.2 then
                            dxDrawText(pt.typ == "npc" and "Görevli" or "ATM", sx2 - 40, sy2 + size / 2 + 4, sx2 + 40, sy2 + size / 2 + 22, tocolor(200, 255, 220, alpha), 0.9 * scale, "default", "center", "top")
                        end
                        if eHold and nearInteract == pt then
                            local prog = math.min(1, (getTickCount() - eHoldStart) / HOLD_MS)
                            local bw = 50 * scale
                            dxDrawRectangle(sx2 - bw / 2, sy2 + size / 2 + 24, bw, 6, tocolor(0, 0, 0, 180))
                            dxDrawRectangle(sx2 - bw / 2, sy2 + size / 2 + 24, bw * prog, 6, tocolor(40, 200, 120, 255))
                        end
                    end
                end
            end
        end
    end

    if not open then return end

    -- Menü
    local w, h = 460 * scale, 420 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    local bw, bx = w - 60 * scale, x + 30 * scale

    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 160))
    dxDrawRectangle(x, y, w, h, tocolor(12, 20, 18, 250))
    dxDrawRectangle(x, y, w, 70 * scale, tocolor(20, 50, 40, 255))
    dxDrawRectangle(x, y + 68 * scale, w, 3, tocolor(40, 200, 120))
    dxDrawText("ROASTER BANK", x, y + 10 * scale, x + w, y + 40 * scale, tocolor(80, 255, 160), 1.4 * scale, "default-bold", "center", "center")
    dxDrawText("Banka: $" .. bankBal .. "   |   Cep: $" .. cashBal, x, y + 40 * scale, x + w, y + 65 * scale, tocolor(180, 220, 200), 1.0 * scale, "default", "center", "center")

    if mode == "menu" then
        uiBox(bx, y + 130 * scale, bw, 48 * scale, "PARA YATIR")
        uiBox(bx, y + 190 * scale, bw, 48 * scale, "PARA ÇEK")
        uiBox(bx, y + 250 * scale, bw, 48 * scale, "HAVALE")
        uiBox(bx, y + 320 * scale, bw, 48 * scale, "KAPAT")
    else
        dxDrawText(mode == "deposit" and "YATIR" or (mode == "withdraw" and "ÇEK" or "HAVALE"), x, y + 95 * scale, x + w, y + 125 * scale, tocolor(255, 255, 255), 1.15 * scale, "default-bold", "center", "center")
        if mode == "transfer" then
            dxDrawRectangle(bx, y + 150 * scale, bw, 40 * scale, typingField == "name" and tocolor(40, 70, 55, 255) or tocolor(24, 36, 30, 255))
            dxDrawText(transferName == "" and "Oyuncu adı..." or transferName, bx + 10 * scale, y + 150 * scale, bx + bw, y + 190 * scale, tocolor(255, 255, 255), 1.0 * scale, "default", "left", "center")
            dxDrawRectangle(bx, y + 210 * scale, bw, 40 * scale, typingField == "amount" and tocolor(40, 70, 55, 255) or tocolor(24, 36, 30, 255))
            dxDrawText(inputText == "" and "$0" or ("$" .. inputText), bx + 10 * scale, y + 210 * scale, bx + bw, y + 250 * scale, tocolor(255, 255, 255), 1.1 * scale, "default-bold", "left", "center")
        else
            dxDrawRectangle(bx, y + 150 * scale, bw, 50 * scale, tocolor(24, 36, 30, 255))
            dxDrawText(inputText == "" and "$0" or ("$" .. inputText), bx, y + 150 * scale, bx + bw, y + 200 * scale, tocolor(255, 255, 255), 1.4 * scale, "default-bold", "center", "center")
        end
        uiBox(bx, y + 280 * scale, bw, 48 * scale, "ONAYLA")
        uiBox(bx, y + 340 * scale, bw, 48 * scale, "GERİ")
    end
end)
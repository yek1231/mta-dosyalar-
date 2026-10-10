--[[ balikcilik - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local shopOpen = false
local hasRod, baitCount, fishList = false, 0, {}

local fishing = false
local aiming = false
local powering = false
local power = 0
local powerDir = 1
local castPending = false
local resultText, resultTick = nil, 0
local rodObject = nil

local CONTROLS = { "fire", "action", "aim_weapon", "next_weapon", "previous_weapon", "enter_exit" }

---------------------
-- KONTROL KİLİT
---------------------
local function lockCombat(state)
    for _, c in ipairs(CONTROLS) do
        toggleControl(c, not state) -- state=true → kilitle (false yap)
    end
end

---------------------
-- OLTA
---------------------
local function destroyRod()
    if isElement(rodObject) then
        destroyElement(rodObject)
    end
    rodObject = nil
end

local function giveRodInHand()
    destroyRod()

    -- 338 = bilardo sopası (olta gibi)
    rodObject = createObject(338, 0, 0, 0)
    if not rodObject then
        outputChatBox("[Balık] Olta modeli oluşturulamadı.", 255, 80, 80)
        return
    end
    setElementCollisionsEnabled(rodObject, false)
    setObjectScale(rodObject, 1.0)
    setElementDoubleSided(rodObject, true)

    local attached = false

    -- 1) bone_attach
    if not attached then
        local ok = pcall(function()
            exports.bone_attach:attachElementToBone(rodObject, localPlayer, 12, 0.05, 0.02, 0.08, 0, 270, 0)
        end)
        if ok then attached = true end
    end

    -- 2) pAttach
    if not attached then
        local ok = pcall(function()
            exports.pAttach:attach(rodObject, localPlayer, 12, 0.05, 0.02, 0.08, 0, 270, 0)
        end)
        if ok then attached = true end
    end

    -- 3) Basit attach (mutlaka çalışır)
    if not attached then
        attachElements(rodObject, localPlayer, 0.2, 0.4, -0.05, -10, 20, 100)
    end
end

---------------------
-- SYNC / SHOP
---------------------
addEvent("balik:sync", true)
addEventHandler("balik:sync", root, function(rod, bait, _, list)
    hasRod = rod and true or false
    baitCount = bait or 0
    fishList = list or {}
end)

addEvent("balik:openShop", true)
addEventHandler("balik:openShop", root, function()
    shopOpen = true
    showCursor(true)
    triggerServerEvent("balik:requestSync", localPlayer)
end)

local function closeShop()
    shopOpen = false
    showCursor(false)
end

local shopBtns = {
    { id = "rod",   label = "OLTA AL ($150)" },
    { id = "bait",  label = "YEM AL x5 ($125)" },
    { id = "sell",  label = "BALIKLARI SAT" },
    { id = "fish",  label = "BALIK TUTMAYA BAŞLA" },
    { id = "close", label = "KAPAT" },
}

local function drawShop()
    local w, h = 420 * scale, 380 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 160))
    dxDrawRectangle(x, y, w, h, tocolor(14, 18, 28, 250))
    dxDrawRectangle(x, y, w, 54 * scale, tocolor(20, 40, 70, 255))
    dxDrawRectangle(x, y + 52 * scale, w, 3, tocolor(40, 140, 255))
    dxDrawText("BALIKÇI LİMANI", x, y + 8 * scale, x + w, y + 48 * scale, tocolor(120, 200, 255), 1.4 * scale, "default-bold", "center", "center")
    dxDrawText(
        (hasRod and "Olta: Var" or "Olta: Yok") .. "  |  Yem: " .. baitCount .. "  |  Balık: " .. #fishList,
        x, y + 62 * scale, x + w, y + 90 * scale,
        tocolor(180, 200, 220), 1.0 * scale, "default", "center", "center"
    )
    for i, b in ipairs(shopBtns) do
        local by = y + 100 * scale + (i - 1) * 48 * scale
        dxDrawRectangle(x + 30 * scale, by, w - 60 * scale, 42 * scale, tocolor(30, 50, 80, 240))
        dxDrawText(b.label, x + 30 * scale, by, x + w - 30 * scale, by + 42 * scale, tocolor(255, 255, 255), 1.1 * scale, "default-bold", "center", "center")
    end
end

---------------------
-- BALIK TUTMA
---------------------
function startFishing()
    if fishing then return end
    if not hasRod then
        outputChatBox("[Balık] Önce olta al.", 255, 80, 80)
        return
    end
    if baitCount < 1 then
        outputChatBox("[Balık] Yemin yok, limandan al.", 255, 80, 80)
        return
    end

    fishing = true
    aiming = false
    powering = false
    power = 0
    castPending = false

    lockCombat(true)          -- yumruk / ateş kapat
    setPedWeaponSlot(localPlayer, 0)
    giveRodInHand()

    outputChatBox("#40A0FF[Balık] #FFFFFFSağ tık: nişan  |  Sol tık basılı: güç  |  Bırak: at  |  Backspace: bırak", 255, 255, 255, true)
end

function stopFishing()
    fishing = false
    aiming = false
    powering = false
    castPending = false
    destroyRod()
    lockCombat(false)         -- kontrolleri geri aç
end

-- Sağ tık = nişan (oyun yumruğunu engelledik)
bindKey("mouse2", "down", function()
    if fishing and not castPending then
        aiming = true
    end
end)
bindKey("mouse2", "up", function()
    aiming = false
end)

-- Sol tık = güç
bindKey("mouse1", "down", function()
    if not fishing or castPending then return end
    if not aiming then
        outputChatBox("[Balık] Önce sağ tık ile nişan al.", 255, 180, 80)
        return
    end
    powering = true
    power = 10
    powerDir = 1
end)

bindKey("mouse1", "up", function()
    if not fishing or not powering or castPending then return end
    powering = false
    castPending = true
    aiming = false
    outputChatBox("[Balık] Olta atıldı... Bekle", 100, 180, 255)
    setTimer(function()
        if fishing then
            triggerServerEvent("balik:tryCatch", localPlayer, power)
        end
    end, 1500 + math.random(800, 1800), 1)
end)

bindKey("backspace", "down", function()
    if fishing then
        stopFishing()
        outputChatBox("[Balık] Avlanmayı bıraktın.", 255, 180, 80)
    end
end)

bindKey("escape", "down", function()
    if shopOpen then
        closeShop()
        cancelEvent()
    end
end)

addEvent("balik:catchResult", true)
addEventHandler("balik:catchResult", root, function(ok, a, b, c)
    castPending = false
    if ok then
        resultText = "TUTTUNUZ: " .. tostring(a) .. "  (" .. tostring(b) .. " kg)  $" .. tostring(c)
        resultTick = getTickCount()
        playSoundFrontEnd(5)
    else
        resultText = a or "Balık kaçtı..."
        resultTick = getTickCount()
        playSoundFrontEnd(4)
    end
end)

---------------------
-- SHOP TIK
---------------------
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not shopOpen or btn ~= "left" or state ~= "down" then return end
    local w, h = 420 * scale, 380 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    for i, b in ipairs(shopBtns) do
        local by = y + 100 * scale + (i - 1) * 48 * scale
        if cx >= x + 30 * scale and cx <= x + w - 30 * scale and cy >= by and cy <= by + 42 * scale then
            if b.id == "rod" then
                triggerServerEvent("balik:buyRod", localPlayer)
            elseif b.id == "bait" then
                triggerServerEvent("balik:buyBait", localPlayer, 5)
            elseif b.id == "sell" then
                triggerServerEvent("balik:sellAll", localPlayer)
            elseif b.id == "fish" then
                closeShop()
                startFishing()
            elseif b.id == "close" then
                closeShop()
            end
            return
        end
    end
end)

---------------------
-- RENDER
---------------------
addEventHandler("onClientRender", root, function()
    if shopOpen then
        drawShop()
        return
    end

    if resultText and getTickCount() - resultTick < 3500 then
        local alpha = 255
        local age = getTickCount() - resultTick
        if age > 2500 then
            alpha = math.floor(255 * (1 - (age - 2500) / 1000))
        end
        dxDrawText(resultText, 0, 40 * scale, sx, 100 * scale, tocolor(80, 220, 255, alpha), 1.6 * scale, "default-bold", "center", "top", false, false, true)
    end

    if not fishing then return end

    -- Olta hâlâ yoksa tekrar dene (nadiren stream)
    if not isElement(rodObject) then
        giveRodInHand()
    end

    dxDrawText("BALIK TUTMA  |  Backspace = bırak", 0, sy - 50 * scale, sx, sy - 20 * scale, tocolor(180, 200, 220, 220), 1.0 * scale, "default", "center", "center")

    if aiming and not powering and not castPending then
        dxDrawText("NİŞAN — Sol tık basılı tut", 0, sy * 0.55, sx, sy * 0.55 + 30, tocolor(255, 220, 80), 1.2 * scale, "default-bold", "center", "center")
    end

    if powering then
        power = power + powerDir * 2.2
        if power >= 100 then power = 100 powerDir = -1 end
        if power <= 10 then power = 10 powerDir = 1 end

        local bw, bh = 280 * scale, 22 * scale
        local bx, by = (sx - bw) / 2, sy * 0.62
        dxDrawRectangle(bx - 2, by - 2, bw + 4, bh + 4, tocolor(0, 0, 0, 180))
        dxDrawRectangle(bx, by, bw, bh, tocolor(40, 40, 50, 220))
        local col = tocolor(40, 180, 255)
        if power > 70 then col = tocolor(80, 255, 120) end
        if power > 90 then col = tocolor(255, 80, 40) end
        dxDrawRectangle(bx, by, bw * (power / 100), bh, col)
        dxDrawText("GÜÇ " .. math.floor(power) .. "%", bx, by - 28 * scale, bx + bw, by, tocolor(255, 255, 255), 1.1 * scale, "default-bold", "center", "center")
    end

    if castPending then
        dxDrawText("Olta suda... Bekleniyor", 0, sy * 0.58, sx, sy * 0.58 + 30, tocolor(100, 180, 255), 1.2 * scale, "default-bold", "center", "center")
    end
end)

addEventHandler("onClientPlayerWasted", localPlayer, function()
    if fishing then stopFishing() end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    destroyRod()
    lockCombat(false)
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("#40A0FF[Balıkçılık] #FFFFFFLiman mavi işaret | F2 → Balıkçı", 255, 255, 255, true)
end)
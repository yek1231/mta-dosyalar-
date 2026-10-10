--[[ f1menu - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local menuOpen, invOpen, jobOpen = false, false, false
local selected, invSelected, jobSelected = 1, 1, 1
local menuItems, jobItems = {}, {}
local inv = {}
local isAdmin = false
local jobData = { job = "issiz", jobLabel = "İşsiz", xp = 0, level = 1 }

-- Sürükle-bırak
local dragging = false
local dragSlot = nil
local dragItem = nil
local lastClickSlot, lastClickTime = nil, 0

local itemImages = {
    Telefon = "img/telefon.png",
    Kimlik  = "img/kimlik.png",
    Su      = "img/su.png",
    Ekmek   = "img/ekmek.png",
    Anahtar = "img/anahtar.png",
}

local function buildMenu()
    local t = {
        { id = "kimlik",   label = "KİMLİK",    desc = "Karakter kartın",    icon = "ID" },
        { id = "envanter", label = "ENVANTER",  desc = "Eşya grid'i",        icon = "IN" },
        { id = "anim",     label = "ANİMASYON", desc = "/anim dans el otur", icon = "AN" },
        { id = "arac",     label = "ARAÇ",      desc = "Araç durumu",        icon = "AR" },
        { id = "yardim",   label = "KURALLAR",  desc = "RP kuralları",       icon = "??" },
    }
    if isAdmin then
        table.insert(t, { id = "admin", label = "ADMIN", desc = "Yetkili", icon = "AD" })
    end
    table.insert(t, { id = "kapat", label = "KAPAT", desc = "Menüyü kapat", icon = "X" })
    return t
end

local function buildJobs()
    return {
        { id = "issiz", label = "İŞSİZ",       desc = "Mesleği bırak",   col = tocolor(120, 120, 130) },
        { id = "balik", label = "BALIKÇI",     desc = "Balık tut & sat", col = tocolor(40, 140, 255) },
        { id = "pizza", label = "PİZZA KURYE", desc = "Pizza dağıt",     col = tocolor(255, 140, 40) },
        { id = "kargo", label = "KARGO",       desc = "Paket taşı",      col = tocolor(255, 200, 40) },
        { id = "tamir", label = "TAMİRCİ",     desc = "Araç tamir et",   col = tocolor(80, 255, 120) },
        { id = "taksi", label = "TAKSİCİ",     desc = "Yolcu taşı",      col = tocolor(255, 220, 50) },
    }
end

local function openMenu()
    if invOpen or jobOpen then return end
    menuOpen = true
    selected = 1
    menuItems = buildMenu()
    showCursor(true)
end

local function closeMenu()
    menuOpen = false
    showCursor(false)
end

local function openInv()
    menuOpen = false
    invOpen = true
    invSelected = 1
    dragging = false
    triggerServerEvent("f1:requestInv", localPlayer)
    showCursor(true)
end

local function closeInv()
    invOpen = false
    dragging = false
    showCursor(false)
end

local function openJob()
    if invOpen then return end
    menuOpen = false
    jobOpen = true
    jobSelected = 1
    jobItems = buildJobs()
    triggerServerEvent("f2:requestJob", localPlayer)
    showCursor(true)
end

local function closeJob()
    jobOpen = false
    showCursor(false)
end

local function closeAll()
    menuOpen, invOpen, jobOpen, dragging = false, false, false, false
    showCursor(false)
end

---------------------
-- TUŞLAR
---------------------
bindKey("F1", "down", function()
    if invOpen then closeInv() return end
    if jobOpen then closeJob() return end
    if menuOpen then closeMenu() else openMenu() end
end)

bindKey("F2", "down", function()
    if invOpen then return end
    if jobOpen then closeJob() else openJob() end
end)

bindKey("arrow_u", "down", function()
    if menuOpen then
        selected = selected - 1
        if selected < 1 then selected = #menuItems end
    elseif jobOpen then
        jobSelected = jobSelected - 1
        if jobSelected < 1 then jobSelected = #jobItems end
    elseif invOpen then
        invSelected = invSelected - 9
        if invSelected < 1 then invSelected = invSelected + 36 end
    end
end)

bindKey("arrow_d", "down", function()
    if menuOpen then
        selected = selected + 1
        if selected > #menuItems then selected = 1 end
    elseif jobOpen then
        jobSelected = jobSelected + 1
        if jobSelected > #jobItems then jobSelected = 1 end
    elseif invOpen then
        invSelected = invSelected + 9
        if invSelected > 36 then invSelected = invSelected - 36 end
    end
end)

bindKey("arrow_l", "down", function()
    if invOpen then
        invSelected = invSelected - 1
        if invSelected < 1 then invSelected = 36 end
    end
end)

bindKey("arrow_r", "down", function()
    if invOpen then
        invSelected = invSelected + 1
        if invSelected > 36 then invSelected = 1 end
    end
end)

bindKey("i", "down", function()
    if menuOpen or jobOpen then return end
    if invOpen then
        closeInv()
    else
        openInv()
    end
end)

bindKey("enter", "down", function()
    if menuOpen then
        local it = menuItems[selected]
        if not it then return end
        if it.id == "kapat" then closeMenu()
        elseif it.id == "envanter" then openInv()
        elseif it.id == "kimlik" then triggerServerEvent("f1:kimlik", localPlayer)
        elseif it.id == "arac" then triggerServerEvent("f1:arac", localPlayer)
        elseif it.id == "admin" then triggerServerEvent("f1:admin", localPlayer)
        elseif it.id == "anim" then outputChatBox("[F1] /anim dans | /anim el | /anim otur", 255, 180, 80)
        elseif it.id == "yardim" then outputChatBox("[F1] RP kurallarına uy.", 255, 180, 80)
        end
    elseif jobOpen then
        local it = jobItems[jobSelected]
        if it then
            triggerServerEvent("f2:selectJob", localPlayer, it.id)
            closeJob()
        end
    end
end)

bindKey("escape", "down", function()
    if menuOpen or invOpen or jobOpen then
        closeAll()
        cancelEvent()
    end
end)


---------------------
-- ENVANTER GEOMETRİ
---------------------
local function getInvLayout()
    local cols, rows = 9, 4
    local slot = 70 * scale
    local pad = 10 * scale
    local gridW = cols * (slot + pad) + pad
    local gridH = rows * (slot + pad) + pad
    local panelW = gridW + 60 * scale
    local panelH = gridH + 160 * scale
    local x = (sx - panelW) / 2
    local y = (sy - panelH) / 2
    local gx, gy = x + 30 * scale, y + 78 * scale
    return cols, slot, pad, panelW, panelH, x, y, gx, gy
end

local function getSlotAt(cx, cy)
    local cols, slot, pad, _, _, _, _, gx, gy = getInvLayout()
    for i = 1, 36 do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local sx_ = gx + col * (slot + pad)
        local sy_ = gy + row * (slot + pad)
        if cx >= sx_ and cx <= sx_ + slot and cy >= sy_ and cy <= sy_ + slot then
            return i, sx_, sy_, slot
        end
    end
    return nil
end

---------------------
-- MOUSE
---------------------
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not invOpen then return end

    if btn == "left" then
        if state == "down" then
            local slot = getSlotAt(cx, cy)
            if slot then
                invSelected = slot
                local now = getTickCount()
                -- Çift tık = kullan
                if lastClickSlot == slot and (now - lastClickTime) < 350 then
                    if inv[slot] then
                        triggerServerEvent("f1:useItem", localPlayer, slot)
                    end
                    lastClickSlot, lastClickTime = nil, 0
                    dragging = false
                    return
                end
                lastClickSlot, lastClickTime = slot, now

                -- Sürükleme başlat
                if inv[slot] then
                    dragging = true
                    dragSlot = slot
                    dragItem = inv[slot]
                end
            end
        elseif state == "up" then
            if dragging and dragSlot and dragItem then
                -- Envanter panelinin dışında mı?
                local _, _, _, panelW, panelH, px, py = getInvLayout()
                local inside = (cx >= px and cx <= px + panelW and cy >= py and cy <= py + panelH)

                if not inside then
                    -- Yakında oyuncu var mı?
                    local nearest, nearDist
                    local px3, py3, pz3 = getElementPosition(localPlayer)
                    for _, pl in ipairs(getElementsByType("player")) do
                        if pl ~= localPlayer then
                            local x, y, z = getElementPosition(pl)
                            local d = getDistanceBetweenPoints3D(px3, py3, pz3, x, y, z)
                            if d < 4 and (not nearDist or d < nearDist) then
                                nearest, nearDist = pl, d
                            end
                        end
                    end

                    if nearest then
                        triggerServerEvent("f1:giveToPlayer", localPlayer, dragSlot, nearest)
                    else
                        triggerServerEvent("f1:dropToWorld", localPlayer, dragSlot)
                    end
                end
            end
            dragging = false
            dragSlot = nil
            dragItem = nil
        end
    end
end)

---------------------
-- EVENTLER
---------------------
addEvent("f1:syncInv", true)
addEventHandler("f1:syncInv", root, function(data)
    inv = data or {}
end)

addEvent("f2:syncJob", true)
addEventHandler("f2:syncJob", root, function(d)
    jobData = d or jobData
end)

addEvent("f1:setAdmin", true)
addEventHandler("f1:setAdmin", root, function(v)
    isAdmin = v and true or false
end)

---------------------
-- ÇİZİM
---------------------
local function drawMenu()
    local w = 440 * scale
    local h = (52 + #menuItems * 56 + 36) * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 150))
    dxDrawRectangle(x, y, w, h, tocolor(16, 16, 22, 250))
    dxDrawRectangle(x, y, w, 52 * scale, tocolor(10, 10, 14, 255))
    dxDrawRectangle(x, y + 50 * scale, w, 3, tocolor(255, 80, 20))
    dxDrawText("ROASTER RP", x, y + 6 * scale, x + w, y + 28 * scale, tocolor(255, 80, 20), 1.3 * scale, "default-bold", "center", "center")
    dxDrawText("F1 MENÜ", x, y + 28 * scale, x + w, y + 48 * scale, tocolor(140, 140, 150), 0.95 * scale, "default", "center", "center")
    for i, it in ipairs(menuItems) do
        local iy = y + 60 * scale + (i - 1) * 56 * scale
        local sel = (i == selected)
        dxDrawRectangle(x + 14 * scale, iy, w - 28 * scale, 50 * scale, sel and tocolor(255, 80, 20, 55) or tocolor(24, 24, 30, 240))
        if sel then dxDrawRectangle(x + 14 * scale, iy, 4 * scale, 50 * scale, tocolor(255, 80, 20)) end
        dxDrawText(it.icon or "?", x + 26 * scale, iy + 8 * scale, x + 60 * scale, iy + 42 * scale, sel and tocolor(255, 150, 50) or tocolor(140, 140, 150), 0.85 * scale, "default-bold", "center", "center")
        dxDrawText(it.label, x + 72 * scale, iy + 6 * scale, x + w - 24 * scale, iy + 28 * scale, tocolor(255, 255, 255), 1.1 * scale, "default-bold", "left", "center")
        dxDrawText(it.desc or "", x + 72 * scale, iy + 26 * scale, x + w - 24 * scale, iy + 46 * scale, tocolor(140, 140, 150), 0.9 * scale, "default", "left", "center")
    end
end

local function drawBigInv()
    local cols, slot, pad, panelW, panelH, x, y, gx, gy = getInvLayout()

    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 200))
    dxDrawRectangle(x, y, panelW, panelH, tocolor(16, 16, 22, 252))
    dxDrawRectangle(x, y, panelW, 60 * scale, tocolor(10, 10, 14, 255))
    dxDrawRectangle(x, y + 58 * scale, panelW, 3, tocolor(255, 80, 20))
    dxDrawText("ENVANTER", x, y + 14 * scale, x + panelW, y + 52 * scale, tocolor(255, 255, 255), 1.5 * scale, "default-bold", "center", "center")

    for i = 1, 36 do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local sx_ = gx + col * (slot + pad)
        local sy_ = gy + row * (slot + pad)
        local it = inv[i]
        local hover = (i == invSelected)
        local isDrag = (dragging and dragSlot == i)

        dxDrawRectangle(sx_, sy_, slot, slot, hover and tocolor(255, 80, 20, 90) or tocolor(34, 34, 44, 255))
        local br = hover and tocolor(255, 100, 30) or tocolor(60, 60, 72)
        dxDrawRectangle(sx_, sy_, slot, 2, br)
        dxDrawRectangle(sx_, sy_ + slot - 2, slot, 2, br)
        dxDrawRectangle(sx_, sy_, 2, slot, br)
        dxDrawRectangle(sx_ + slot - 2, sy_, 2, slot, br)

        if it and it.name and not isDrag then
            local imgPath = itemImages[it.name]
            if imgPath and fileExists(imgPath) then
                dxDrawImage(sx_ + 8 * scale, sy_ + 6 * scale, slot - 16 * scale, slot * 0.5, imgPath)
            else
                dxDrawText(it.icon or string.sub(it.name, 1, 2), sx_, sy_ + 8 * scale, sx_ + slot, sy_ + slot * 0.5, tocolor(255, 150, 50), 1.3 * scale, "default-bold", "center", "center")
            end
            dxDrawText(it.name, sx_ + 2, sy_ + slot * 0.55, sx_ + slot - 2, sy_ + slot * 0.78, tocolor(230, 230, 230), 0.75 * scale, "default", "center", "center")
            if it.amount and it.amount > 1 then
                dxDrawText("x" .. it.amount, sx_, sy_ + slot * 0.75, sx_ + slot - 6 * scale, sy_ + slot, tocolor(255, 220, 80), 0.95 * scale, "default-bold", "right", "bottom")
            end
        end
    end

    -- Sürüklenen eşya imleçte
    if dragging and dragItem then
        local cx, cy = getCursorPosition()
        if cx then
            cx, cy = cx * sx, cy * sy
            local s = 50 * scale
            dxDrawRectangle(cx - s / 2, cy - s / 2, s, s, tocolor(255, 80, 20, 180))
            dxDrawText(dragItem.icon or "?", cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2, tocolor(255, 255, 255), 1.2 * scale, "default-bold", "center", "center")
            dxDrawText(dragItem.name, cx - 60, cy + s / 2 + 4, cx + 60, cy + s / 2 + 24, tocolor(255, 255, 255), 0.9 * scale, "default", "center", "top")
        end
    end

    local cur = inv[invSelected]
    local info = "Tek tık: seç  ·  Çift tık: kullan  ·  Sürükle dışarı: yere at / oyuncuya ver  ·  /al = yerden al"
    if cur then
        info = cur.name .. (cur.amount and (" x" .. cur.amount) or "") .. (cur.desc and (" · " .. cur.desc) or "")
    end
    dxDrawText(info, x, y + panelH - 48 * scale, x + panelW, y + panelH - 18 * scale, tocolor(160, 160, 170), 0.95 * scale, "default", "center", "center")
end

local function drawJobMenu()
    local w = 520 * scale
    local h = (90 + #jobItems * 58 + 40) * scale
    local x = (sx - w) / 2
    local y = (sy - h) / 2
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 175))
    dxDrawRectangle(x, y, w, h, tocolor(16, 16, 22, 250))
    dxDrawRectangle(x, y, w, 66 * scale, tocolor(10, 10, 14, 255))
    dxDrawRectangle(x, y + 64 * scale, w, 3, tocolor(255, 80, 20))
    dxDrawText("MESLEK SEÇİMİ", x, y + 10 * scale, x + w, y + 38 * scale, tocolor(255, 255, 255), 1.35 * scale, "default-bold", "center", "center")
    dxDrawText(jobData.jobLabel .. "  |  Seviye " .. jobData.level .. "  |  XP " .. jobData.xp .. "/" .. (jobData.level * 100), x, y + 38 * scale, x + w, y + 62 * scale, tocolor(255, 140, 40), 1.0 * scale, "default", "center", "center")
    for i, it in ipairs(jobItems) do
        local iy = y + 80 * scale + (i - 1) * 58 * scale
        local sel = (i == jobSelected)
        dxDrawRectangle(x + 14 * scale, iy, w - 28 * scale, 52 * scale, sel and tocolor(255, 80, 20, 50) or tocolor(24, 24, 30, 240))
        if sel then dxDrawRectangle(x + 14 * scale, iy, 5 * scale, 52 * scale, it.col or tocolor(255, 80, 20)) end
        dxDrawText(it.label, x + 30 * scale, iy + 6 * scale, x + w - 20 * scale, iy + 30 * scale, tocolor(255, 255, 255), 1.15 * scale, "default-bold", "left", "center")
        dxDrawText(it.desc, x + 30 * scale, iy + 28 * scale, x + w - 20 * scale, iy + 50 * scale, tocolor(140, 140, 150), 0.95 * scale, "default", "left", "center")
    end
end

-- Yerdeki eşya isim etiketi
addEventHandler("onClientRender", root, function()
    if menuOpen then drawMenu() end
    if invOpen then drawBigInv() end
    if jobOpen then drawJobMenu() end

    -- Dünya eşya etiketleri
    local px, py, pz = getElementPosition(localPlayer)
    for _, obj in ipairs(getElementsByType("object", root, true)) do
        local id = getElementData(obj, "f1:worldItemId")
        if id then
            local ox, oy, oz = getElementPosition(obj)
            local d = getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz)
            if d < 25 then
                local sx2, sy2 = getScreenFromWorldPosition(ox, oy, oz + 0.5)
                if sx2 then
                    local name = getElementData(obj, "f1:worldItemName") or "Eşya"
                    dxDrawText(name .. "  [/al]", sx2 - 60, sy2 - 12, sx2 + 60, sy2 + 12, tocolor(255, 200, 80, 220), 1.0, "default-bold", "center", "center")
                end
            end
        end
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("#00FF00[f1menu] Yüklendi. F1=Menü F2=Meslek | Envanter: tek tık seç, çift tık kullan, sürükle at", 255, 255, 255, true)
end)
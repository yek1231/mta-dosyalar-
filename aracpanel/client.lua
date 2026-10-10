--[[ aracpanel - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local open = false
local list = {}
local selected = 1

local function openPanel()
    open = true
    selected = 1
    showCursor(true)
    triggerServerEvent("aracpanel:request", localPlayer)
end

local function closePanel()
    open = false
    showCursor(false)
end

-- F3 panel
bindKey("F3", "down", function()
    if open then closePanel() else openPanel() end
end)

bindKey("escape", "down", function()
    if open then closePanel() cancelEvent() end
end)

bindKey("arrow_u", "down", function()
    if not open then return end
    selected = selected - 1
    if selected < 1 then selected = math.max(1, #list) end
end)

bindKey("arrow_d", "down", function()
    if not open then return end
    selected = selected + 1
    if selected > #list then selected = 1 end
end)

bindKey("enter", "down", function()
    if not open or not list[selected] then return end
    local it = list[selected]
    if it.spawned then
        triggerServerEvent("aracpanel:despawn", localPlayer, it.plate)
    else
        triggerServerEvent("aracpanel:call", localPlayer, it.plate)
    end
end)

addEvent("aracpanel:list", true)
addEventHandler("aracpanel:list", root, function(data)
    list = data or {}
    if selected > #list then selected = math.max(1, #list) end
end)

local function hit(cx, cy, x, y, w, h)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not open or btn ~= "left" or state ~= "down" then return end
    local w, h = 480 * scale, 400 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2

    for i, it in ipairs(list) do
        local iy = y + 70 * scale + (i - 1) * 48 * scale
        if hit(cx, cy, x + 16 * scale, iy, w - 32 * scale, 44 * scale) then
            selected = i
            return
        end
    end

    -- çağır / çek
    if hit(cx, cy, x + 16 * scale, y + h - 58 * scale, 200 * scale, 42 * scale) then
        local it = list[selected]
        if it then
            if it.spawned then
                triggerServerEvent("aracpanel:despawn", localPlayer, it.plate)
            else
                triggerServerEvent("aracpanel:call", localPlayer, it.plate)
            end
        end
        return
    end
    if hit(cx, cy, x + w - 160 * scale, y + h - 58 * scale, 140 * scale, 42 * scale) then
        closePanel()
    end
end)

addEventHandler("onClientRender", root, function()
    if not open then return end

    local w, h = 480 * scale, 400 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2

    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 150))
    dxDrawRectangle(x, y, w, h, tocolor(14, 16, 22, 250))
    dxDrawRectangle(x, y, w, 52 * scale, tocolor(20, 30, 45, 255))
    dxDrawRectangle(x, y + 50 * scale, w, 3, tocolor(80, 160, 255))
    dxDrawText("ARAÇLARIM", x, y + 8 * scale, x + w, y + 48 * scale, tocolor(120, 190, 255), 1.3 * scale, "default-bold", "center", "center")

    if #list == 0 then
        dxDrawText("Kayıtlı aracın yok.\nGaleriden satın al.", x, y + 120 * scale, x + w, y + 200 * scale, tocolor(150, 160, 180), 1.1 * scale, "default", "center", "center")
    else
        for i, it in ipairs(list) do
            local iy = y + 70 * scale + (i - 1) * 48 * scale
            if iy > y + h - 80 * scale then break end
            local sel = (i == selected)
            dxDrawRectangle(x + 16 * scale, iy, w - 32 * scale, 44 * scale, sel and tocolor(40, 80, 140, 220) or tocolor(28, 32, 40, 220))
            dxDrawText(it.name or "Araç", x + 28 * scale, iy + 4 * scale, x + w - 100 * scale, iy + 24 * scale, tocolor(255, 255, 255), 1.0 * scale, "default-bold", "left", "center")
            dxDrawText(it.plate or "?", x + 28 * scale, iy + 22 * scale, x + w - 100 * scale, iy + 42 * scale, tocolor(160, 190, 220), 0.9 * scale, "default", "left", "center")
            local st = it.spawned and "DÜNYADA" or "GARAJ"
            local sc = it.spawned and tocolor(80, 255, 140) or tocolor(180, 180, 100)
            dxDrawText(st, x + w - 120 * scale, iy, x + w - 28 * scale, iy + 44 * scale, sc, 0.9 * scale, "default-bold", "right", "center")
        end
    end

    local it = list[selected]
    local btnText = (it and it.spawned) and "ÇEK (ENTER)" or "ÇAĞIR (ENTER)"
    dxDrawRectangle(x + 16 * scale, y + h - 58 * scale, 200 * scale, 42 * scale, tocolor(30, 90, 140, 255))
    dxDrawText(btnText, x + 16 * scale, y + h - 58 * scale, x + 216 * scale, y + h - 16 * scale, tocolor(255, 255, 255), 1.0 * scale, "default-bold", "center", "center")

    dxDrawRectangle(x + w - 160 * scale, y + h - 58 * scale, 140 * scale, 42 * scale, tocolor(60, 40, 40, 255))
    dxDrawText("KAPAT", x + w - 160 * scale, y + h - 58 * scale, x + w - 20 * scale, y + h - 16 * scale, tocolor(255, 255, 255), 1.0 * scale, "default-bold", "center", "center")
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("#80C0FF[Araç Panel] #FFFFFFF3 ile aç — çağır / çek", 255, 255, 255, true)
end)
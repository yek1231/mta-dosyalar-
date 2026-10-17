--[[ karakter - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local open = false
local errorMsg = ""
local fields = {
    { key = "name",   label = "İsim Soyisim",  value = "", placeholder = "Orn: Ali Yilmaz" },
    { key = "age",    label = "Yas",           value = "", placeholder = "18-80" },
    { key = "height", label = "Boy (cm)",      value = "", placeholder = "140-220" },
    { key = "weight", label = "Kilo (kg)",     value = "", placeholder = "40-200" },
    { key = "desc",   label = "Aciklama",      value = "", placeholder = "Kisa karakter ozeti..." },
}
local focus = 1
local skins = { 0, 1, 2, 7, 15, 20, 21, 22, 23, 26, 29, 35, 36, 46, 47, 48, 60, 67, 73 }
local skinIdx = 1

local edits = {} -- gui edit boxes

local function destroyEdits()
    for _, e in pairs(edits) do
        if isElement(e) then destroyElement(e) end
    end
    edits = {}
end

local function createEdits()
    destroyEdits()
    local w, h = 520 * scale, 520 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    local order = { "name", "age", "height", "weight", "desc" }
    for i, key in ipairs(order) do
        local iy = y + 70 * scale + (i - 1) * 58 * scale
        local edit = guiCreateEdit(x + 160 * scale, iy + 8 * scale, 320 * scale, 36 * scale, "", false)
        guiEditSetMaxLength(edit, key == "desc" and 120 or 24)
        guiSetVisible(edit, true)
        edits[key] = edit
    end
    guiSetInputEnabled(true)
    showCursor(true)
end

local function openUI()
    if open then return end
    open = true
    errorMsg = ""
    createEdits()
    setElementModel(localPlayer, skins[skinIdx] or 0)
end

local function closeUI()
    open = false
    destroyEdits()
    guiSetInputEnabled(false)
    showCursor(false)
end

addEvent("char:show", true)
addEventHandler("char:show", root, openUI)

addEvent("char:hide", true)
addEventHandler("char:hide", root, closeUI)

addEvent("char:error", true)
addEventHandler("char:error", root, function(msg)
    errorMsg = tostring(msg or "")
end)

local function submit()
    local payload = {
        name = edits.name and guiGetText(edits.name) or "",
        age = edits.age and guiGetText(edits.age) or "",
        height = edits.height and guiGetText(edits.height) or "",
        weight = edits.weight and guiGetText(edits.weight) or "",
        desc = edits.desc and guiGetText(edits.desc) or "",
        skin = skins[skinIdx] or 0,
    }
    triggerServerEvent("char:submit", localPlayer, payload)
end

bindKey("enter", "down", function()
    if open then submit() end
end)

bindKey("arrow_l", "down", function()
    if not open then return end
    skinIdx = skinIdx - 1
    if skinIdx < 1 then skinIdx = #skins end
    setElementModel(localPlayer, skins[skinIdx])
end)

bindKey("arrow_r", "down", function()
    if not open then return end
    skinIdx = skinIdx + 1
    if skinIdx > #skins then skinIdx = 1 end
    setElementModel(localPlayer, skins[skinIdx])
end)

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not open or btn ~= "left" or state ~= "down" then return end
    local w, h = 520 * scale, 520 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    -- kaydet butonu
    local bx, by, bw, bh = x + 40 * scale, y + h - 70 * scale, w - 80 * scale, 48 * scale
    if cx >= bx and cx <= bx + bw and cy >= by and cy <= by + bh then
        submit()
    end
end)

addEventHandler("onClientRender", root, function()
    if not open then return end
    local w, h = 520 * scale, 520 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2

    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 180))
    dxDrawRectangle(x, y, w, h, tocolor(16, 18, 24, 250))
    dxDrawRectangle(x, y, w, 52 * scale, tocolor(24, 32, 48, 255))
    dxDrawRectangle(x, y + 50 * scale, w, 3, tocolor(80, 160, 255))
    dxDrawText("KARAKTER KAYIT", x, y + 8 * scale, x + w, y + 48 * scale, tocolor(120, 190, 255), 1.35 * scale, "default-bold", "center", "center")

    local labels = {
        { "Isim Soyisim", "name" },
        { "Yas", "age" },
        { "Boy (cm)", "height" },
        { "Kilo (kg)", "weight" },
        { "Aciklama", "desc" },
    }
    for i, row in ipairs(labels) do
        local iy = y + 70 * scale + (i - 1) * 58 * scale
        dxDrawText(row[1], x + 24 * scale, iy, x + 150 * scale, iy + 50 * scale, tocolor(180, 200, 220), 1.0 * scale, "default-bold", "left", "center")
        dxDrawRectangle(x + 155 * scale, iy + 6 * scale, 330 * scale, 40 * scale, tocolor(28, 32, 42, 255))
    end

    -- skin
    local sy2 = y + 70 * scale + 5 * 58 * scale
    dxDrawText("Skin  (← →)", x + 24 * scale, sy2, x + 150 * scale, sy2 + 40 * scale, tocolor(180, 200, 220), 1.0 * scale, "default-bold", "left", "center")
    dxDrawText("ID: " .. tostring(skins[skinIdx] or 0), x + 155 * scale, sy2, x + w - 24 * scale, sy2 + 40 * scale, tocolor(120, 190, 255), 1.1 * scale, "default-bold", "left", "center")

    if errorMsg ~= "" then
        dxDrawText(errorMsg, x, y + h - 100 * scale, x + w, y + h - 75 * scale, tocolor(255, 100, 100), 1.0 * scale, "default-bold", "center", "center")
    end

    local bx, by, bw, bh = x + 40 * scale, y + h - 70 * scale, w - 80 * scale, 48 * scale
    dxDrawRectangle(bx, by, bw, bh, tocolor(30, 100, 60, 255))
    dxDrawText("KAYDET (ENTER)", bx, by, bx + bw, by + bh, tocolor(255, 255, 255), 1.15 * scale, "default-bold", "center", "center")
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    -- join event serverdan gelecek
end)
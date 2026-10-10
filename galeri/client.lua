--[[ galeri - client.lua ]]

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)

local open = false
local catalog = {}
local brandIdx, carIdx = 1, 1

local DEALER = { x = 2131.0, y = -1150.0, z = 24.2 }

addEvent("galeri:show", true)
addEventHandler("galeri:show", root, function(data)
    catalog = data or {}
    brandIdx = 1
    carIdx = 1
    open = true
    showCursor(true)
end)

local function close()
    open = false
    showCursor(false)
end

bindKey("f", "down", function()
    if open then return end
    local px, py, pz = getElementPosition(localPlayer)
    if getDistanceBetweenPoints3D(px, py, pz, DEALER.x, DEALER.y, DEALER.z) < 4 then
        triggerServerEvent("galeri:open", localPlayer)
    end
end)

bindKey("escape", "down", function()
    if open then close() cancelEvent() end
end)

bindKey("arrow_u", "down", function()
    if not open then return end
    carIdx = carIdx - 1
    if carIdx < 1 then carIdx = #(catalog[brandIdx] and catalog[brandIdx].cars or {}) end
end)

bindKey("arrow_d", "down", function()
    if not open then return end
    local n = #(catalog[brandIdx] and catalog[brandIdx].cars or {})
    carIdx = carIdx + 1
    if carIdx > n then carIdx = 1 end
end)

bindKey("arrow_l", "down", function()
    if not open then return end
    brandIdx = brandIdx - 1
    if brandIdx < 1 then brandIdx = #catalog end
    carIdx = 1
end)

bindKey("arrow_r", "down", function()
    if not open then return end
    brandIdx = brandIdx + 1
    if brandIdx > #catalog then brandIdx = 1 end
    carIdx = 1
end)

bindKey("enter", "down", function()
    if not open then return end
    triggerServerEvent("galeri:buy", localPlayer, brandIdx, carIdx)
    close()
end)

local function hit(cx, cy, x, y, w, h)
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not open or btn ~= "left" or state ~= "down" then return end
    local w, h = 900 * scale, 520 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2

    -- marka sekmeleri
    local tabW = 140 * scale
    for i, brand in ipairs(catalog) do
        local tx = x + 16 * scale + (i - 1) * (tabW + 6 * scale)
        if hit(cx, cy, tx, y + 56 * scale, tabW, 36 * scale) then
            brandIdx = i
            carIdx = 1
            return
        end
    end

    -- liste
    local listX, listY = x + 16 * scale, y + 100 * scale
    local listW, rowH = 280 * scale, 36 * scale
    local cars = catalog[brandIdx] and catalog[brandIdx].cars or {}
    for i, car in ipairs(cars) do
        local ry = listY + (i - 1) * rowH
        if hit(cx, cy, listX, ry, listW, rowH - 2) then
            carIdx = i
            return
        end
    end

    -- satın al
    if hit(cx, cy, x + w - 220 * scale, y + h - 60 * scale, 190 * scale, 42 * scale) then
        triggerServerEvent("galeri:buy", localPlayer, brandIdx, carIdx)
        close()
        return
    end
    -- kapat
    if hit(cx, cy, x + 20 * scale, y + h - 60 * scale, 140 * scale, 42 * scale) then
        close()
    end
end)

addEventHandler("onClientRender", root, function()
    local px, py, pz = getElementPosition(localPlayer)
    local near = getDistanceBetweenPoints3D(px, py, pz, DEALER.x, DEALER.y, DEALER.z) < 4
    if near and not open then
        dxDrawText("Galeri — F ile aç", 0, sy - 70 * scale, sx, sy - 30 * scale, tocolor(100, 180, 255, 240), 1.25 * scale, "default-bold", "center", "center", false, false, true)
    end

    if not open then return end
    local brand = catalog[brandIdx]
    local cars = brand and brand.cars or {}
    local car = cars[carIdx]

    local w, h = 900 * scale, 520 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2

    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 160))
    dxDrawRectangle(x, y, w, h, tocolor(14, 16, 22, 250))
    dxDrawRectangle(x, y, w, 50 * scale, tocolor(20, 28, 40, 255))
    dxDrawRectangle(x, y + 48 * scale, w, 3, tocolor(80, 160, 255))
    dxDrawText("ARAÇ GALERİSİ", x, y + 8 * scale, x + w, y + 44 * scale, tocolor(120, 190, 255), 1.4 * scale, "default-bold", "center", "center")

    -- markalar
    local tabW = 140 * scale
    for i, b in ipairs(catalog) do
        local tx = x + 16 * scale + (i - 1) * (tabW + 6 * scale)
        local sel = (i == brandIdx)
        dxDrawRectangle(tx, y + 56 * scale, tabW, 36 * scale, sel and tocolor(40, 80, 140, 255) or tocolor(28, 32, 42, 255))
        dxDrawText(b.brand, tx, y + 56 * scale, tx + tabW, y + 92 * scale, tocolor(255, 255, 255), 0.95 * scale, "default-bold", "center", "center")
    end

    -- liste
    local listX, listY = x + 16 * scale, y + 100 * scale
    local listW, rowH = 280 * scale, 36 * scale
    dxDrawRectangle(listX, listY, listW, 340 * scale, tocolor(20, 24, 32, 255))
    for i, c in ipairs(cars) do
        local ry = listY + (i - 1) * rowH
        if ry + rowH < listY + 340 * scale then
            local sel = (i == carIdx)
            dxDrawRectangle(listX + 2, ry, listW - 4, rowH - 2, sel and tocolor(50, 100, 170, 230) or tocolor(28, 32, 40, 200))
            local name = c.modName or c.name
            dxDrawText(name, listX + 10 * scale, ry, listX + listW - 10 * scale, ry + rowH - 2, tocolor(255, 255, 255), 0.95 * scale, sel and "default-bold" or "default", "left", "center")
        end
    end

    -- detay panel
    local dx_, dy_ = x + 310 * scale, y + 100 * scale
    local dw, dh = w - 330 * scale, 340 * scale
    dxDrawRectangle(dx_, dy_, dw, dh, tocolor(20, 24, 32, 255))

    if car then
        local title = car.modName or car.name
        dxDrawText(title, dx_ + 16 * scale, dy_ + 12 * scale, dx_ + dw - 16 * scale, dy_ + 48 * scale, tocolor(255, 255, 255), 1.35 * scale, "default-bold", "left", "center")
        if car.modName then
            dxDrawText("MODLU ARAÇ", dx_ + 16 * scale, dy_ + 44 * scale, dx_ + dw, dy_ + 64 * scale, tocolor(255, 180, 60), 0.95 * scale, "default-bold", "left", "center")
        end

        -- resim
        local imgW, imgH = 260 * scale, 140 * scale
        local ix, iy = dx_ + (dw - imgW) / 2, dy_ + 70 * scale
        dxDrawRectangle(ix, iy, imgW, imgH, tocolor(12, 14, 18, 255))
        if car.img and fileExists(car.img) then
            dxDrawImage(ix, iy, imgW, imgH, car.img)
        else
            dxDrawText("Model ID: " .. tostring(car.model), ix, iy, ix + imgW, iy + imgH, tocolor(100, 120, 150), 1.2 * scale, "default-bold", "center", "center")
            dxDrawText("(img/" .. tostring(car.model) .. ".png ekle)", ix, iy + 30 * scale, ix + imgW, iy + imgH, tocolor(70, 90, 110), 0.9 * scale, "default", "center", "center")
        end

        -- istatistikler
        local sy_ = iy + imgH + 16 * scale
        dxDrawText("Fiyat", dx_ + 24 * scale, sy_, dx_ + dw / 2, sy_ + 24 * scale, tocolor(140, 160, 180), 0.95 * scale, "default", "left", "center")
        dxDrawText("$" .. car.price, dx_ + dw / 2, sy_, dx_ + dw - 24 * scale, sy_ + 24 * scale, tocolor(80, 220, 120), 1.15 * scale, "default-bold", "right", "center")

        dxDrawText("Max hız", dx_ + 24 * scale, sy_ + 32 * scale, dx_ + dw / 2, sy_ + 56 * scale, tocolor(140, 160, 180), 0.95 * scale, "default", "left", "center")
        dxDrawText(car.speed .. " km/h", dx_ + dw / 2, sy_ + 32 * scale, dx_ + dw - 24 * scale, sy_ + 56 * scale, tocolor(120, 190, 255), 1.15 * scale, "default-bold", "right", "center")

        dxDrawText("Model ID", dx_ + 24 * scale, sy_ + 64 * scale, dx_ + dw / 2, sy_ + 88 * scale, tocolor(140, 160, 180), 0.95 * scale, "default", "left", "center")
        dxDrawText(tostring(car.model), dx_ + dw / 2, sy_ + 64 * scale, dx_ + dw - 24 * scale, sy_ + 88 * scale, tocolor(200, 200, 210), 1.05 * scale, "default-bold", "right", "center")

        -- hız bar
        local barX, barY, barW, barH = dx_ + 24 * scale, sy_ + 100 * scale, dw - 48 * scale, 12 * scale
        dxDrawRectangle(barX, barY, barW, barH, tocolor(30, 30, 40, 255))
        local pct = math.min(1, (car.speed or 0) / 230)
        dxDrawRectangle(barX, barY, barW * pct, barH, tocolor(80, 160, 255, 255))
    end

    -- butonlar
    dxDrawRectangle(x + 20 * scale, y + h - 60 * scale, 140 * scale, 42 * scale, tocolor(60, 40, 40, 255))
    dxDrawText("KAPAT", x + 20 * scale, y + h - 60 * scale, x + 160 * scale, y + h - 18 * scale, tocolor(255, 255, 255), 1.05 * scale, "default-bold", "center", "center")

    dxDrawRectangle(x + w - 220 * scale, y + h - 60 * scale, 190 * scale, 42 * scale, tocolor(30, 90, 50, 255))
    dxDrawText("SATIN AL (ENTER)", x + w - 220 * scale, y + h - 60 * scale, x + w - 30 * scale, y + h - 18 * scale, tocolor(255, 255, 255), 1.05 * scale, "default-bold", "center", "center")

    dxDrawText("← → Marka   ↑ ↓ Model", x, y + h - 18 * scale, x + w, y + h - 2 * scale, tocolor(100, 110, 130), 0.85 * scale, "default", "center", "center")
end)
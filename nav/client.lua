local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)
local target, label = nil, ""

addEvent("nav:go", true)
addEventHandler("nav:go", root, function(x, y, z, name)
    target = { x = x, y = y, z = z or 0 }
    label = name or "Hedef"
end)

addEvent("nav:clear", true)
addEventHandler("nav:clear", root, function()
    target = nil
end)

local function angleDiff(a, b)
    local d = (a - b + 180) % 360 - 180
    return d
end

local function dirIcon(diff)
    local a = math.abs(diff)
    if a < 25 then return "↑", "DÜZ GİT"
    elseif a > 150 then return "↩", "U DÖNÜŞÜ"
    elseif diff > 0 then return "←", "SOLA DÖN"
    else return "→", "SAĞA DÖN"
    end
end

addEventHandler("onClientRender", root, function()
    if not target then return end
    local px, py, pz = getElementPosition(localPlayer)
    local dist = getDistanceBetweenPoints3D(px, py, pz, target.x, target.y, target.z)
    if dist < 5 then
        target = nil
        outputChatBox("#80C0FF[Nav] #FFFFFFHedefe vardın.", 255, 255, 255, true)
        return
    end

    local ang = math.deg(math.atan2(target.x - px, target.y - py)) % 360
    local _, _, prz = getElementRotation(localPlayer)
    local diff = angleDiff(ang, prz)
    local icon, text = dirIcon(diff)

    local w, h = 280 * scale, 90 * scale
    local x, y = (sx - w) / 2, sy - 160 * scale
    dxDrawRectangle(x, y, w, h, tocolor(10, 14, 20, 210))
    dxDrawRectangle(x, y, w, 3, tocolor(80, 160, 255))
    dxDrawText(icon, x, y + 6 * scale, x + 90 * scale, y + h, tocolor(80, 180, 255), 2.4 * scale, "default-bold", "center", "center")
    dxDrawText(text, x + 90 * scale, y + 12 * scale, x + w - 10 * scale, y + 42 * scale, tocolor(255, 255, 255), 1.15 * scale, "default-bold", "left", "center")
    dxDrawText(string.format("%s  ·  %.0f m", label, dist), x + 90 * scale, y + 42 * scale, x + w - 10 * scale, y + 72 * scale, tocolor(160, 190, 220), 0.95 * scale, "default", "left", "center")
end)
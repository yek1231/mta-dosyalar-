local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1920, sy / 1080)
local theoryOpen, theoryQ, theoryScore = false, 1, 0
local practiceCP, practiceList, cpMarker = nil, nil, nil

local QUESTIONS = {
    { q = "Kırmızı ışıkta ne yapılır?", a = { "Geçilir", "Durulur", "Korna çalınır" }, c = 2 },
    { q = "Emniyet kemeri?", a = { "Şart değil", "Takılmalıdır", "Sadece otoyolda" }, c = 2 },
    { q = "Alkollüyken araç?", a = { "Yasak", "Az içince olur", "Gece serbest" }, c = 1 },
}

addEvent("ehliyet:theory", true)
addEventHandler("ehliyet:theory", root, function()
    theoryOpen, theoryQ, theoryScore = true, 1, 0
    showCursor(true)
end)

addEvent("ehliyet:practice", true)
addEventHandler("ehliyet:practice", root, function(list, idx)
    practiceList = list
    practiceCP = idx
    if isElement(cpMarker) then destroyElement(cpMarker) end
    local c = list[idx]
    if c then
        cpMarker = createMarker(c.x, c.y, c.z - 1, "checkpoint", 4, 80, 255, 120, 180)
        outputChatBox("#80C0FF[Sınav] #FFFFFFCheckpoint " .. idx .. "/" .. #list, 255, 255, 255, true)
    end
end)

addEvent("ehliyet:practiceEnd", true)
addEventHandler("ehliyet:practiceEnd", root, function()
    if isElement(cpMarker) then destroyElement(cpMarker) end
    practiceCP, practiceList = nil, nil
end)

addEventHandler("onClientMarkerHit", root, function(hit)
    if hit ~= localPlayer or not practiceCP or not practiceList then return end
    if source ~= cpMarker then return end
    triggerServerEvent("ehliyet:hitCP", localPlayer, practiceCP)
end)

local function closeTheory()
    theoryOpen = false
    showCursor(false)
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if not theoryOpen or btn ~= "left" or state ~= "down" then return end
    local q = QUESTIONS[theoryQ]
    if not q then return end
    local w, h = 480 * scale, 320 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    for i = 1, 3 do
        local iy = y + 100 * scale + (i - 1) * 50 * scale
        if cx >= x + 30 * scale and cx <= x + w - 30 * scale and cy >= iy and cy <= iy + 42 * scale then
            if i == q.c then theoryScore = theoryScore + 1 end
            theoryQ = theoryQ + 1
            if theoryQ > #QUESTIONS then
                closeTheory()
                triggerServerEvent("ehliyet:theoryResult", localPlayer, theoryScore >= 2)
            end
            return
        end
    end
end)

addEventHandler("onClientRender", root, function()
    if not theoryOpen then return end
    local q = QUESTIONS[theoryQ]
    if not q then return end
    local w, h = 480 * scale, 320 * scale
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 160))
    dxDrawRectangle(x, y, w, h, tocolor(16, 20, 28, 250))
    dxDrawText("TEORİK SINAV  " .. theoryQ .. "/" .. #QUESTIONS, x, y + 16 * scale, x + w, y + 50 * scale, tocolor(80, 200, 255), 1.2 * scale, "default-bold", "center", "center")
    dxDrawText(q.q, x + 20 * scale, y + 55 * scale, x + w - 20 * scale, y + 95 * scale, tocolor(255, 255, 255), 1.05 * scale, "default", "center", "center")
    for i, ans in ipairs(q.a) do
        local iy = y + 100 * scale + (i - 1) * 50 * scale
        dxDrawRectangle(x + 30 * scale, iy, w - 60 * scale, 42 * scale, tocolor(30, 40, 55, 240))
        dxDrawText(ans, x + 30 * scale, iy, x + w - 30 * scale, iy + 42 * scale, tocolor(255, 255, 255), 1.05 * scale, "default-bold", "center", "center")
    end
end)
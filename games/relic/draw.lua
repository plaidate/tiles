-- Relic: rendering. Rooms, quest actors, sword swings, HUD.

local gfx = playdate.graphics

Draw = {}

local S = Spr.makeSet({
    hero = {
        "....####....",
        "...#oooo#...",
        "..#oooooo#..",
        "..#o#oo#o#..",
        "..#oooooo#..",
        "...#oooo#...",
        "..########..",
        ".#oooooooo#.",
        ".#oo#oo#oo#.",
        ".#oooooooo#.",
        "..#oooooo#..",
        "...#o##o#...",
        "...#o##o#...",
        "...##..##...",
    },
    blob = {
        "...######...",
        "..########..",
        ".##########.",
        ".##o####o##.",
        ".##########.",
        "..########..",
        "...######...",
        "..##.##.##..",
    },
    skel = {
        "...######...",
        "..#oooooo#..",
        "..#o#oo#o#..",
        "..#oooooo#..",
        "...##oo##...",
        "..########..",
        ".#o#o##o#o#.",
        ".#########..",
        "..#o#oo#o#..",
        "...######...",
        "...#....#...",
        "..##....##..",
    },
    shooter = {
        "....####....",
        "..########..",
        ".##########.",
        ".###oooo###.",
        ".##oo##oo##.",
        ".##o####o##.",
        ".##oo##oo##.",
        ".###oooo###.",
        ".##########.",
        "..########..",
        "....####....",
    },
    boss = {
        "......##########........",
        "....##############......",
        "..##################....",
        ".####################...",
        ".####o######o########...",
        "#####o######o#########..",
        "######################..",
        "########oooo##########..",
        "#######o####o#########..",
        ".####################...",
        ".####################...",
        "..##################....",
        "..###.####.####.###.....",
        "...##..###..###..##.....",
    },
    key = {
        "...####.",
        "..#oooo#",
        "..#o##o#",
        "..#oooo#",
        "...####.",
        "....#...",
        "..###...",
        "....#...",
        "..###...",
    },
    heartPick = {
        ".##..##.",
        "#oo##oo#",
        "#oooooo#",
        ".#oooo#.",
        "..#oo#..",
        "...##...",
    },
    boomPick = {
        ".####...",
        "#oooo#..",
        "####o#..",
        "...#o#..",
        "...#o#..",
        "...#o#..",
        "..#oo#..",
        "..####..",
    },
    relic = {
        ".....##.....",
        "....#oo#....",
        "...#oooo#...",
        "..#oo##oo#..",
        ".#oo####oo#.",
        "#oo######oo#",
        ".#oo####oo#.",
        "..#oo##oo#..",
        "...#oooo#...",
        "....#oo#....",
        ".....##.....",
    },
})

local frame = 0

local function drawSword(p)
    if p.swordT <= 0 then return end
    gfx.setColor(gfx.kColorWhite)
    if p.fx ~= 0 then
        local x0 = p.fx > 0 and p.x + 6 or p.x - 6 - 12
        gfx.fillRect(x0, p.y - 2, 12, 4)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x0, p.y - 2, 12, 4)
    else
        local y0 = p.fy > 0 and p.y + 6 or p.y - 6 - 12
        gfx.fillRect(p.x - 2, y0, 4, 12)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(p.x - 2, y0, 4, 12)
    end
end

local function entities()
    local p = Game.player
    for i = 1, #Game.pickups do
        local pk = Game.pickups[i]
        local img = pk.kind == "key" and S.key
            or pk.kind == "boom" and S.boomPick
            or pk.kind == "relic" and S.relic
            or S.heartPick
        Spr.draw(img, pk.x, pk.y + math.sin(frame / 10 + i) * 2)
    end
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        if not e.stun or frame % 4 < 2 then
            local img = S[e.kind == "boss" and "boss" or e.kind]
            Spr.draw(img, e.x, e.y + math.sin((e.t or 0) * 4) * 1.5)
        end
    end
    for i = 1, #Game.ebullets do
        local b = Game.ebullets[i]
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(b.x, b.y, 4)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(b.x, b.y, 2)
    end
    if Game.boom then
        local bm = Game.boom
        gfx.setColor(gfx.kColorBlack)
        if frame % 4 < 2 then
            gfx.fillRect(bm.x - 5, bm.y - 2, 10, 4)
            gfx.fillRect(bm.x - 2, bm.y - 5, 4, 10)
        else
            gfx.setLineWidth(3)
            gfx.drawLine(bm.x - 4, bm.y - 4, bm.x + 4, bm.y + 4)
            gfx.drawLine(bm.x - 4, bm.y + 4, bm.x + 4, bm.y - 4)
            gfx.setLineWidth(1)
        end
        gfx.setColor(gfx.kColorWhite)
        gfx.drawPixel(bm.x, bm.y)
    end
    if p and (p.iframes <= 0 or frame % 6 < 3) then
        Spr.draw(S.hero, p.x, p.y, p.fx < 0 and gfx.kImageFlippedX or nil)
        drawSword(p)
    end
    if p then Kit.marker(p.x, p.y - 9, frame / 30) end
    if Game.spinFx > 0 and p then
        local r = math.floor((0.25 - Game.spinFx) / 0.25 * Config.SPIN_R)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(p.x, p.y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(p.x, p.y, r + 1)
    end
    Kit.drawParts(Game.parts)
end

local heart = S.heartPick
local heartEmpty = Spr.make({
    ".oo..oo.",
    "o..oo..o",
    "o......o",
    ".o....o.",
    "..o..o..",
    "...oo...",
})

local function hud()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 16)
    for i = 1, State.maxHearts do
        Spr.draw(i <= State.hearts and heart or heartEmpty, i * 12 - 2, 8)
    end
    Kit.text("KEY x" .. State.keys, 90, 0)
    if State.hasBoom then Spr.draw(S.boomPick, 165, 8) end
    -- spin charge meter
    local w = 60
    local fill = Harness.enabled
        and (Game.player and Game.player.spinCd <= 0 and w or 0)
        or math.floor(Util.clamp(Input.charge / Config.SPIN_CHARGE, 0, 1) * w)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(210, 4, w, 8)
    gfx.fillRect(210, 4, fill, 8)
    Kit.text("SPIN", 274, 0)
    local zone = State.room:sub(1, 1) == "d" and "BELOW" or "ABOVE"
    Kit.text(zone, 344, 0)
end

function Draw.frame()
    frame = frame + 1
    gfx.clear(gfx.kColorBlack)
    gfx.setDrawOffset(Kit.sx, Kit.sy)
    Map.draw()
    if State.mode ~= "title" and Game.player then
        entities()
    end
    gfx.setDrawOffset(0, 0)
    hud()
    if State.mode == "title" then
        local lines = {
            "The relic sleeps below the hills",
            "D-pad move  Ⓐ sword  Ⓑ boomerang",
            "Wind the crank for a spin attack",
            State.hasSave and "Ⓐ new quest   Ⓑ continue" or "Press Ⓐ to begin",
        }
        Kit.title("RELIC", lines)
    elseif State.mode == "over" then
        Kit.over("YOU FELL", { "The quest waits", "Ⓐ to continue" })
    elseif State.mode == "win" then
        Kit.over("RELIC RECLAIMED", { "The land is bright again", "Ⓐ to continue" })
    end
end

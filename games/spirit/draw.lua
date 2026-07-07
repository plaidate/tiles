-- Spirit: rendering. Shrine map, yokai, talismans, sweep ring, HUD.

local gfx = playdate.graphics

Draw = {}

local S = Spr.makeSet({
    maiden = {
        "....####....",
        "...#oooo#...",
        "..#oooooo#..",
        "..#o#oo#o#..",
        "..#oooooo#..",
        "...#oooo#...",
        "..###oo###..",
        ".#oooooooo#.",
        ".#o#oooo#o#.",
        "..#oooooo#..",
        "..#oooooo#..",
        "..#o#oo#o#..",
        "..#oo##oo#..",
        "...##..##...",
    },
    ghost = {
        "...######...",
        "..########..",
        ".##########.",
        "##o##o#####.",
        "##o##o######",
        "############",
        "############",
        "############",
        "############",
        "#.##.##.##.#",
    },
    spitter = {
        "....####....",
        "..########..",
        ".##########.",
        ".##oooooo##.",
        ".##o#oo#o##.",
        ".##oooooo##.",
        ".##########.",
        "..########..",
        "....####....",
        "...##..##...",
    },
    dasher = {
        "##..........",
        "####........",
        "######......",
        "#o########..",
        "#o##########",
        "######......",
        "####........",
        "##..........",
    },
    shotV = {
        ".###.",
        "#ooo#",
        "#o#o#",
        "#ooo#",
        "#o#o#",
        "#ooo#",
        ".###.",
    },
    heart = {
        ".oo..oo.",
        "oooooooo",
        "oooooooo",
        ".oooooo.",
        "..oooo..",
        "...oo...",
    },
    heartEmpty = {
        ".oo..oo.",
        "o..oo..o",
        "o......o",
        ".o....o.",
        "..o..o..",
        "...oo...",
    },
})
S.shotH = Spr.make({
    ".#####.",
    "#ooooo#",
    "#o#o#o#",
    "#ooooo#",
    ".#####.",
})

local frame = 0

local function entities()
    local p = Game.player
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        if not e.spawning or frame % 4 < 2 then
            local img = S[e.kind]
            local flip = (e.kind == "dasher" and e.vx and e.vx < 0)
                and gfx.kImageFlippedX or nil
            Spr.draw(img, e.x, e.y + math.sin((e.t or 0) * 4) * 2, flip)
        end
    end
    for i = 1, #Game.shots do
        local sh = Game.shots[i]
        Spr.draw(sh.vx ~= 0 and S.shotH or S.shotV, sh.x, sh.y)
    end
    for i = 1, #Game.ebullets do
        local b = Game.ebullets[i]
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(b.x, b.y, 4)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(b.x, b.y, 2)
    end
    if p and (p.iframes <= 0 or frame % 6 < 3) then
        Spr.draw(S.maiden, p.x, p.y)
        -- wand tip marks the firing direction
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(p.x + p.fx * 10, p.y + p.fy * 10, 2)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawPixel(p.x + p.fx * 10, p.y + p.fy * 10)
    end
    if p then Kit.marker(p.x, p.y - 9, frame / 30) end
    if Game.sweepFx > 0 and p then
        local r = math.floor((0.25 - Game.sweepFx) / 0.25 * Config.SWEEP_BULLET_R)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(p.x, p.y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(p.x, p.y, r + 1)
    end
    Kit.drawParts(Game.parts)
end

local function hud()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 16)
    Kit.text("WAVE " .. math.min(State.wave, Config.WAVES) .. "/" .. Config.WAVES, 6, 0)
    for i = 1, Config.HEARTS do
        Spr.draw(i <= State.hearts and S.heart or S.heartEmpty, 118 + i * 12, 8)
    end
    -- sweep meter: fills as the crank spins
    local w = 60
    local fill = Harness.enabled and (Game.player and Game.player.sweepCd <= 0 and w or 0)
        or math.floor(Util.clamp(Input.charge / Config.SWEEP_CHARGE, 0, 1) * w)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(210, 4, w, 8)
    gfx.fillRect(210, 4, fill, 8)
    Kit.text("SPIN", 274, 0)
    Kit.text("SCORE " .. State.score, 320, 0)
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
        Kit.title("SPIRIT", {
            "Waves of yokai haunt the shrine",
            "D-pad move   Ⓐ throw talismans",
            "Spin the crank to bank a sweep",
            "Press Ⓐ to start",
        })
    elseif State.mode == "wavein" then
        Kit.bigCentered("WAVE " .. State.wave, 100, 2)
    elseif State.mode == "over" then
        Kit.over("GAME OVER", { "Score " .. State.score, "Ⓐ to continue" })
    elseif State.mode == "win" then
        Kit.over("SHRINE AT PEACE", { "Score " .. State.score, "Ⓐ to continue" })
    end
end

-- Blast: rendering. Map blit + entities + HUD + mode overlays.

local gfx = playdate.graphics

Draw = {}

local S = Spr.makeSet({
    player = {
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
    puff = {
        "...######...",
        "..########..",
        ".##########.",
        "############",
        "##o######o##",
        "############",
        "############",
        "############",
        ".##########.",
        "..########..",
        "..#.####.#..",
    },
    hound = {
        "....##......",
        "...####.....",
        "..######....",
        ".########...",
        "#o########..",
        "############",
        ".##########.",
        "..###..###..",
        "..##....##..",
        "..#......#..",
    },
})

-- powerup icons: bordered white chip with a block letter
local LETTERS = {
    B = { "####.", "#...#", "#...#", "####.", "#...#", "#...#", "####." },
    F = { "#####", "#....", "#....", "####.", "#....", "#....", "#...." },
    S = { ".####", "#....", "#....", ".###.", "....#", "....#", "####." },
}
for kind, rows in pairs(LETTERS) do
    local art = { "############", "#oooooooooo#" }
    for i = 1, 7 do
        local mid = rows[i]:gsub("%.", "o")
        art[#art + 1] = "#oo" .. mid .. "oooo#"
    end
    art[#art + 1] = "#oooooooooo#"
    art[#art + 1] = "#oooooooooo#"
    art[#art + 1] = "############"
    S["pu" .. kind] = Spr.make(art)
end

local frame = 0

local function entities()
    local pl = Game.player
    for i = 1, #Game.powerups do
        local p = Game.powerups[i]
        Spr.draw(S["pu" .. p.kind], Map.cx(p.tx), Map.cy(p.ty))
    end
    for i = 1, #Game.bombs do
        local b = Game.bombs[i]
        local x, y = Map.cx(b.tx), Map.cy(b.ty)
        local r = 5 + math.floor(b.t * 8) % 2
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawPixel(x - 2, y - 2)
        if math.floor(b.t * 10) % 2 == 0 then
            gfx.fillCircleAtPoint(x + 4, y - 6, 2)
        end
    end
    for _, f in pairs(Game.flames) do
        local x, y = Map.cx(f.tx), Map.cy(f.ty)
        local r = 6 + (frame % 4 < 2 and 1 or 0)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(x, y, r)
        gfx.fillCircleAtPoint(x, y, 2)
    end
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        Spr.draw(S[e.kind], e.x, e.y)
    end
    if pl and State.mode ~= "dying" then
        if pl.invuln <= 0 or frame % 6 < 3 then
            Spr.draw(S.player, pl.x, pl.y,
                pl.face < 0 and gfx.kImageFlippedX or nil)
        end
        Kit.marker(pl.x, pl.y - 9, frame / 30)
    end
    Kit.drawParts(Game.parts)
end

local function hud()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 16)
    Kit.text("L" .. State.level, 6, 0)
    Kit.text("LIVES " .. State.lives, 38, 0)
    Kit.text("B" .. State.maxBombs .. " F" .. State.power .. " S" .. State.boots, 128, 0)
    Kit.text(string.format("FUSE %.1f", Input.state.fuse), 216, 0)
    Kit.text("SCORE " .. State.score, 306, 0)
end

function Draw.frame()
    frame = frame + 1
    gfx.clear(gfx.kColorBlack)
    Kit.applyShake()
    Map.draw()
    if State.mode ~= "title" and Game.player then
        entities()
    end
    Kit.doneShake()
    hud()
    if State.mode == "title" then
        Kit.title("BLAST", {
            "Bomb the crates, trap the beasts",
            "D-pad move   Ⓐ drop bomb",
            "Crank dials the fuse length",
            "Press Ⓐ to start",
        })
    elseif State.mode == "over" then
        Kit.over("GAME OVER", { "Score " .. State.score, "Ⓐ to continue" })
    elseif State.mode == "win" then
        Kit.over("ALL CLEAR!", { "Score " .. State.score, "Ⓐ to continue" })
    end
end

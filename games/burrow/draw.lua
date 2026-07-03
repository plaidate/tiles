-- Burrow: rendering. World through the camera, HUD in screen space.

local gfx = playdate.graphics

Draw = {}

local miner = Spr.make({
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
})

local frame = 0

local function hud()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 16)
    Kit.text("L" .. State.level, 6, 0)
    Kit.text("LIVES " .. State.lives, 38, 0)
    Kit.text("GEMS " .. State.gems .. "/" .. State.need, 128, 0)
    Kit.text("TIME " .. math.max(0, math.floor(State.time)), 230, 0)
    Kit.text("SCORE " .. State.score, 312, 0)
end

function Draw.frame()
    frame = frame + 1
    gfx.clear(gfx.kColorBlack)
    Cam.apply()
    Map.draw()
    local p = Game.player
    if State.mode ~= "title" and p and State.mode ~= "dying" then
        Spr.draw(miner, p.px, p.py, p.face < 0 and gfx.kImageFlippedX or nil)
        Kit.marker(p.px, p.py - 9, frame / 30)
    end
    Kit.drawParts(Game.parts)
    Cam.done()
    hud()
    if State.mode == "title" then
        Kit.title("BURROW", {
            "Dig deep, bank the gems,",
            "never stand under a rock",
            "D-pad dig   Crank surveys the shaft",
            "Press Ⓐ to start",
        })
    elseif State.mode == "clear" then
        Kit.bigCentered("CAVE CLEAR!", 100, 2)
    elseif State.mode == "over" then
        Kit.over("GAME OVER", { "Score " .. State.score, "Ⓐ to continue" })
    elseif State.mode == "win" then
        Kit.over("RICH!", { "Score " .. State.score, "Ⓐ to continue" })
    end
end

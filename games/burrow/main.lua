-- Burrow: entry point. Scrolling Boulder-Dash-style digger on the Tiles
-- core — the first game on the Cam module.

import "lib"
import "config"
import "gamestate"
import "mine"
import "game"
import "input"
import "draw"

playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
math.randomseed(playdate.getSecondsSinceEpoch())

Game.init()

local updMs, drwMs = 0, 0

if Harness.enabled then
    Harness.extra = function(t)
        t.mode = State.mode
        t.level = State.level
        t.lives = State.lives
        t.gems = State.gems
        t.need = State.need
        t.time = math.floor(State.time)
        t.camx = math.floor(Cam.x)
        t.camy = math.floor(Cam.y)
        if Game.camMinX then
            t.camSpanX = math.floor(Game.camMaxX - Game.camMinX)
            t.camSpanY = math.floor(Game.camMaxY - Game.camMinY)
        end
        t.updMs = math.floor(updMs * 10) / 10
        t.drwMs = math.floor(drwMs * 10) / 10
    end
    if playdate.simulator then
        Harness.shotPath = "tiles/build/burrow-shot.png"
    end
end

local frame = 0

function playdate.update()
    frame = frame + 1
    Harness.frame(frame, function()
        Input.poll()
        playdate.resetElapsedTime()
        Game.update(Config.DT)
        Util.runPending(Config.DT)
        updMs = updMs * 0.95 + playdate.getElapsedTime() * 50
        playdate.resetElapsedTime()
        Draw.frame()
        drwMs = drwMs * 0.95 + playdate.getElapsedTime() * 50
    end)
end

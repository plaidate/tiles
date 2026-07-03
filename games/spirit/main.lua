-- Spirit: entry point. Single-screen 4-way yokai shooter on the Tiles core.

import "lib"
import "config"
import "gamestate"
import "arena"
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
        t.wave = State.wave
        t.hearts = State.hearts
        t.enemies = #Game.enemies
        t.queued = #Game.queue
        t.score = State.score
        t.updMs = math.floor(updMs * 10) / 10
        t.drwMs = math.floor(drwMs * 10) / 10
    end
    if playdate.simulator then
        Harness.shotPath = "tiles/build/spirit-shot.png"
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

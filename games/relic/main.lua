-- Relic: entry point. Screen-flip action RPG on the Tiles core.

import "lib"
import "config"
import "gamestate"
import "world"
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
        t.room = State.room
        t.hearts = State.hearts
        t.keycount = State.keys
        t.enemies = #Game.enemies
        t.route = Game.apIndex
        if Game.player then
            t.px = math.floor(Game.player.x)
            t.py = math.floor(Game.player.y)
            t.ifr = math.floor(Game.player.iframes * 10) / 10
        end
        t.minBd = Game.minBd and math.floor(Game.minBd) or -1
        t.lastBlock = Game.lastBlock or ""
        t.live = #Game.ebullets
        t.updMs = math.floor(updMs * 10) / 10
        t.drwMs = math.floor(drwMs * 10) / 10
    end
    if playdate.simulator then
        Harness.shotPath = "tiles/build/relic-shot.png"
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

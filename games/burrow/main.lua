-- Burrow: entry point. Scrolling Boulder-Dash-style digger on the Tiles
-- core — the first game on the Cam module.

import "lib"
import "config"
import "gamestate"
import "mine"
import "game"
import "input"
import "draw"

Kit.run{
    init = Game.init,
    extra = function(t)
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
    end,
    shotPath = "build/burrow-shot.png",
}

-- Relic: entry point. Screen-flip action RPG on the Tiles core.

import "lib"
import "config"
import "gamestate"
import "world"
import "game"
import "input"
import "draw"

Kit.run{
    init = Game.init,
    extra = function(t)
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
    end,
    shotPath = "build/relic-shot.png",
}

-- Spirit: entry point. Single-screen 4-way yokai shooter on the Tiles core.

import "lib"
import "config"
import "gamestate"
import "arena"
import "game"
import "input"
import "draw"

Kit.run{
    init = Game.init,
    extra = function(t)
        t.mode = State.mode
        t.wave = State.wave
        t.hearts = State.hearts
        t.enemies = #Game.enemies
        t.queued = #Game.queue
        t.score = State.score
    end,
    shotPath = "build/spirit-shot.png",
}

-- Blast: entry point. Single-screen bomb-the-maze arcade on the Tiles core.

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
        t.level = State.level
        t.lives = State.lives
        t.enemies = #Game.enemies
        t.score = State.score
    end,
    shotPath = "build/blast-shot.png",
}

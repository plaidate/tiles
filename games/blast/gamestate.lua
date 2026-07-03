-- Blast: run-wide state. Per-level entities live on Game.

State = {}

function State.reset()
    State.mode = "title" -- title | play | dying | clear | over | win
    State.level = 1
    State.score = 0
    State.lives = Config.LIVES
    -- upgrades persist across levels, reset on death
    State.maxBombs = 1
    State.power = 2
    State.boots = 0
end

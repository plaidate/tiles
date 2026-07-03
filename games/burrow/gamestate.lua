-- Burrow: run-wide state.

State = {}

function State.reset()
    State.mode = "title" -- title | play | dying | clear | over | win
    State.level = 1
    State.score = 0
    State.lives = Config.LIVES
    State.gems = 0
    State.need = 0
    State.time = Config.TIME
end

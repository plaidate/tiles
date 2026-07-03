-- Spirit: run-wide state.

State = {}

function State.reset()
    State.mode = "title" -- title | play | wavein | over | win
    State.wave = 1
    State.score = 0
    State.hearts = Config.HEARTS
end

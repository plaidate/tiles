-- Relic: run-wide state + datastore save/continue. The save is written on
-- every room transition; continue restores it with hearts refilled.

State = {}

function State.reset()
    State.mode = "title" -- title | play | over | win
    State.room = "o1_2"
    State.hearts = Config.HEARTS
    State.maxHearts = Config.HEARTS
    State.keys = 0
    State.hasBoom = false
    State.taken = {}  -- pickup ids collected
    State.doors = {}  -- door cells opened, "room:tx,ty"
    State.bossDead = false
    State.hasSave = playdate.datastore.read("save") ~= nil
end

function State.save()
    playdate.datastore.write({
        room = State.room,
        hearts = State.hearts,
        maxHearts = State.maxHearts,
        keys = State.keys,
        hasBoom = State.hasBoom,
        taken = State.taken,
        doors = State.doors,
        bossDead = State.bossDead,
    }, "save")
    State.hasSave = true
    Harness.count("saves")
end

-- returns true when a save was loaded
function State.load()
    local s = playdate.datastore.read("save")
    if not s then return false end
    State.room = s.room or "o1_2"
    State.maxHearts = s.maxHearts or Config.HEARTS
    State.hearts = State.maxHearts -- continue refills
    State.keys = s.keys or 0
    State.hasBoom = s.hasBoom or false
    State.taken = s.taken or {}
    State.doors = s.doors or {}
    State.bossDead = s.bossDead or false
    Harness.count("loads")
    return true
end

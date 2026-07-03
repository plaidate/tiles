-- Burrow: dig, collect, don't stand under anything shiny. Rocks and gems
-- live as TILES driven by a Boulder-Dash cellular automaton — every move
-- is two Map.set dirty repaints, which is exactly what the engine's
-- bg-image model is good at. The camera follows the miner around a
-- 640x448 world; the crank pans it to survey the shaft.

Game = {
    parts = {},
    falling = {}, -- cells that moved last tick (falling objects kill)
    player = nil,
    exitOpen = false,
    peekY = 0,    -- crank camera offset
    tickT = 0,
}

local function key(x, y) return y * 64 + x end

function Game.init()
    State.reset()
    Mine.generate(1)
    Map.build()
    Cam.reset()
end

function Game.startGame()
    State.reset()
    State.mode = "play"
    Game.startLevel()
end

function Game.startLevel()
    Mine.generate(State.level)
    Map.build()
    Game.parts, Game.falling = {}, {}
    Game.exitOpen = false
    Game.peekY = 0
    Game.tickT = 0
    State.gems = 0
    State.need = Mine.need(State.level)
    State.time = Config.TIME
    Game.player = {
        tx = 2, ty = 2, px = Map.cx(2), py = Map.cy(2),
        moving = false, face = 1,
    }
    Cam.center(Game.player.px, Game.player.py)
    State.mode = "play"
end

function Game.update(dt)
    local s = Input.state
    Kit.updateShake(dt)
    Kit.updateParts(Game.parts, dt)
    if State.mode == "title" then
        if s.confirm then Game.startGame() end
        return
    end
    if State.mode == "over" or State.mode == "win" then
        if s.confirm then
            Util.clearPending()
            State.reset()
            Mine.generate(1)
            Map.build()
            Cam.reset()
        end
        return
    end
    if State.mode ~= "play" then return end -- dying | clear

    State.time = State.time - dt
    if State.time <= 0 then
        Game.kill("timeouts")
        return
    end

    Game.tickT = Game.tickT + dt
    while Game.tickT >= Config.TICK do
        Game.tickT = Game.tickT - Config.TICK
        Game.tick()
    end

    Game.updatePlayer(dt, s)

    -- camera: follow the miner, crank pans to survey
    local p = Game.player
    Game.peekY = Util.clamp((Game.peekY + (s.peek or 0) * 0.8) * 0.94, -160, 160)
    Cam.follow(p.px, p.py + Game.peekY, dt)
    if Harness.enabled then
        Game.camMinX = math.min(Game.camMinX or 1e9, Cam.x)
        Game.camMaxX = math.max(Game.camMaxX or -1e9, Cam.x)
        Game.camMinY = math.min(Game.camMinY or 1e9, Cam.y)
        Game.camMaxY = math.max(Game.camMaxY or -1e9, Cam.y)
    end
end

local function crushCheck(x, y)
    local p = Game.player
    if State.mode == "play" and p.tx == x and p.ty == y then
        Game.kill("crushes")
    end
end

-- the automaton: bottom-up scan; rocks and gems fall into tunnels and
-- roll off rounded piles, one cell per tick
function Game.tick()
    local newFall = {}
    local moved = {}
    local p = Game.player
    for y = Map.H - 1, 2, -1 do
        for x = 2, Map.W - 1 do
            local ch = Map.get(x, y)
            if (ch == "O" or ch == "*") and not moved[key(x, y)] then
                local below = Map.get(x, y + 1)
                local onMiner = p.tx == x and p.ty == y + 1
                if below == "." and (not onMiner or Game.falling[key(x, y)]) then
                    -- BD rule: the miner's cell counts as occupied, so a
                    -- resting rock sits on your helmet; only an object
                    -- that is already falling drops in and kills
                    Map.set(x, y, ".")
                    Map.set(x, y + 1, ch)
                    newFall[key(x, y + 1)] = true
                    moved[key(x, y + 1)] = true
                    crushCheck(x, y + 1)
                elseif below == "." then
                    -- resting on the miner: stay put, stay primed
                elseif below == "O" or below == "*" then
                    local rolled = false
                    for _, dx in ipairs({ -1, 1 }) do
                        if not rolled
                            and Map.get(x + dx, y) == "." and Map.get(x + dx, y + 1) == "."
                            and not (p.tx == x + dx and p.ty == y) then
                            Map.set(x, y, ".")
                            Map.set(x + dx, y, ch)
                            newFall[key(x + dx, y)] = true
                            moved[key(x + dx, y)] = true
                            rolled = true
                        end
                    end
                elseif Game.falling[key(x, y)] then
                    Snd.play("noise", 90, 0.06, 0.18) -- landed
                end
            end
        end
    end
    Game.falling = newFall
end

function Game.updatePlayer(dt, s)
    local p = Game.player
    if p.moving then
        local tx, ty = Map.cx(p.tx), Map.cy(p.ty)
        local sp = Config.STEP_SPEED * dt
        p.px = p.px + Util.clamp(tx - p.px, -sp, sp)
        p.py = p.py + Util.clamp(ty - p.py, -sp, sp)
        if math.abs(tx - p.px) < 0.5 and math.abs(ty - p.py) < 0.5 then
            p.px, p.py = tx, ty
            p.moving = false
        end
        return
    end
    local dx, dy = s.mx, s.my
    if dx ~= 0 then dy = 0 end
    if dx == 0 and dy == 0 then return end
    if dx ~= 0 then p.face = dx end
    local nx, ny = p.tx + dx, p.ty + dy
    local ch = Map.get(nx, ny)
    if ch == "d" then
        Map.set(nx, ny, ".")
        Harness.count("dug")
        Snd.play("noise", 500, 0.03, 0.08)
        Kit.burst(Game.parts, Map.cx(nx), Map.cy(ny), 3, 60)
    elseif ch == "*" then
        if Game.falling[key(nx, ny)] then return end
        Map.set(nx, ny, ".")
        State.gems = State.gems + 1
        State.score = State.score + 25
        Harness.count("gemsTaken")
        Snd.play("tri", 880, 0.06, 0.25)
        Util.after(0.07, function() Snd.play("tri", 1320, 0.1, 0.25) end)
        if State.gems >= State.need and not Game.exitOpen then Game.openExit() end
    elseif ch == "O" then
        -- shoulder a rock sideways into open space
        if dy ~= 0 or Game.falling[key(nx, ny)] or Map.get(nx + dx, ny) ~= "." then
            return
        end
        Map.set(nx + dx, ny, "O")
        Map.set(nx, ny, ".")
        Harness.count("pushes")
        Snd.play("noise", 140, 0.06, 0.2)
    elseif ch == "E" then
        p.tx, p.ty = nx, ny
        p.moving = true
        Game.levelClear()
        return
    elseif ch ~= "." then
        return -- steel or the closed door
    end
    p.tx, p.ty = nx, ny
    p.moving = true
end

function Game.openExit()
    Game.exitOpen = true
    Harness.count("exitopen")
    Map.each(function(x, y, ch)
        if ch == "X" then Map.set(x, y, "E") end
    end)
    Snd.play("tri", 523, 0.1, 0.3)
    Util.after(0.12, function() Snd.play("tri", 784, 0.15, 0.3) end)
end

function Game.levelClear()
    State.mode = "clear"
    Harness.count("clears")
    State.score = State.score + 250 + math.floor(State.time)
    Snd.play("tri", 523, 0.1, 0.3)
    Util.after(0.15, function() Snd.play("tri", 659, 0.1, 0.3) end)
    Util.after(0.3, function() Snd.play("tri", 784, 0.2, 0.3) end)
    Util.after(1.4, function()
        State.level = State.level + 1
        if State.level > Config.LEVELS then
            State.mode = "win"
            Harness.count("wins")
        else
            Game.startLevel()
        end
    end)
end

function Game.kill(tag)
    if State.mode ~= "play" then return end
    State.mode = "dying"
    Harness.count(tag)
    Harness.count("deaths")
    Kit.shake(0.4)
    Kit.burst(Game.parts, Game.player.px, Game.player.py, 14, 140, 40)
    Snd.boom(150, 4)
    State.lives = State.lives - 1
    Util.after(1.2, function()
        if State.lives <= 0 then
            State.mode = "over"
            Harness.count("gameovers")
        else
            Game.startLevel() -- a fresh cut of the same level
        end
    end)
end

-- ---------------------------------------------------------------------
-- Autopilot: BFS through diggable ground to the nearest safe gem (cells
-- under or beside an unsteady rock are avoided until there's no other
-- way), then to the open exit. After the first win it deliberately digs
-- out the ground under a rock and stands there.
local apFrame, apStuck, apLastProg, apWander = 0, 0, -1, 0
local apDir = { 1, 0 }

local function walkable(x, y)
    local ch = Map.get(x, y)
    return ch == "." or ch == "d" or ch == "*" or ch == "E"
end

-- a cell is dangerous if a rock could reach it in free fall (scan up the
-- open column — this is what makes digging straight down under a rock
-- lethal) or roll into it off a rounded pile next door
local function dangerAt(x, y)
    local yy = y - 1
    while yy >= 1 and Map.get(x, yy) == "." do
        yy = yy - 1
    end
    if Map.get(x, yy) == "O" then return true end
    for _, dx in ipairs({ -1, 1 }) do
        if Map.get(x + dx, y - 1) == "O" then
            local under = Map.get(x + dx, y)
            if under == "O" or under == "*" then return true end
        end
    end
    return false
end

local function apSteer(s, nx, ny)
    local p = Game.player
    s.mx, s.my = Util.sign(nx - p.tx), Util.sign(ny - p.ty)
    if s.mx ~= 0 then s.my = 0 end
end

function Game.autopilot(s)
    s.mx, s.my, s.confirm, s.peek = 0, 0, false, 0
    apFrame = apFrame + 1
    if State.mode ~= "play" then
        s.confirm = apFrame % 30 == 0
        return
    end
    local p = Game.player
    if p.moving then return end
    local won = (Harness.counters.wins or 0) >= 1

    -- periodic crank survey: exercises the camera-peek path
    if not won and apFrame % 600 < 30 then s.peek = 20 end

    -- reckless after the win: get under a rock (safe — it rests on the
    -- helmet), then dig straight down so it falls after us and lands on
    -- our head — the BD way to die
    if won then
        if Map.get(p.tx, p.ty - 1) == "O" then
            local below = Map.get(p.tx, p.ty + 1)
            if below == "d" or below == "." or below == "*" then
                s.my = 1
            elseif walkable(p.tx - 1, p.ty) then
                s.mx = -1 -- shaft blocked since we picked it: try another
            elseif walkable(p.tx + 1, p.ty) then
                s.mx = 1
            end
            return
        end
        local dist = Phys.bfs(p.tx, p.ty, walkable)
        local best, bx, by = 1e9, nil, nil
        Map.each(function(x, y, ch)
            if ch == "O" and walkable(x, y + 1) then
                -- need dig-room below the parking spot to lure the rock
                local deeper = Map.get(x, y + 2)
                if deeper == "d" or deeper == "." or deeper == "*" then
                    local d = dist[y + 1] and dist[y + 1][x]
                    if d and d < best then best, bx, by = d, x, y + 1 end
                end
            end
        end)
        if bx then
            local nx, ny = Phys.firstStep(dist, bx, by)
            if nx then apSteer(s, nx, ny) end
        end
        return
    end

    -- progress-based stuck detection
    local prog = (Harness.counters.gemsTaken or 0) * 10
        + (Harness.counters.clears or 0) * 1000
        + (Harness.counters.deaths or 0) * 100
    if prog ~= apLastProg then
        apLastProg, apStuck = prog, 0
    else
        apStuck = apStuck + 1
    end
    if apWander > 0 then
        apWander = apWander - 1
        if apFrame % 15 == 0 then
            apDir = Util.choose({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } })
        end
        s.mx, s.my = apDir[1], apDir[2]
        return
    end
    if apStuck > 300 then
        apStuck, apWander = 0, 60
        return
    end

    -- nearest goal: a gem, or the exit once it's open
    local wantCh = (State.gems >= State.need) and "E" or "*"
    local function seek(isOpen)
        local dist = Phys.bfs(p.tx, p.ty, isOpen)
        local best, bx, by = 1e9, nil, nil
        Map.each(function(x, y, ch)
            if ch == wantCh then
                local d = dist[y] and dist[y][x]
                if d and d < best then best, bx, by = d, x, y end
            end
        end)
        return bx, by, dist
    end
    local bx, by, dist = seek(function(x, y) return walkable(x, y) and not dangerAt(x, y) end)
    if not bx then
        bx, by, dist = seek(walkable) -- no safe route: risk it
    end
    if bx then
        local nx, ny = Phys.firstStep(dist, bx, by)
        if nx then apSteer(s, nx, ny) end
    end
end

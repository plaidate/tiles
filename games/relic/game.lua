-- Relic: rooms, sword, keys, boomerang, boss — the quest loop.

Game = {
    enemies = {},
    ebullets = {},
    pickups = {},
    parts = {},
    player = nil,
    room = nil, -- current room def
    boom = nil, -- boomerang in flight
    spinFx = 0,
    stabId = 0,
}

local function shotBlocked(x, y)
    local tx, ty = Map.tileAt(x, y)
    local d = Map.def(tx, ty)
    if not d then return true end
    return d.solid == true and not d.shootthru
end

function Game.init()
    State.reset()
    Game.room = World.enter(State.room)
end

function Game.startGame(continue)
    State.reset()
    if continue then
        if not State.load() then State.reset() end
    else
        playdate.datastore.delete("save")
        State.hasSave = false
    end
    State.mode = "play"
    Game.enterRoom(State.room, nil, nil, true)
end

-- find an open cell at/near (tx, ty) for spawning
local function findOpen(tx, ty)
    if not Map.solid(tx, ty) then return tx, ty end
    for r = 1, 6 do
        for dy = -r, r do
            for dx = -r, r do
                if not Map.solid(tx + dx, ty + dy) then return tx + dx, ty + dy end
            end
        end
    end
    return 13, 7
end

function Game.enterRoom(key, px, py, fresh)
    State.room = key
    Game.room = World.enter(key)
    Game.enemies, Game.ebullets, Game.pickups, Game.parts = {}, {}, {}, {}
    Game.boom = nil
    local r = Game.room
    -- findOpen guards against spawn coords landing on solid tiles
    for i, e in ipairs(r.enemies or {}) do
        local tx, ty = findOpen(e[2], e[3])
        Game.spawnEnemy(e[1], tx, ty)
    end
    for i, pk in ipairs(r.pickups or {}) do
        local id = key .. ":" .. i
        if not State.taken[id] then
            local tx, ty = findOpen(pk[2], pk[3])
            Game.pickups[#Game.pickups + 1] =
                { kind = pk[1], x = Map.cx(tx), y = Map.cy(ty), id = id }
        end
    end
    if r.boss and not State.bossDead then
        Game.enemies[#Game.enemies + 1] = {
            kind = "boss", x = Map.cx(r.boss.tx), y = Map.cy(r.boss.ty),
            hw = 10, hh = 8, hp = Config.BOSS_HP, speed = 26, spawnT = 4, t = 0,
        }
    elseif r.boss and State.bossDead and State.mode ~= "win" then
        Game.pickups[#Game.pickups + 1] =
            { kind = "relic", x = Map.cx(13), y = Map.cy(4) }
    end
    local p = Game.player
    if fresh or not p then
        local tx, ty = findOpen(13, 11)
        Game.player = {
            x = Map.cx(tx), y = Map.cy(ty), hw = 5, hh = 6,
            fx = 0, fy = -1, iframes = 1,
            swordCd = 0, swordT = 0, spinCd = 0,
        }
    else
        p.x, p.y = px, py
    end
    Harness.count("rooms")
    State.save()
end

function Game.update(dt)
    local s = Input.state
    if State.mode == "title" then
        if s.confirm then Game.startGame(false) end
        if s.alt and State.hasSave then Game.startGame(true) end
        return
    end
    if State.mode == "over" or State.mode == "win" then
        if s.confirm then
            Util.clearPending()
            State.reset()
        end
        return
    end
    Kit.updateShake(dt)
    Kit.updateParts(Game.parts, dt)
    Game.spinFx = math.max(0, Game.spinFx - dt)
    Game.updatePlayer(dt, s)
    if State.mode ~= "play" then return end
    Game.updateEnemies(dt)
    Game.updateEbullets(dt)
    Game.updateBoom(dt)
end

function Game.updatePlayer(dt, s)
    local p = Game.player
    p.iframes = math.max(0, p.iframes - dt)
    p.swordCd = math.max(0, p.swordCd - dt)
    p.swordT = math.max(0, p.swordT - dt)
    p.spinCd = math.max(0, p.spinCd - dt)
    local sp = Config.SPEED * dt
    local hx, hy = Phys.moveAssist(p, s.mx * sp, s.my * sp)
    if s.mx ~= 0 and s.my == 0 then
        p.fx, p.fy = Util.sign(s.mx), 0
    elseif s.my ~= 0 and s.mx == 0 then
        p.fx, p.fy = 0, Util.sign(s.my)
    end

    -- push into a locked door with a key to open it
    if (hx or hy) and State.keys > 0 then
        local tx, ty = Map.tileAt(p.x + p.fx * 14, p.y + p.fy * 14)
        local d = Map.def(tx, ty)
        if d and d.kind == "door" then Game.openDoor(tx, ty) end
    end

    -- edge gaps flip to the neighboring room
    local ex = Game.room.exits or {}
    if p.x < 12 and ex.w then return Game.enterRoom(ex.w, 376, p.y) end
    if p.x > 388 and ex.e then return Game.enterRoom(ex.e, 24, p.y) end
    if p.y < 28 and ex.n then return Game.enterRoom(ex.n, p.x, 212) end
    if p.y > 228 and ex.s then return Game.enterRoom(ex.s, p.x, 44) end

    -- stairs / dungeon mouth
    local tx, ty = Phys.cell(p)
    local d = Map.def(tx, ty)
    if d and d.kind == "warp" then
        for _, w in ipairs(Game.room.warps or {}) do
            if w.tx == tx and w.ty == ty then
                return Game.enterRoom(w.to, Map.cx(w.px), Map.cy(w.py))
            end
        end
    end

    -- sword
    if s.attack and p.swordCd <= 0 then
        p.swordCd = Config.SWORD_CD
        p.swordT = Config.SWORD_T
        Game.stabId = Game.stabId + 1
        Harness.count("stabs")
        Snd.play("saw", 700, 0.06, 0.2)
    end
    if p.swordT > 0 then
        local bx, by = p.x + p.fx * Config.SWORD_R, p.y + p.fy * Config.SWORD_R
        for i = #Game.enemies, 1, -1 do
            local e = Game.enemies[i]
            if e.hitStab ~= Game.stabId and Util.dist2(bx, by, e.x, e.y) < 260 then
                e.hitStab = Game.stabId
                Game.damageEnemy(i, 1)
            end
        end
    end

    -- spin attack (crank-charged)
    if s.spin and p.spinCd <= 0 then
        p.spinCd = Config.SPIN_CD
        Game.spinFx = 0.25
        Harness.count("spins")
        Snd.play("saw", 320, 0.1, 0.3)
        Util.after(0.08, function() Snd.play("saw", 480, 0.12, 0.3) end)
        for i = #Game.enemies, 1, -1 do
            local e = Game.enemies[i]
            if Util.dist2(p.x, p.y, e.x, e.y) < Config.SPIN_R * Config.SPIN_R then
                Game.damageEnemy(i, 2)
            end
        end
    end

    -- boomerang
    if s.item and State.hasBoom and not Game.boom then
        Game.boom = {
            x = p.x, y = p.y,
            vx = p.fx * Config.BOOM_SPEED, vy = p.fy * Config.BOOM_SPEED,
            t = 0, phase = "out",
        }
        Harness.count("booms")
        Snd.play("tri", 520, 0.06, 0.2)
    end

    -- pickups
    for i = #Game.pickups, 1, -1 do
        local pk = Game.pickups[i]
        if Util.dist2(pk.x, pk.y, p.x, p.y) < 144 then
            Game.collect(i)
        end
    end
end

function Game.collect(i)
    local pk = table.remove(Game.pickups, i)
    if pk.id then State.taken[pk.id] = true end
    Harness.count("pickups")
    Snd.play("tri", 660, 0.08, 0.25)
    Util.after(0.09, function() Snd.play("tri", 990, 0.12, 0.25) end)
    if pk.kind == "key" then
        State.keys = State.keys + 1
        Harness.count("keys")
    elseif pk.kind == "heart" then
        State.maxHearts = math.min(Config.MAX_HEARTS, State.maxHearts + 1)
        State.hearts = State.maxHearts
    elseif pk.kind == "dropheart" then
        State.hearts = math.min(State.maxHearts, State.hearts + 1)
    elseif pk.kind == "boom" then
        State.hasBoom = true
    elseif pk.kind == "relic" then
        State.mode = "win"
        Harness.count("wins")
        State.save()
    end
end

function Game.openDoor(tx, ty)
    State.keys = State.keys - 1
    Harness.count("doors")
    Snd.play("square", 440, 0.15, 0.3)
    local function openCell(cx, cy)
        local d = Map.def(cx, cy)
        if d and d.kind == "door" then
            Map.set(cx, cy, ".")
            State.doors[State.room .. ":" .. cx .. "," .. cy] = true
        end
    end
    openCell(tx, ty)
    openCell(tx + 1, ty)
    openCell(tx - 1, ty)
    openCell(tx, ty + 1)
    openCell(tx, ty - 1)
    State.save()
end

function Game.spawnEnemy(kind, tx, ty)
    local e = { kind = kind, x = Map.cx(tx), y = Map.cy(ty), hw = 6, hh = 6, t = math.random() * 9 }
    if kind == "blob" then
        e.hp, e.speed, e.dirT = 1, 24, 0
    elseif kind == "skel" then
        e.hp, e.speed, e.aimT = 2, 34, 0
    else -- shooter
        e.hp, e.shootT = 2, 1.5 + math.random()
    end
    Game.enemies[#Game.enemies + 1] = e
end

function Game.damageEnemy(i, n)
    local e = Game.enemies[i]
    e.hp = e.hp - n
    Kit.burst(Game.parts, e.x, e.y, 4, 90)
    if e.hp > 0 then
        Snd.play("noise", 300, 0.06, 0.2)
        return
    end
    table.remove(Game.enemies, i)
    Harness.count("kills")
    Kit.burst(Game.parts, e.x, e.y, 10, 120, 30)
    Snd.play("noise", 160, 0.18, 0.28)
    if e.kind == "boss" then
        State.bossDead = true
        Harness.count("bosskills")
        Kit.shake(0.5)
        Snd.boom(140, 5)
        Game.pickups[#Game.pickups + 1] =
            { kind = "relic", x = Map.cx(13), y = Map.cy(4) }
        State.save()
    elseif e.kind == "blob" and math.random() < 0.25 then
        Game.pickups[#Game.pickups + 1] = { kind = "dropheart", x = e.x, y = e.y }
    end
end

function Game.updateEnemies(dt)
    local p = Game.player
    for i = #Game.enemies, 1, -1 do
        local e = Game.enemies[i]
        e.t = e.t + dt
        if e.stun and e.stun > 0 then
            e.stun = e.stun - dt
            if e.stun <= 0 then e.stun = nil end
        elseif e.kind == "blob" then
            e.dirT = e.dirT - dt
            if e.dirT <= 0 then
                e.dirT = 0.8 + math.random() * 0.9
                local d = Util.choose({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0, 0 } })
                e.vx, e.vy = d[1] * e.speed, d[2] * e.speed
            end
            Phys.move(e, (e.vx or 0) * dt, (e.vy or 0) * dt)
        elseif e.kind == "skel" then
            e.aimT = e.aimT - dt
            if e.aimT <= 0 then
                e.aimT = 0.5
                local d = math.max(1, math.sqrt(Util.dist2(e.x, e.y, p.x, p.y)))
                e.vx, e.vy = (p.x - e.x) / d * e.speed, (p.y - e.y) / d * e.speed
            end
            local hx, hy = Phys.move(e, (e.vx or 0) * dt, (e.vy or 0) * dt)
            if hx then e.vx = -(e.vx or 0) * 0.5 end
            if hy then e.vy = -(e.vy or 0) * 0.5 end
        elseif e.kind == "shooter" then
            e.shootT = e.shootT - dt
            if e.shootT <= 0 then
                e.shootT = 2.5
                local d = math.max(1, math.sqrt(Util.dist2(e.x, e.y, p.x, p.y)))
                Game.ebullets[#Game.ebullets + 1] = {
                    x = e.x, y = e.y,
                    vx = (p.x - e.x) / d * 100, vy = (p.y - e.y) / d * 100,
                }
                Harness.count("espits")
                Snd.play("tri", 300, 0.08, 0.2)
            end
        else -- boss: lumber at the player, call little blobs
            local d = math.max(1, math.sqrt(Util.dist2(e.x, e.y, p.x, p.y)))
            Phys.move(e, (p.x - e.x) / d * e.speed * dt, (p.y - e.y) / d * e.speed * dt)
            e.spawnT = e.spawnT - dt
            if e.spawnT <= 0 then
                e.spawnT = 4
                local minions = 0
                for j = 1, #Game.enemies do
                    if Game.enemies[j].kind == "blob" then minions = minions + 1 end
                end
                if minions < 2 then
                    local tx, ty = Phys.cell(e)
                    Game.spawnEnemy("blob", tx, ty)
                    Snd.play("noise", 220, 0.1, 0.2)
                end
            end
        end
        local touchR = e.kind == "boss" and 256 or 121
        if (not e.stun) and Util.dist2(e.x, e.y, p.x, p.y) < touchR then
            Game.hurtPlayer(e.x, e.y)
        end
    end
end

function Game.updateEbullets(dt)
    local p = Game.player
    for i = #Game.ebullets, 1, -1 do
        local b = Game.ebullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if Harness.enabled then
            local d = Util.dist2(b.x, b.y, p.x, p.y)
            if not Game.minBd or d < Game.minBd then Game.minBd = d end
        end
        if shotBlocked(b.x, b.y) then
            table.remove(Game.ebullets, i)
            Harness.count("bblocked")
            if Harness.enabled then
                local tx, ty = Map.tileAt(b.x, b.y)
                Game.lastBlock = tx .. "," .. ty .. "=" .. tostring(Map.get(tx, ty))
            end
        elseif Util.dist2(b.x, b.y, p.x, p.y) < 81 then
            table.remove(Game.ebullets, i)
            Harness.count("bhits")
            Game.hurtPlayer(b.x, b.y)
        end
    end
end

function Game.updateBoom(dt)
    local bm = Game.boom
    if not bm then return end
    local p = Game.player
    bm.t = bm.t + dt
    if bm.phase == "out" then
        bm.x = bm.x + bm.vx * dt
        bm.y = bm.y + bm.vy * dt
        if bm.t > Config.BOOM_RANGE or shotBlocked(bm.x, bm.y) then
            bm.phase = "back"
        end
    else
        local d = math.max(1, math.sqrt(Util.dist2(bm.x, bm.y, p.x, p.y)))
        bm.x = bm.x + (p.x - bm.x) / d * 180 * dt
        bm.y = bm.y + (p.y - bm.y) / d * 180 * dt
        if d < 10 then
            Game.boom = nil
            return
        end
    end
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        if e.kind ~= "boss" and not e.stun
            and Util.dist2(bm.x, bm.y, e.x, e.y) < 144 then
            e.stun = 1.8
            Harness.count("stuns")
            Snd.play("square", 990, 0.05, 0.2)
        end
    end
    for i = #Game.pickups, 1, -1 do
        local pk = Game.pickups[i]
        if Util.dist2(bm.x, bm.y, pk.x, pk.y) < 100 then
            Game.collect(i)
        end
    end
end

function Game.hurtPlayer(sx, sy)
    local p = Game.player
    if p.iframes > 0 then return end
    p.iframes = Config.IFRAMES
    State.hearts = State.hearts - 1
    Harness.count("hurts")
    Kit.shake(0.3)
    Kit.burst(Game.parts, p.x, p.y, 8, 120, 30)
    Snd.boom(180, 3)
    -- knockback away from the source
    local d = math.max(1, math.sqrt(Util.dist2(p.x, p.y, sx, sy)))
    Phys.move(p, (p.x - sx) / d * Config.KNOCKBACK, (p.y - sy) / d * Config.KNOCKBACK)
    if State.hearts <= 0 then
        State.mode = "over"
        Harness.count("gameovers")
    end
end

-- ---------------------------------------------------------------------
-- Autopilot: follows the quest route (key -> dungeon door -> descend ->
-- boss key -> boss door -> boss -> relic), navigating the room graph and
-- fighting through with advance-stabs. After the win it walks into d3
-- and stands still to exercise death and game over; at the title it
-- continues a save when one exists, which also exercises State.load().
local ROUTE = {
    { type = "pickup", room = "o2_2", id = "o2_2:1" },
    { type = "door", room = "o3_1", tx = 13, ty = 5 },
    { type = "room", room = "d1" },
    { type = "pickup", room = "d2", id = "d2:1" },
    { type = "door", room = "d3", tx = 12, ty = 1 },
    { type = "boss", room = "d4" },
    { type = "win", room = "d4" },
}

local apFrame, apStuck, apLastProg, apWander = 0, 0, -1, 0
local apDir = { 1, 0 }
Game.apIndex = 1

local function goalDone(g)
    if g.type == "pickup" then return State.taken[g.id] == true end
    if g.type == "door" then
        return State.doors[g.room .. ":" .. g.tx .. "," .. g.ty] == true
    end
    if g.type == "room" then return State.room == g.room end
    if g.type == "boss" then return State.bossDead end
    return (Harness.counters.wins or 0) >= 1
end

-- next room on the way to target, via exits and warps
local function nextRoomHop(target)
    if State.room == target then return nil end
    local seen, queue, head = { [State.room] = true }, { { State.room } }, 1
    while queue[head] do
        local path = queue[head]
        head = head + 1
        local last = path[#path]
        local room = World.ROOMS[last]
        local links = {}
        for _, r in pairs(room.exits or {}) do links[#links + 1] = r end
        for _, w in ipairs(room.warps or {}) do links[#links + 1] = w.to end
        for i = 1, #links do
            local r = links[i]
            if not seen[r] then
                seen[r] = true
                local np = { table.unpack(path) }
                np[#np + 1] = r
                if r == target then return np[2] end
                queue[#queue + 1] = np
            end
        end
    end
    return nil
end

-- the cell to walk to so we cross into `hop`
local function hopTargetCell(hop)
    local room = World.ROOMS[State.room]
    for _, w in ipairs(room.warps or {}) do
        if w.to == hop then return w.tx, w.ty end
    end
    local ex = room.exits or {}
    if ex.n == hop then return 12, 1 end
    if ex.s == hop then return 12, 14 end
    if ex.w == hop then return 1, 8 end
    if ex.e == hop then return 25, 8 end
    return nil
end

local function apSteerTo(s, nx, ny)
    local p = Game.player
    local dx, dy = Map.cx(nx) - p.x, Map.cy(ny) - p.y
    if math.abs(dx) >= math.abs(dy) and dx ~= 0 then
        s.mx = Util.sign(dx)
    else
        s.my = Util.sign(dy)
    end
end

local function apWalkTo(s, tx, ty)
    local p = Game.player
    local ptx, pty = Phys.cell(p)
    if ptx == tx and pty == ty then
        -- keep pressing toward the cell center: border cells flip the
        -- room before the center is ever reached, so stopping at the
        -- cell edge would strand us in the transition dead zone
        local dx, dy = Map.cx(tx) - p.x, Map.cy(ty) - p.y
        if math.abs(dx) + math.abs(dy) > 2 then
            if math.abs(dx) >= math.abs(dy) then
                s.mx = Util.sign(dx)
            else
                s.my = Util.sign(dy)
            end
            return false
        end
        return true
    end
    local dist = Phys.bfs(ptx, pty, function(x, y) return not Map.solid(x, y) end)
    local nx, ny = Phys.firstStep(dist, tx, ty)
    if nx then
        apSteerTo(s, nx, ny)
    else
        -- unreachable (e.g. a locked door cell): press toward it directly
        apSteerTo(s, tx, ty)
    end
    return false
end

function Game.autopilot(s)
    s.mx, s.my, s.attack, s.spin, s.item, s.confirm, s.alt = 0, 0, false, false, false, false, false
    apFrame = apFrame + 1
    if State.mode == "title" then
        if apFrame % 30 == 0 then
            if State.hasSave then s.alt = true else s.confirm = true end
        end
        return
    end
    if State.mode ~= "play" then
        s.confirm = apFrame % 30 == 0
        return
    end
    local p = Game.player
    local won = (Harness.counters.wins or 0) >= 1

    -- combat overlay: stab anything close, spin when swamped
    local ne, nd = nil, 1e9
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        local d = Util.dist2(e.x, e.y, p.x, p.y)
        if d < nd then ne, nd = e, d end
    end
    if not won and ne and nd < 34 * 34 then
        local close = 0
        for i = 1, #Game.enemies do
            if Util.dist2(Game.enemies[i].x, Game.enemies[i].y, p.x, p.y) < 34 * 34 then
                close = close + 1
            end
        end
        if p.spinCd <= 0 and (close >= 2 or nd < 18 * 18) then s.spin = true end
        -- hit-and-run: retreat while the sword recovers, stab on approach
        local dx, dy = ne.x - p.x, ne.y - p.y
        if p.swordCd > 0.1 and nd < 26 * 26 then
            s.mx, s.my = -Util.sign(dx), -Util.sign(dy)
        else
            if math.abs(dx) >= math.abs(dy) then
                s.mx = Util.sign(dx)
            else
                s.my = Util.sign(dy)
            end
            if nd < 24 * 24 then s.attack = true end
        end
        return
    end

    -- reckless after the win: stand in d3's open field (clear firing
    -- lines, next to the skeleton) and let the dungeon win
    if won then
        if State.room ~= "d3" then
            local hop = nextRoomHop("d3")
            if hop then
                local tx, ty = hopTargetCell(hop)
                if tx then apWalkTo(s, tx, ty) end
            end
        else
            apWalkTo(s, 13, 11)
        end
        return
    end

    -- dodge shooter bullets
    local nb, nbd = nil, 40 * 40
    for i = 1, #Game.ebullets do
        local b = Game.ebullets[i]
        local d = Util.dist2(b.x, b.y, p.x, p.y)
        if d < nbd then nb, nbd = b, d end
    end
    if nb then
        local px, py = -nb.vy, nb.vx
        if px * (p.x - nb.x) + py * (p.y - nb.y) < 0 then px, py = -px, -py end
        s.mx, s.my = Util.sign(px), Util.sign(py)
        return
    end

    -- progress-based stuck detection
    local prog = Game.apIndex * 1000 + (Harness.counters.kills or 0) * 10
        + (Harness.counters.rooms or 0)
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
    if apStuck > 360 then
        apStuck, apWander = 0, 45
        return
    end

    -- advance the route
    while Game.apIndex <= #ROUTE and goalDone(ROUTE[Game.apIndex]) do
        Game.apIndex = Game.apIndex + 1
    end
    local g = ROUTE[Game.apIndex]
    if not g then return end
    if State.room ~= g.room then
        local hop = nextRoomHop(g.room)
        if hop then
            local tx, ty = hopTargetCell(hop)
            if tx then apWalkTo(s, tx, ty) end
        end
        return
    end
    if g.type == "pickup" or g.type == "win" then
        for i = 1, #Game.pickups do
            local pk = Game.pickups[i]
            if (g.type == "win" and pk.kind == "relic") or pk.id == g.id then
                local tx, ty = Map.tileAt(pk.x, pk.y)
                apWalkTo(s, tx, ty)
                return
            end
        end
    elseif g.type == "door" then
        -- stand under the door and push into it
        local below = g.ty + 1
        if apWalkTo(s, g.tx, below) then
            s.my = -1
        end
    elseif g.type == "boss" then
        for i = 1, #Game.enemies do
            local e = Game.enemies[i]
            if e.kind == "boss" then
                local tx, ty = Map.tileAt(e.x, e.y)
                apWalkTo(s, tx, ty)
                return
            end
        end
    end
end

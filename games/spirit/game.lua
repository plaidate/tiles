-- Spirit: waves of yokai vs talismans and the wand sweep.

Game = {
    shots = {},    -- player talismans
    ebullets = {}, -- enemy shots
    enemies = {},
    parts = {},
    player = nil,
    queue = {},
    spawnT = 0,
    sweepFx = 0,
}

-- bullets fly over ponds but stop on walls and lanterns
local function shotBlocked(x, y)
    local tx, ty = Map.tileAt(x, y)
    local d = Map.def(tx, ty)
    if not d then return true end
    return d.solid == true and not d.shootthru
end

function Game.init()
    State.reset()
    Arena.build()
end

function Game.startGame()
    State.reset()
    Game.shots, Game.ebullets, Game.enemies, Game.parts = {}, {}, {}, {}
    Game.player = {
        x = 200, y = Map.cy(11), hw = 5, hh = 6,
        fx = 0, fy = -1, iframes = 1, shotCd = 0, sweepCd = 0,
    }
    Game.startWave()
end

function Game.startWave()
    local mix = Config.MIX[math.min(State.wave, #Config.MIX)]
    Game.queue = {}
    local function push(kind, n)
        for _ = 1, n do Game.queue[#Game.queue + 1] = kind end
    end
    push("ghost", mix.ghosts)
    push("spitter", mix.spitters)
    push("dasher", mix.dashers)
    -- shuffle so kinds interleave
    for i = #Game.queue, 2, -1 do
        local j = math.random(i)
        Game.queue[i], Game.queue[j] = Game.queue[j], Game.queue[i]
    end
    Game.spawnT = 0.3
    State.mode = "wavein"
    State.waveT = 1.2
    Snd.play("tri", 392, 0.12, 0.25)
    Snd.play("tri", 523, 0.2, 0.25)
end

function Game.update(dt)
    local s = Input.state
    if State.mode == "title" then
        if s.confirm then Game.startGame() end
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
    Game.sweepFx = math.max(0, Game.sweepFx - dt)
    if State.mode == "wavein" then
        State.waveT = State.waveT - dt
        if State.waveT <= 0 then State.mode = "play" end
        return
    end
    -- trickle this wave's spawns in
    if #Game.queue > 0 then
        Game.spawnT = Game.spawnT - dt
        if Game.spawnT <= 0 then
            Game.spawnT = math.max(0.4, Config.SPAWN_T - State.wave * 0.05)
            Game.spawnEnemy(table.remove(Game.queue))
        end
    end
    Game.updatePlayer(dt, s)
    Game.updateShots(dt)
    Game.updateEnemies(dt)
    Game.updateEbullets(dt)
    if State.mode == "play" and #Game.queue == 0 and #Game.enemies == 0 then
        Harness.count("waveclears")
        State.score = State.score + 250
        State.wave = State.wave + 1
        if State.wave > Config.WAVES then
            State.mode = "win"
            Harness.count("wins")
        else
            Game.startWave()
        end
    end
end

function Game.updatePlayer(dt, s)
    local p = Game.player
    p.iframes = math.max(0, p.iframes - dt)
    p.shotCd = math.max(0, p.shotCd - dt)
    p.sweepCd = math.max(0, p.sweepCd - dt)
    local sp = Config.PLAYER_SPEED * dt
    Phys.move(p, s.mx * sp, s.my * sp)
    -- cardinal facing from single-axis input; diagonals keep the old one
    if s.mx ~= 0 and s.my == 0 then
        p.fx, p.fy = Util.sign(s.mx), 0
    elseif s.my ~= 0 and s.mx == 0 then
        p.fx, p.fy = 0, Util.sign(s.my)
    end
    if s.fire and p.shotCd <= 0 then
        p.shotCd = Config.SHOT_CD
        Game.shots[#Game.shots + 1] = {
            x = p.x + p.fx * 8, y = p.y + p.fy * 8,
            vx = p.fx * Config.SHOT_SPEED, vy = p.fy * Config.SHOT_SPEED,
        }
        Harness.count("shots")
        Snd.play("square", 880, 0.04, 0.12)
    end
    if s.sweep and p.sweepCd <= 0 then Game.sweep() end
end

function Game.sweep()
    local p = Game.player
    p.sweepCd = Config.SWEEP_CD
    Game.sweepFx = 0.25
    Harness.count("sweeps")
    Snd.play("saw", 250, 0.12, 0.3)
    Util.after(0.08, function() Snd.play("saw", 380, 0.12, 0.3) end)
    for i = #Game.enemies, 1, -1 do
        local e = Game.enemies[i]
        if not e.spawning
            and Util.dist2(e.x, e.y, p.x, p.y) < Config.SWEEP_R * Config.SWEEP_R then
            Game.killEnemy(i)
        end
    end
    for i = #Game.ebullets, 1, -1 do
        local b = Game.ebullets[i]
        if Util.dist2(b.x, b.y, p.x, p.y) < Config.SWEEP_BULLET_R * Config.SWEEP_BULLET_R then
            Kit.burst(Game.parts, b.x, b.y, 3, 60)
            table.remove(Game.ebullets, i)
            Harness.count("swept")
        end
    end
end

function Game.spawnEnemy(kind)
    local tx, ty = Arena.spawnCell()
    local e = {
        x = Map.cx(tx), y = Map.cy(ty), kind = kind,
        hw = 6, hh = 6, spawning = 1, t = math.random() * 10,
    }
    if kind == "ghost" then
        e.hp, e.speed = 1, 26 + State.wave * 2
    elseif kind == "spitter" then
        e.hp, e.shootT = 2, 1 + math.random()
    else -- dasher
        e.hp, e.state, e.stT = 1, "idle", 1.2
    end
    Game.enemies[#Game.enemies + 1] = e
    Harness.count("spawns")
end

function Game.killEnemy(i)
    local e = table.remove(Game.enemies, i)
    Harness.count("kills")
    State.score = State.score
        + (e.kind == "spitter" and 200 or e.kind == "dasher" and 150 or 100)
    Kit.burst(Game.parts, e.x, e.y, 8, 120, 30)
    Snd.play("noise", 180, 0.15, 0.25)
end

function Game.updateShots(dt)
    for i = #Game.shots, 1, -1 do
        local sh = Game.shots[i]
        sh.x = sh.x + sh.vx * dt
        sh.y = sh.y + sh.vy * dt
        local dead = shotBlocked(sh.x, sh.y)
        if not dead then
            for j = #Game.enemies, 1, -1 do
                local e = Game.enemies[j]
                if not e.spawning and Util.dist2(sh.x, sh.y, e.x, e.y) < 100 then
                    e.hp = e.hp - 1
                    if e.hp <= 0 then Game.killEnemy(j) end
                    Kit.burst(Game.parts, sh.x, sh.y, 3, 70)
                    dead = true
                    break
                end
            end
        end
        if dead then table.remove(Game.shots, i) end
    end
end

function Game.updateEnemies(dt)
    local p = Game.player
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        e.t = e.t + dt
        if e.spawning then
            e.spawning = e.spawning - dt
            if e.spawning <= 0 then e.spawning = nil end
        elseif e.kind == "ghost" then
            -- drift at the player with a perpendicular wobble; ghosts
            -- float over lanterns and ponds, walls still bound them
            local d = math.max(1, math.sqrt(Util.dist2(e.x, e.y, p.x, p.y)))
            local nx, ny = (p.x - e.x) / d, (p.y - e.y) / d
            local wob = math.sin(e.t * 3) * 14
            e.x = Util.clamp(e.x + (nx * e.speed - ny * wob) * dt, 22, 378)
            e.y = Util.clamp(e.y + (ny * e.speed + nx * wob) * dt, 38, 218)
        elseif e.kind == "spitter" then
            e.shootT = e.shootT - dt
            if e.shootT <= 0 then
                e.shootT = 2.2
                local d = math.max(1, math.sqrt(Util.dist2(e.x, e.y, p.x, p.y)))
                Game.ebullets[#Game.ebullets + 1] = {
                    x = e.x, y = e.y,
                    vx = (p.x - e.x) / d * 90, vy = (p.y - e.y) / d * 90,
                }
                Harness.count("espits")
                Snd.play("tri", 330, 0.08, 0.2)
            end
        else -- dasher: wind up, then charge in a straight line
            if e.state == "idle" then
                e.stT = e.stT - dt
                if e.stT <= 0 then
                    local d = math.max(1, math.sqrt(Util.dist2(e.x, e.y, p.x, p.y)))
                    e.vx, e.vy = (p.x - e.x) / d * 170, (p.y - e.y) / d * 170
                    e.state, e.stT = "dash", 0.55
                    Snd.play("noise", 400, 0.1, 0.2)
                end
            else
                e.stT = e.stT - dt
                local hx, hy = Phys.move(e, e.vx * dt, e.vy * dt)
                if hx or hy or e.stT <= 0 then e.state, e.stT = "idle", 1.1 end
            end
        end
        if not e.spawning and Util.dist2(e.x, e.y, p.x, p.y) < 121 then
            Game.hurtPlayer()
        end
    end
end

function Game.updateEbullets(dt)
    local p = Game.player
    for i = #Game.ebullets, 1, -1 do
        local b = Game.ebullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if shotBlocked(b.x, b.y) then
            table.remove(Game.ebullets, i)
        elseif Util.dist2(b.x, b.y, p.x, p.y) < 81 then
            table.remove(Game.ebullets, i)
            Game.hurtPlayer()
        end
    end
end

function Game.hurtPlayer()
    local p = Game.player
    if p.iframes > 0 then return end
    p.iframes = Config.IFRAMES
    State.hearts = State.hearts - 1
    Harness.count("hurts")
    Kit.shake(0.3)
    Kit.burst(Game.parts, p.x, p.y, 10, 130, 40)
    Snd.boom(180, 3)
    if State.hearts <= 0 then
        State.mode = "over"
        Harness.count("gameovers")
    end
end

-- Autopilot: align on an axis with the nearest yokai and advance-fire
-- (this scheme shoots the way you move, same as a human); break off when
-- close, dodge incoming shots perpendicular, sweep point-blank threats.
-- Reckless after the first win: stand still and take it.
local apFrame, apStuck, apLastKills, apWander = 0, 0, -1, 0
local apDir = { 1, 0 }

function Game.autopilot(s)
    s.mx, s.my, s.fire, s.sweep, s.confirm = 0, 0, false, false, false
    apFrame = apFrame + 1
    if State.mode ~= "play" then
        s.confirm = apFrame % 30 == 0
        return
    end
    local p = Game.player
    if (Harness.counters.wins or 0) >= 1 then return end

    -- panic sweep
    if p.sweepCd <= 0 then
        for i = 1, #Game.enemies do
            local e = Game.enemies[i]
            if not e.spawning and Util.dist2(e.x, e.y, p.x, p.y) < 900 then
                s.sweep = true
                break
            end
        end
        if not s.sweep then
            for i = 1, #Game.ebullets do
                local b = Game.ebullets[i]
                if Util.dist2(b.x, b.y, p.x, p.y) < 676 then
                    s.sweep = true
                    break
                end
            end
        end
    end

    -- dodge the nearest incoming bullet: strafe perpendicular
    local nb, nbd = nil, 45 * 45
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

    -- stuck? (kills stalled while enemies live) -> wander burst
    local kills = Harness.counters.kills or 0
    if kills ~= apLastKills then
        apLastKills, apStuck = kills, 0
    elseif #Game.enemies > 0 then
        apStuck = apStuck + 1
    end
    if apWander > 0 then
        apWander = apWander - 1
        if apFrame % 15 == 0 then
            apDir = Util.choose({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, -1 } })
        end
        s.mx, s.my = apDir[1], apDir[2]
        return
    end
    if apStuck > 300 then
        apStuck, apWander = 0, 45
        return
    end

    -- nearest live yokai
    local ne, nd = nil, 1e9
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        if not e.spawning then
            local d = Util.dist2(e.x, e.y, p.x, p.y)
            if d < nd then ne, nd = e, d end
        end
    end
    if not ne then return end
    local dx, dy = ne.x - p.x, ne.y - p.y
    if nd < 55 * 55 and math.abs(dx) < 40 and math.abs(dy) < 40 then
        -- too close: back off diagonally
        s.mx, s.my = -Util.sign(dx), -Util.sign(dy)
        return
    end
    if math.abs(dx) >= math.abs(dy) then
        if math.abs(dy) > 10 then
            s.my = Util.sign(dy) -- line up the row first
        else
            s.mx = Util.sign(dx) -- advance-fire
            s.fire = true
        end
    else
        if math.abs(dx) > 10 then
            s.mx = Util.sign(dx)
        else
            s.my = Util.sign(dy)
            s.fire = true
        end
    end
end

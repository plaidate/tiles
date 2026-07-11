-- Blast: bombs, flames, walkers and the level loop.

Game = {
    bombs = {},
    flames = {},   -- key -> {tx, ty, t}
    powerups = {}, -- {tx, ty, kind}
    enemies = {},
    parts = {},
    player = nil,
}

local function key(tx, ty) return ty * 64 + tx end

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

function Game.init()
    State.reset()
    Arena.generate(1)
    Map.build()
end

function Game.bombAt(tx, ty)
    for i = 1, #Game.bombs do
        local b = Game.bombs[i]
        if b.tx == tx and b.ty == ty then return b end
    end
end

function Game.powerAt(tx, ty)
    for i = #Game.powerups, 1, -1 do
        local p = Game.powerups[i]
        if p.tx == tx and p.ty == ty then return p, i end
    end
end

-- solidity for the player: map solids + bombs. A fresh bomb stays
-- walkable until the player's BOX fully clears its cell (center-cell
-- checks freeze you straddling the boundary), then hardens for good.
function Game.solidFor(a)
    return function(tx, ty)
        if Map.solid(tx, ty) then return true end
        local b = Game.bombAt(tx, ty)
        if b and not b.walkable then return true end
        return false
    end
end

function Game.startGame()
    State.reset()
    State.mode = "play"
    Game.startLevel()
end

function Game.startLevel()
    Arena.generate(State.level)
    Map.build()
    Game.bombs, Game.flames, Game.powerups, Game.parts = {}, {}, {}, {}
    Game.player = { x = Map.cx(2), y = Map.cy(2), hw = 6, hh = 6, invuln = 2, face = 1 }
    Game.enemies = Arena.spawnEnemies(State.level)
    State.mode = "play"
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
    Game.updateBombs(dt)
    Game.updateFlames(dt)
    if State.mode == "play" then
        Game.updatePlayer(dt, s)
        Game.updateEnemies(dt)
        Game.checkDeaths()
        if #Game.enemies == 0 then Game.levelClear() end
    end
end

function Game.updatePlayer(dt, s)
    local p = Game.player
    p.invuln = math.max(0, p.invuln - dt)
    local speed = (Config.BASE_SPEED + State.boots * Config.BOOT_SPEED) * dt
    local dx, dy = s.mx * speed, s.my * speed
    if dx ~= 0 and dy ~= 0 then dy = 0 end -- 4-way like the classic
    if dx ~= 0 then p.face = Util.sign(dx) end
    Phys.moveAssist(p, dx, dy, Game.solidFor(p))
    if s.bomb then Game.dropBomb(s.fuse) end
    local tx, ty = Phys.cell(p)
    local pu, i = Game.powerAt(tx, ty)
    if pu then
        table.remove(Game.powerups, i)
        Harness.count("powerups")
        State.score = State.score + 50
        Snd.play("tri", 660, 0.08, 0.3)
        Util.after(0.09, function() Snd.play("tri", 880, 0.12, 0.3) end)
        if pu.kind == "B" then
            State.maxBombs = math.min(5, State.maxBombs + 1)
        elseif pu.kind == "F" then
            State.power = math.min(6, State.power + 1)
        else
            State.boots = math.min(3, State.boots + 1)
        end
    end
end

function Game.dropBomb(fuse)
    local p = Game.player
    local tx, ty = Phys.cell(p)
    if #Game.bombs >= State.maxBombs or Game.bombAt(tx, ty) then return end
    Game.bombs[#Game.bombs + 1] = {
        tx = tx, ty = ty,
        fuse = Util.clamp(fuse or 2, Config.FUSE_MIN, Config.FUSE_MAX),
        power = State.power, t = 0, walkable = true,
    }
    Harness.count("bombs")
    Snd.play("square", 196, 0.06, 0.2)
end

function Game.updateBombs(dt)
    local p = Game.player
    for i = #Game.bombs, 1, -1 do
        local b = Game.bombs[i]
        b.fuse = b.fuse - dt
        b.t = b.t + dt
        if b.walkable and p then
            -- harden once the player's box has cleared the bomb's cell
            local ov = math.abs(p.x - Map.cx(b.tx)) < 8 + p.hw
                and math.abs(p.y - Map.cy(b.ty)) < 8 + p.hh
            if not ov then b.walkable = false end
        end
        if b.fuse <= 0 then Game.explode(b) end
    end
end

function Game.flameCell(tx, ty)
    Game.flames[key(tx, ty)] = { tx = tx, ty = ty, t = Config.FLAME_T }
    local pu, i = Game.powerAt(tx, ty)
    if pu then table.remove(Game.powerups, i) end
end

function Game.explode(b)
    for i = #Game.bombs, 1, -1 do
        if Game.bombs[i] == b then
            table.remove(Game.bombs, i)
            break
        end
    end
    Harness.count("booms")
    if Harness.enabled and Game.player then
        -- was the player inside this bomb's blast at detonation?
        local dang = Game.dangerCellsOf({ b })
        local ptx, pty = Phys.cell(Game.player)
        if dang[key(ptx, pty)] then Harness.count("boomHitP") end
    end
    Snd.boom(220, 3)
    Kit.shake(0.2)
    Game.flameCell(b.tx, b.ty)
    for d = 1, 4 do
        for i = 1, b.power do
            local tx, ty = b.tx + DIRS[d][1] * i, b.ty + DIRS[d][2] * i
            local ch = Map.get(tx, ty)
            if ch == nil or ch == "#" or ch == "%" then break end
            if ch == "x" then
                Map.set(tx, ty, ".")
                Harness.count("crates")
                State.score = State.score + 10
                Kit.burst(Game.parts, Map.cx(tx), Map.cy(ty), 6, 110, 30)
                if math.random() < Config.DROP_CHANCE then
                    Game.powerups[#Game.powerups + 1] =
                        { tx = tx, ty = ty, kind = Util.choose({ "B", "F", "S" }) }
                end
                Game.flameCell(tx, ty)
                break
            end
            local ob = Game.bombAt(tx, ty)
            if ob and ob.fuse > 0.05 then ob.fuse = 0.05 end
            Game.flameCell(tx, ty)
        end
    end
end

function Game.updateFlames(dt)
    for k, f in pairs(Game.flames) do
        f.t = f.t - dt
        if f.t <= 0 then Game.flames[k] = nil end
    end
end

-- enemies walk open-cell-center to open-cell-center; hounds path toward
-- the player, puffs wander without reversing unless dead-ended
local function isOpenCell(tx, ty)
    return not Map.solid(tx, ty) and not Game.bombAt(tx, ty)
end

local function pickNext(e)
    local tx, ty = Map.tileAt(e.x, e.y)
    if e.kind == "hound" and math.random() < 0.8 then
        local ptx, pty = Phys.cell(Game.player)
        local dist = Phys.bfs(ptx, pty, isOpenCell)
        local dx, dy = Phys.descend(dist, tx, ty)
        if dx then
            e.ntx, e.nty, e.pdx, e.pdy = tx + dx, ty + dy, dx, dy
            return
        end
    end
    local fwd, all = {}, {}
    for i = 1, 4 do
        local dx, dy = DIRS[i][1], DIRS[i][2]
        if isOpenCell(tx + dx, ty + dy) then
            all[#all + 1] = DIRS[i]
            if not (dx == -(e.pdx or 0) and dy == -(e.pdy or 0)) then
                fwd[#fwd + 1] = DIRS[i]
            end
        end
    end
    local pick = #fwd > 0 and Util.choose(fwd) or (#all > 0 and Util.choose(all) or nil)
    if not pick then return end
    e.ntx, e.nty = tx + pick[1], ty + pick[2]
    e.pdx, e.pdy = pick[1], pick[2]
end

function Game.updateEnemies(dt)
    for i = 1, #Game.enemies do
        local e = Game.enemies[i]
        if not e.ntx then pickNext(e) end
        if e.ntx then
            if not isOpenCell(e.ntx, e.nty) then
                e.ntx = nil -- a bomb dropped in the way; rethink
            else
                local cx, cy = Map.cx(e.ntx), Map.cy(e.nty)
                local sp = e.speed * dt
                e.x = e.x + Util.clamp(cx - e.x, -sp, sp)
                e.y = e.y + Util.clamp(cy - e.y, -sp, sp)
                if math.abs(cx - e.x) < 0.5 and math.abs(cy - e.y) < 0.5 then
                    e.x, e.y = cx, cy
                    e.ntx = nil
                end
            end
        end
    end
end

function Game.checkDeaths()
    local p = Game.player
    for i = #Game.enemies, 1, -1 do
        local e = Game.enemies[i]
        local tx, ty = Map.tileAt(e.x, e.y)
        if Game.flames[key(tx, ty)] then
            table.remove(Game.enemies, i)
            Harness.count("kills")
            State.score = State.score + (e.kind == "hound" and 200 or 100)
            Kit.burst(Game.parts, e.x, e.y, 8, 120, 40)
            Snd.play("saw", 150, 0.2, 0.3)
        end
    end
    if p.invuln > 0 then return end
    local ptx, pty = Phys.cell(p)
    local hit = nil
    if Game.flames[key(ptx, pty)] then hit = "dflame" end
    if not hit then
        for i = 1, #Game.enemies do
            local e = Game.enemies[i]
            if Util.dist2(e.x, e.y, p.x, p.y) < 121 then
                hit = "denemy"
                break
            end
        end
    end
    if hit then
        Harness.count(hit)
        Game.killPlayer()
    end
end

function Game.killPlayer()
    State.mode = "dying"
    Harness.count("deaths")
    Snd.boom(160, 4)
    Kit.shake(0.4)
    Kit.burst(Game.parts, Game.player.x, Game.player.y, 14, 140, 50)
    State.lives = State.lives - 1
    State.maxBombs, State.power, State.boots = 1, 2, 0
    Util.after(1.2, function()
        if State.lives <= 0 then
            State.mode = "over"
            Harness.count("gameovers")
        else
            local p = Game.player
            p.x, p.y = Map.cx(2), Map.cy(2)
            p.invuln = 2.5
            State.mode = "play"
        end
    end)
end

function Game.levelClear()
    State.mode = "clear"
    Harness.count("clears")
    State.score = State.score + 500
    Snd.play("tri", 523, 0.1, 0.3)
    Util.after(0.15, function() Snd.play("tri", 659, 0.1, 0.3) end)
    Util.after(0.3, function() Snd.play("tri", 784, 0.2, 0.3) end)
    Util.after(1.5, function()
        State.level = State.level + 1
        if State.level > Config.LEVELS then
            State.mode = "win"
            Harness.count("wins")
        else
            Game.startLevel()
        end
    end)
end

-- blast coverage of an explicit bomb list (no flames)
function Game.dangerCellsOf(bombs)
    local dang = {}
    for j = 1, #bombs do
        local b = bombs[j]
        dang[key(b.tx, b.ty)] = true
        for d = 1, 4 do
            for i = 1, b.power do
                local tx, ty = b.tx + DIRS[d][1] * i, b.ty + DIRS[d][2] * i
                local ch = Map.get(tx, ty)
                if ch == nil or ch == "#" or ch == "%" then break end
                dang[key(tx, ty)] = true
                if ch == "x" then break end
            end
        end
    end
    return dang
end

-- every cell a live bomb or flame will cover; extra = hypothetical bomb
function Game.dangerCells(extra)
    local dang = {}
    for k in pairs(Game.flames) do dang[k] = true end
    local function blast(b)
        dang[key(b.tx, b.ty)] = true
        for d = 1, 4 do
            for i = 1, b.power do
                local tx, ty = b.tx + DIRS[d][1] * i, b.ty + DIRS[d][2] * i
                local ch = Map.get(tx, ty)
                if ch == nil or ch == "#" or ch == "%" then break end
                dang[key(tx, ty)] = true
                if ch == "x" then break end
            end
        end
    end
    for i = 1, #Game.bombs do blast(Game.bombs[i]) end
    if extra then
        extra.power = extra.power or State.power
        blast(extra)
    end
    return dang
end

-- would dropping here leave a reachable safe cell within the fuse time?
function Game.wouldBeSafe(btx, bty, fuse)
    local dang = Game.dangerCells({ tx = btx, ty = bty })
    local ptx, pty = Phys.cell(Game.player)
    local isOpen = function(tx, ty)
        if Map.solid(tx, ty) then return false end
        local b = Game.bombAt(tx, ty)
        if b and not b.walkable then return false end
        if tx == btx and ty == bty and not (tx == ptx and ty == pty) then return false end
        return true
    end
    local dist = Phys.bfs(ptx, pty, isOpen)
    local speed = Config.BASE_SPEED + State.boots * Config.BOOT_SPEED
    local reach = math.floor(fuse * speed / Tiles.SIZE)
    for ty = 1, Map.H do
        for tx = 1, Map.W do
            local d = dist[ty][tx]
            if d and d <= reach and not dang[key(tx, ty)] then return true end
        end
    end
    return false
end

-- Autopilot: drives the same Input.state a human does. Normal mode plays
-- to win — bomb crates/enemies only when a safe cell is reachable, flee
-- danger, progress-based stuck detection (movement-based fails for
-- walkers). After the first win it goes reckless to exercise the death
-- and game-over paths.
local apFrame, apStuck, apLastProgress, apWander = 0, 0, -1, 0
local apDir = { 1, 0 }

local function apSteerTo(s, nx, ny)
    local p = Game.player
    local dx, dy = Map.cx(nx) - p.x, Map.cy(ny) - p.y
    if math.abs(dx) >= math.abs(dy) and dx ~= 0 then
        s.mx = Util.sign(dx)
    else
        s.my = Util.sign(dy)
    end
end

function Game.autopilot(s)
    s.mx, s.my, s.bomb, s.confirm, s.fuse = 0, 0, false, false, 2
    apFrame = apFrame + 1
    if State.mode ~= "play" then
        s.confirm = apFrame % 30 == 0
        return
    end
    s.fuse = Config.FUSE_MIN -- fast cycles beat long burns for the bot
    local p = Game.player
    local ptx, pty = Phys.cell(p)
    local bombDang = Game.dangerCells()
    -- enemies and their neighbor cells are no-go zones too
    local dang = {}
    for k in pairs(bombDang) do dang[k] = true end
    for j = 1, #Game.enemies do
        local e = Game.enemies[j]
        local etx, ety = Map.tileAt(e.x, e.y)
        dang[key(etx, ety)] = true
        dang[key(etx + 1, ety)] = true
        dang[key(etx - 1, ety)] = true
        dang[key(etx, ety + 1)] = true
        dang[key(etx, ety - 1)] = true
    end
    local isOpen = function(tx, ty)
        if Map.solid(tx, ty) then return false end
        local b = Game.bombAt(tx, ty)
        if b and not b.walkable then return false end
        return true
    end

    -- reckless after the first win: drop and stand on the bomb
    if (Harness.counters.wins or 0) >= 1 then
        if #Game.bombs < State.maxBombs then s.bomb = true end
        return
    end

    -- flee danger first, through danger if that's the only way out; if
    -- it's only an enemy closing in (no bomb burning here), drop one
    -- behind us on the way out — the classic drop-and-run
    if dang[key(ptx, pty)] then
        Harness.count("fFlee")
        if not bombDang[key(ptx, pty)] and #Game.bombs < State.maxBombs
            and not Game.bombAt(ptx, pty) and Game.wouldBeSafe(ptx, pty, s.fuse) then
            s.bomb = true
        end
        local dist = Phys.bfs(ptx, pty, isOpen)
        local best, bx, by = 9999, nil, nil
        for ty = 1, Map.H do
            for tx = 1, Map.W do
                local d = dist[ty][tx]
                if d and d < best and not dang[key(tx, ty)] then
                    best, bx, by = d, tx, ty
                end
            end
        end
        if bx then
            local nx, ny = Phys.firstStep(dist, bx, by)
            if nx then apSteerTo(s, nx, ny) else Harness.count("fNoStep") end
        else
            Harness.count("fNoSafe")
        end
        return
    end

    -- progress-based stuck detection -> wander burst
    local progress = (Harness.counters.crates or 0) + (Harness.counters.kills or 0)
    if progress ~= apLastProgress then
        apLastProgress, apStuck = progress, 0
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
    if apStuck > 240 then
        apStuck, apWander = 0, 45
        return
    end

    -- bomb when a crate or an enemy sits in the blast line and escape exists
    local wantBomb = false
    for d = 1, 4 do
        for i = 1, State.power do
            local tx, ty = ptx + DIRS[d][1] * i, pty + DIRS[d][2] * i
            local ch = Map.get(tx, ty)
            if ch == nil or ch == "#" or ch == "%" then break end
            if ch == "x" then
                wantBomb = true
                break
            end
            for j = 1, #Game.enemies do
                local e = Game.enemies[j]
                local etx, ety = Map.tileAt(e.x, e.y)
                if etx == tx and ety == ty then wantBomb = true end
            end
            if wantBomb then break end
        end
        if wantBomb then break end
    end
    if wantBomb and #Game.bombs < State.maxBombs and not Game.bombAt(ptx, pty)
        and Game.wouldBeSafe(ptx, pty, s.fuse) then
        s.bomb = true
        return
    end

    -- otherwise head for the nearest useful safe cell: a powerup, a spot
    -- next to a crate, or near an enemy
    local dist = Phys.bfs(ptx, pty, isOpen)
    local best, bx, by = 9999, nil, nil
    for ty = 1, Map.H do
        for tx = 1, Map.W do
            local d = dist[ty][tx]
            if d and d > 0 and d < best and not dang[key(tx, ty)] then
                local good = Game.powerAt(tx, ty) ~= nil
                if not good then
                    for i = 1, 4 do
                        if Map.get(tx + DIRS[i][1], ty + DIRS[i][2]) == "x" then
                            good = true
                            break
                        end
                    end
                end
                if not good then
                    for j = 1, #Game.enemies do
                        local e = Game.enemies[j]
                        local etx, ety = Map.tileAt(e.x, e.y)
                        if math.abs(etx - tx) + math.abs(ety - ty) <= 2 then
                            good = true
                            break
                        end
                    end
                end
                if good then best, bx, by = d, tx, ty end
            end
        end
    end
    if bx then
        local nx, ny = Phys.firstStep(dist, bx, by)
        if nx and not dang[key(nx, ny)] then apSteerTo(s, nx, ny) end
    end
end

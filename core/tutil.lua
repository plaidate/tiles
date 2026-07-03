-- Tiles core: clamp/sign/distance helpers and the delayed-call scheduler.

Util = {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

-- NB: Util.sign(0) == 0, which never matches a +/-1 facing check.
function Util.sign(v)
    if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

function Util.dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

function Util.choose(list)
    return list[math.random(#list)]
end

local pending = {}

function Util.after(delay, fn)
    pending[#pending + 1] = { t = delay, fn = fn }
end

function Util.clearPending()
    pending = {}
end

function Util.runPending(dt)
    -- alias so a callback calling clearPending can't nil out mid-iteration
    local list = pending
    for i = #list, 1, -1 do
        local p = list[i]
        p.t = p.t - dt
        if p.t <= 0 then
            table.remove(list, i)
            p.fn()
        end
    end
end

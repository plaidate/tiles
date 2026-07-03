-- Blast: tileset and arena generation. Classic single-screen layout:
-- hard border, pillar lattice on odd/odd cells, random crates, player
-- corner kept clear. 25x14 tiles under a 16px HUD row.

Arena = {}

local function k(tx, ty) return ty * 64 + tx end

-- floor: light field with an etched dot per tile (subtle grid)
Tiles.def(".", {
    kind = "floor",
    pat = Tiles.PAT.LIGHT,
    art = { "#" },
})

-- border wall: dark bevel, white top edge
local wallArt = { "oooooooooooooooo" }
for i = 2, 15 do wallArt[i] = "o..............#" end
wallArt[16] = "################"
Tiles.def("#", {
    solid = true,
    kind = "wall",
    pat = Tiles.PAT.DARK,
    art = wallArt,
})

-- pillar: mid-gray block with a white cap (landmarks get white caps)
local pillarArt = { ".##############.", "#oooooooooooooo#", "#oooooooooooooo#" }
for i = 4, 15 do pillarArt[i] = "#..............#" end
pillarArt[16] = ".##############."
Tiles.def("%", {
    solid = true,
    kind = "pillar",
    pat = Tiles.PAT.DARK,
    art = pillarArt,
})

-- crate: bordered box with an X brace
Tiles.def("x", {
    solid = true,
    kind = "crate",
    pat = Tiles.PAT.MID,
    art = {
        "################",
        "#..............#",
        "#.#..........#.#",
        "#..#........#..#",
        "#...#......#...#",
        "#....#....#....#",
        "#.....#..#.....#",
        "#......##......#",
        "#......##......#",
        "#.....#..#.....#",
        "#....#....#....#",
        "#...#......#...#",
        "#..#........#..#",
        "#.#..........#.#",
        "#..............#",
        "################",
    },
})

function Arena.generate(level)
    local rows = {}
    for y = 1, 14 do
        local row = {}
        for x = 1, 25 do
            local ch = "."
            if x == 1 or x == 25 or y == 1 or y == 14 then
                ch = "#"
            elseif x % 2 == 1 and y % 2 == 1 then
                ch = "%"
            end
            row[x] = ch
        end
        rows[y] = table.concat(row)
    end
    Map.load(rows, 0, 16)

    -- crates everywhere except the player's corner pocket
    local prot = { [k(2, 2)] = true, [k(3, 2)] = true, [k(2, 3)] = true, [k(4, 2)] = true, [k(2, 4)] = true }
    Map.each(function(x, y, ch)
        if ch == "." and not prot[k(x, y)] and math.random() < Config.CRATES then
            Map.set(x, y, "x")
        end
    end)
end

-- spawn this level's enemies on open floor, away from the player corner
function Arena.spawnEnemies(level)
    local plan = Config.WAVES[math.min(level, #Config.WAVES)]
    local floors = {}
    Map.each(function(x, y, ch)
        if ch == "." and (math.abs(x - 2) + math.abs(y - 2)) >= 10 then
            floors[#floors + 1] = { x, y }
        end
    end)
    local list = {}
    local function add(kind, speed)
        if #floors == 0 then return end
        local c = table.remove(floors, math.random(#floors))
        list[#list + 1] = { x = Map.cx(c[1]), y = Map.cy(c[2]), kind = kind, speed = speed }
    end
    for _ = 1, plan.puffs do add("puff", 30 + level * 2) end
    for _ = 1, plan.hounds do add("hound", 38 + level * 2) end
    return list
end

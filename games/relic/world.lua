-- Relic: the world — tileset, rooms-as-data, and the room loader.
--
-- Rooms are 23x12 INTERIOR strings; the loader adds the border wall with
-- standardized exit gaps (horizontal exits at rows 7-8, vertical exits at
-- columns 12-13) so adjacent rooms always line up. A door on an exit
-- ('doorN' etc.) puts locked 'D' tiles in the gap instead.

World = {}

-- grass with an etched dot
Tiles.def(".", { kind = "floor", pat = Tiles.PAT.LIGHT, art = { "#" } })

-- rock/dungeon wall: dark bevel, white top edge
local wallArt = { "oooooooooooooooo" }
for i = 2, 15 do wallArt[i] = "o..............#" end
wallArt[16] = "################"
Tiles.def("#", { solid = true, kind = "wall", pat = Tiles.PAT.DARK, art = wallArt })

-- tree: dark canopy with a white crown cap
Tiles.def("t", {
    solid = true,
    kind = "tree",
    pat = Tiles.PAT.LIGHT,
    art = {
        "....oo####......",
        "..oo########....",
        ".o###########o..",
        ".o#############.",
        "#o##############",
        "#o##############",
        "#################",
        ".##############.",
        ".############...",
        "..##########....",
        "...###..###.....",
        ".....#..#.......",
        ".....#..#.......",
        "....######......",
        "...########.....",
        "................",
    },
})

-- water: blocks walking, boomerang flies over
Tiles.def("~", {
    solid = true,
    shootthru = true,
    kind = "water",
    pat = Tiles.PAT.MID,
    art = {
        "................",
        "..oooo..........",
        ".o....o.........",
        "................",
        "..........oooo..",
        ".........o....o.",
        "................",
        "................",
        "...oooo.........",
        "..o....o........",
        "................",
        "..............o.",
        ".........oooo...",
        "........o....o..",
        "................",
        "................",
    },
})

-- locked door: opens with a key (adjacent 'D' tiles open together)
Tiles.def("D", {
    solid = true,
    kind = "door",
    pat = Tiles.PAT.DARK,
    art = {
        "################",
        "#oooooooooooooo#",
        "#o............o#",
        "#o............o#",
        "#o...######...o#",
        "#o..##oooo##..o#",
        "#o..#oo##oo#..o#",
        "#o..#o####o#..o#",
        "#o..#oo##oo#..o#",
        "#o..##oooo##..o#",
        "#o...######...o#",
        "#o............o#",
        "#o............o#",
        "#oooooooooooooo#",
        "################",
        "################",
    },
})

-- dungeon mouth / stairs: step on it to warp
Tiles.def("d", {
    kind = "warp",
    pat = Tiles.PAT.BLACK,
    art = {
        "oooooooooooooooo",
        "o##############o",
        "o#oooooooooooo#o",
        "o#o##########o#o",
        "o#o#oooooooo#o#o",
        "o#o#o######o#o#o",
        "o#o#o#....#o#o#o",
        "o#o#o#....#o#o#o",
        "o#o#o######o#o#o",
        "o#o#oooooooo#o#o",
        "o#o##########o#o",
        "o#oooooooooooo#o",
        "o##############o",
        "oooooooooooooooo",
        "oooooooooooooooo",
        "oooooooooooooooo",
    },
})

-- 23-char interior template pieces
local E = "......................." -- empty row

-- ROOMS: interior (12 rows x 23 chars), exits, doors on exits, spawns.
-- Overworld is a 3x2 grid (oX_Y, Y=1 north); the dungeon is d1..d4.
World.ROOMS = {
    o1_2 = {
        exits = { n = "o1_1", e = "o2_2" },
        interior = {
            "......t.......t........",
            E,
            "..t....................",
            "............t..........",
            E,
            E,
            ".......t...............",
            E,
            "...................t...",
            "..t....................",
            E,
            E,
        },
        enemies = { { "blob", 15, 5 }, { "blob", 8, 10 } },
    },
    o2_2 = {
        exits = { w = "o1_2", e = "o3_2" },
        interior = {
            E,
            "....~~~~.....~~~~......",
            "....~~~~.....~~~~......",
            E,
            "..........~~...........",
            "..........~~...........",
            E,
            "....~~~~.....~~~~......",
            "....~~~~.....~~~~......",
            E,
            E,
            E,
        },
        enemies = { { "blob", 7, 12 }, { "blob", 19, 11 }, { "blob", 5, 12 } },
        pickups = { { "key", 19, 6 } },
    },
    o3_2 = {
        exits = { w = "o2_2", n = "o3_1" },
        interior = {
            "......t......t.........",
            E,
            "..t......t.........t...",
            E,
            "......t.......t........",
            "..t.................t..",
            E,
            "........t....t.........",
            E,
            "..t........t.......t...",
            E,
            E,
        },
        enemies = { { "skel", 16, 7 }, { "skel", 8, 9 } },
        pickups = { { "boom", 19, 10 } },
    },
    o1_1 = {
        exits = { s = "o1_2", e = "o2_1" },
        interior = {
            E,
            "...####.......####.....",
            "...#..............#....",
            E,
            "..........##...........",
            "..........##...........",
            E,
            "...#..............#....",
            "...####.......####.....",
            E,
            E,
            E,
        },
        enemies = { { "blob", 18, 4 }, { "blob", 7, 12 } },
        pickups = { { "heart", 12, 8 } },
    },
    o2_1 = {
        exits = { w = "o1_1", e = "o3_1" },
        interior = {
            E,
            "....t.........t........",
            E,
            "........t.........t....",
            E,
            "..t....................",
            E,
            ".......t......t........",
            E,
            "....t..............t...",
            E,
            E,
        },
        enemies = { { "skel", 11, 5 }, { "skel", 17, 9 }, { "skel", 7, 11 } },
    },
    o3_1 = {
        exits = { w = "o2_1", s = "o3_2" },
        interior = {
            "........#######........",
            "........#..d..#........",
            "........#.....#........",
            "........###D###........",
            E,
            "....t.............t....",
            E,
            E,
            "......t.......t........",
            E,
            E,
            E,
        },
        enemies = { { "skel", 6, 8 } },
        warps = { { tx = 13, ty = 3, to = "d1", px = 13, py = 11 } },
    },
    d1 = {
        exits = { n = "d2" },
        interior = {
            E,
            "...##.......#.....##...",
            "...#................#..",
            E,
            "......###....###.......",
            E,
            E,
            "...#................#..",
            "...##..............##..",
            E,
            "...........d...........",
            E,
        },
        enemies = { { "shooter", 6, 6 }, { "shooter", 20, 6 } },
        warps = { { tx = 13, ty = 12, to = "o3_1", px = 13, py = 6 } },
    },
    d2 = {
        exits = { s = "d1", n = "d3" },
        interior = {
            E,
            "....######..######.....",
            E,
            "..#..................#.",
            E,
            "........##..##.........",
            "........##..##.........",
            E,
            "..#..................#.",
            E,
            "....######..######.....",
            E,
        },
        enemies = { { "skel", 7, 5 }, { "skel", 18, 9 }, { "shooter", 13, 7 } },
        pickups = { { "key", 4, 11 } },
    },
    d3 = {
        exits = { s = "d2", n = "d4" },
        doorN = true,
        interior = {
            E,
            "...#####.......#####...",
            E,
            E,
            ".....##....#....##.....",
            E,
            E,
            "...........#...........",
            "...#####.......#####...",
            E,
            E,
            E,
        },
        enemies = { { "shooter", 7, 7 }, { "shooter", 19, 7 }, { "skel", 13, 10 } },
    },
    d4 = {
        exits = { s = "d3" },
        interior = {
            E,
            "....##............##...",
            E,
            E,
            E,
            E,
            E,
            E,
            E,
            E,
            "....##............##...",
            E,
        },
        boss = { tx = 13, ty = 6 },
    },
}

-- build full 25x14 rows for a room: border + gaps/doors + interior
local function buildRows(room)
    local rows = {}
    local ex = room.exits or {}
    local top, bottom = {}, {}
    for x = 1, 25 do
        top[x], bottom[x] = "#", "#"
        if x == 12 or x == 13 then
            if ex.n then top[x] = room.doorN and "D" or "." end
            if ex.s then bottom[x] = room.doorS and "D" or "." end
        end
    end
    rows[1] = table.concat(top)
    for y = 2, 13 do
        local interior = room.interior[y - 1]
        assert(#interior == 23, "room interior row " .. (y - 1) .. " must be 23 chars")
        local w, e = "#", "#"
        if (y == 8 or y == 9) and ex.w then w = room.doorW and "D" or "." end
        if (y == 8 or y == 9) and ex.e then e = room.doorE and "D" or "." end
        rows[y] = w .. interior .. e
    end
    rows[14] = table.concat(bottom)
    return rows
end

-- load a room into the Map, honoring opened doors
function World.enter(key)
    local room = World.ROOMS[key]
    assert(room, "no room " .. tostring(key))
    local rows = buildRows(room)
    Map.load(rows, 0, 16)
    for cell in pairs(State.doors) do
        local r, tx, ty = cell:match("^([%w_]+):(%d+),(%d+)$")
        if r == key then
            Map.set(tonumber(tx), tonumber(ty), ".")
        end
    end
    Map.build()
    return room
end

-- validate every room at import time so typos die in smoke, not on device
for key, room in pairs(World.ROOMS) do
    assert(#room.interior == 12, key .. " needs 12 interior rows")
    local rows = buildRows(room)
    for _, exit in pairs(room.exits or {}) do
        assert(World.ROOMS[exit], key .. " exits to missing room " .. exit)
    end
    assert(#rows == 14)
end

-- Burrow: tileset and cave generation. Underground palette: black
-- tunnels, dark speckled dirt, mid steel walls, light rocks and gems so
-- the hazards pop.

Mine = {}

-- open tunnel: black
Tiles.def(".", { kind = "tunnel", pat = Tiles.PAT.BLACK })

-- dirt: dark soil with speckles; the player digs through it
Tiles.def("d", {
    kind = "dirt",
    pat = Tiles.PAT.DARK,
    art = {
        "..o......o......",
        "......o.......o.",
        "...o......o.....",
        "o.....o.....o...",
        ".....o....o.....",
        ".o.....o......o.",
        "....o.....o.....",
        "..o....o.....o..",
    },
})

-- steel border: mid bevel, indestructible
local wallArt = { "oooooooooooooooo" }
for i = 2, 15 do wallArt[i] = "o..............#" end
wallArt[16] = "################"
Tiles.def("#", { solid = true, kind = "steel", pat = Tiles.PAT.MID, art = wallArt })

-- rock: dithered boulder, falls and rolls
Tiles.def("O", {
    solid = true,
    kind = "rock",
    round = true,
    pat = Tiles.PAT.BLACK,
    art = {
        "................",
        "....oooooooo....",
        "...o#o#o#o#oo...",
        "..oo#o#o#o#o#o..",
        ".oo#o#o#o#o#o#o.",
        ".o#o#o#o#o#o#oo.",
        ".oo#o#o#o#o#o#o.",
        ".o#o#o#o#o#o#oo.",
        ".oo#o#o#o#o#o#o.",
        ".o#o#o#o#o#o#oo.",
        "..o#o#o#o#o#oo..",
        "...oo#o#o#oo....",
        "....oooooooo....",
        "................",
    },
})

-- gem: white diamond, collect to open the exit (falls like a rock)
Tiles.def("*", {
    kind = "gem",
    round = true,
    pat = Tiles.PAT.BLACK,
    art = {
        "................",
        ".......oo.......",
        "......oooo......",
        ".....oo##oo.....",
        "....oo####oo....",
        "...oo##oo##oo...",
        "..oo########oo..",
        "...oo######oo...",
        "....oo####oo....",
        ".....oo##oo.....",
        "......oooo......",
        ".......oo.......",
        "................",
    },
})

-- exit door, closed until enough gems are banked
Tiles.def("X", {
    solid = true,
    kind = "exit",
    pat = Tiles.PAT.DARK,
    art = {
        "################",
        "#o............o#",
        "#.####....####.#",
        "#.#..........#.#",
        "#.#..........#.#",
        "#.#...####...#.#",
        "#.#...#oo#...#.#",
        "#.#...#oo#...#.#",
        "#.#...####...#.#",
        "#.#..........#.#",
        "#.#..........#.#",
        "#.####....####.#",
        "#o............o#",
        "################",
        "################",
        "################",
    },
})

-- exit door, open: bright doorway
Tiles.def("E", {
    kind = "exitopen",
    pat = Tiles.PAT.BLACK,
    art = {
        "################",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "#oo##########oo#",
        "#oo##########oo#",
        "#oo##oooooo##oo#",
        "#oo##oooooo##oo#",
        "#oo##oooooo##oo#",
        "#oo##oooooo##oo#",
        "#oo##########oo#",
        "#oo##########oo#",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "################",
        "################",
        "################",
    },
})

function Mine.need(level)
    return Config.NEED_BASE + level * Config.NEED_PER
end

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

function Mine.generate(level)
    local W, H = Config.MAP_W, Config.MAP_H
    local g = {}
    for y = 1, H do
        g[y] = {}
        for x = 1, W do
            g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "d"
        end
    end
    -- cave pockets: short random walks
    for _ = 1, 10 do
        local x, y = math.random(3, W - 2), math.random(3, H - 2)
        for _ = 1, 35 do
            g[y][x] = "."
            local d = Util.choose(DIRS)
            x = Util.clamp(x + d[1], 2, W - 1)
            y = Util.clamp(y + d[2], 2, H - 1)
        end
    end
    -- rocks, keeping the start pocket clear
    for y = 2, H - 1 do
        for x = 2, W - 1 do
            if not (x <= 6 and y <= 6) and math.random() < Config.ROCKS then
                g[y][x] = "O"
            end
        end
    end
    -- gems: never directly under a rock at gen time
    local placed, tries = 0, 0
    local total = Mine.need(level) + Config.GEM_SPARE
    while placed < total and tries < 4000 do
        tries = tries + 1
        local x, y = math.random(2, W - 1), math.random(3, H - 1)
        local ch = g[y][x]
        if (ch == "d" or ch == ".") and g[y - 1][x] ~= "O" and not (x <= 6 and y <= 6) then
            g[y][x] = "*"
            placed = placed + 1
        end
    end
    -- start pocket and exit
    g[2][2], g[2][3], g[3][2] = ".", ".", "."
    g[H - 1][W - 1] = "X"
    local rows = {}
    for y = 1, H do rows[y] = table.concat(g[y]) end
    Map.load(rows, 0, 16)
end

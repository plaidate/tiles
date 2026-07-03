-- Spirit: the shrine courtyard — a fixed symmetric arena. Lanterns are
-- solid cover; ponds block walking but talismans fly over them.

Arena = {}

-- stone floor with an etched dot
Tiles.def(".", {
    kind = "floor",
    pat = Tiles.PAT.LIGHT,
    art = { "#" },
})

-- perimeter wall: dark bevel, white top edge
local wallArt = { "oooooooooooooooo" }
for i = 2, 15 do wallArt[i] = "o..............#" end
wallArt[16] = "################"
Tiles.def("#", {
    solid = true,
    kind = "wall",
    pat = Tiles.PAT.DARK,
    art = wallArt,
})

-- stone lantern: dark pedestal, white light box (white-capped landmark)
Tiles.def("L", {
    solid = true,
    kind = "lantern",
    pat = Tiles.PAT.LIGHT,
    art = {
        "......####......",
        ".....#oooo#.....",
        "....#oo##oo#....",
        "....#oo##oo#....",
        ".....#oooo#.....",
        "....########....",
        "......####......",
        "......#..#......",
        "......#..#......",
        ".....######.....",
        "....########....",
        "...##########...",
        "..############..",
        "..############..",
        ".##############.",
        "################",
    },
})

-- pond: walk-blocking, shoot-through water
Tiles.def("~", {
    solid = true,
    shootthru = true,
    kind = "pond",
    pat = Tiles.PAT.MID,
    art = {
        ".##############.",
        "#..............#",
        "#....oooo......#",
        "#...o....o.....#",
        "#..............#",
        "#.......oooo...#",
        "#......o....o..#",
        "#..............#",
        "#..oooo........#",
        "#.o....o.......#",
        "#..............#",
        "#......oooo....#",
        "#.....o....o...#",
        "#..............#",
        "#..............#",
        ".##############.",
    },
})

local ROWS = {
    "#########################",
    "#.......................#",
    "#..L.....L.....L.....L..#",
    "#.......................#",
    "#....~~.........~~......#",
    "#....~~.........~~......#",
    "#.......................#",
    "#..L.......L.........L..#",
    "#.......................#",
    "#......~~.........~~....#",
    "#......~~.........~~....#",
    "#.......................#",
    "#..L.....L.....L.....L..#",
    "#########################",
}

function Arena.build()
    Map.load(ROWS, 0, 16)
    Map.build()
end

-- a random open cell hugging one of the four edges (enemy entry points)
function Arena.spawnCell()
    for _ = 1, 60 do
        local side = math.random(4)
        local tx, ty
        if side == 1 then tx, ty = math.random(2, 24), 2
        elseif side == 2 then tx, ty = math.random(2, 24), 13
        elseif side == 3 then tx, ty = 2, math.random(2, 13)
        else tx, ty = 24, math.random(2, 13) end
        if not Map.solid(tx, ty) then return tx, ty end
    end
    return 12, 2
end

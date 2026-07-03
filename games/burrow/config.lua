-- Burrow: tunables. Smoke builds shorten the campaign.

Config = {
    DT = 1 / 30,

    LEVELS = SMOKE_BUILD and 2 or 3,
    LIVES = 3,
    TIME = 200,        -- seconds per cave

    MAP_W = 40,        -- 640x448 world -> scrolls on both axes
    MAP_H = 28,

    STEP_SPEED = 90,   -- px/s cell-to-cell tween
    TICK = 0.12,       -- rock/gem automaton cadence
    ROCKS = 0.12,      -- rock density over the fill
    NEED_BASE = 10,    -- gems required = NEED_BASE + level * NEED_PER
    NEED_PER = 2,
    GEM_SPARE = 4,     -- extra gems beyond the requirement
}

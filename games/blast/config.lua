-- Blast: tunables. Smoke builds shorten the campaign so the autopilot
-- can reach both endings quickly.

Config = {
    DT = 1 / 30,

    LEVELS = SMOKE_BUILD and 2 or 5,
    LIVES = 3,

    -- crank dial range for the bomb fuse, seconds
    FUSE_MIN = 1.2,
    FUSE_MAX = 3.6,

    FLAME_T = 0.45,     -- how long a flame cell burns
    BASE_SPEED = 55,    -- player px/s; boots add 18 each
    BOOT_SPEED = 18,
    DROP_CHANCE = 0.3,  -- powerup chance per crate
    CRATES = 0.32,      -- crate density over open floor

    -- per-level enemy mix (repeats last entry past the end)
    WAVES = {
        { puffs = 3, hounds = 0 },
        { puffs = 4, hounds = 1 },
        { puffs = 3, hounds = 2 },
        { puffs = 4, hounds = 3 },
        { puffs = 3, hounds = 4 },
    },
}

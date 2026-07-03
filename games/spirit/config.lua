-- Spirit: tunables. Smoke builds shorten the campaign.

Config = {
    DT = 1 / 30,

    WAVES = SMOKE_BUILD and 3 or 8,
    HEARTS = 3,

    PLAYER_SPEED = 72,   -- px/s, 8-way
    SHOT_SPEED = 200,    -- talisman px/s
    SHOT_CD = 0.22,      -- seconds between shots while held
    IFRAMES = 1.5,

    SWEEP_CHARGE = 300,  -- crank degrees to bank a wand sweep
    SWEEP_R = 32,        -- kill radius
    SWEEP_BULLET_R = 40, -- bullet-clear radius
    SWEEP_CD = 0.8,

    SPAWN_T = 0.9,       -- seconds between spawns within a wave

    -- wave compositions (index clamps at the end)
    MIX = {
        { ghosts = 4, spitters = 0, dashers = 0 },
        { ghosts = 4, spitters = 1, dashers = 0 },
        { ghosts = 4, spitters = 1, dashers = 2 },
        { ghosts = 5, spitters = 2, dashers = 2 },
        { ghosts = 6, spitters = 2, dashers = 3 },
        { ghosts = 6, spitters = 3, dashers = 3 },
        { ghosts = 7, spitters = 3, dashers = 4 },
        { ghosts = 8, spitters = 4, dashers = 4 },
    },
}

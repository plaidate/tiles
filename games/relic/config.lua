-- Relic: tunables. Smoke builds soften the boss.

Config = {
    DT = 1 / 30,

    HEARTS = 3,
    MAX_HEARTS = 5,
    SPEED = 70,        -- player px/s

    SWORD_CD = 0.35,
    SWORD_T = 0.18,    -- stab active window
    SWORD_R = 13,      -- stab reach from the blade point

    SPIN_CHARGE = 330, -- crank degrees to release a spin attack
    SPIN_R = 28,
    SPIN_CD = 0.6,

    IFRAMES = 1.2,
    KNOCKBACK = 18,

    BOOM_SPEED = 150,  -- boomerang px/s
    BOOM_RANGE = 0.5,  -- seconds outbound

    BOSS_HP = SMOKE_BUILD and 6 or 12,
}

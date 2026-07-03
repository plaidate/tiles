-- Blast: input. D-pad moves, A drops a bomb, the crank is a fuse dial —
-- crank up for a hair-trigger, down for a long burn.

Input = {
    state = { mx = 0, my = 0, bomb = false, confirm = false, fuse = 2 },
}

function Input.poll()
    local s = Input.state
    if Harness.enabled then
        Game.autopilot(s)
        return
    end
    local pd = playdate
    s.mx, s.my = 0, 0
    if pd.buttonIsPressed(pd.kButtonLeft) then s.mx = -1 end
    if pd.buttonIsPressed(pd.kButtonRight) then s.mx = 1 end
    if pd.buttonIsPressed(pd.kButtonUp) then s.my = -1 end
    if pd.buttonIsPressed(pd.kButtonDown) then s.my = 1 end
    s.bomb = pd.buttonJustPressed(pd.kButtonA)
    s.confirm = pd.buttonJustPressed(pd.kButtonA)
    -- fold the dial so 0 deg (up) = shortest, 180 deg (down) = longest
    local pos = pd.getCrankPosition()
    if pos > 180 then pos = 360 - pos end
    s.fuse = Config.FUSE_MIN + (pos / 180) * (Config.FUSE_MAX - Config.FUSE_MIN)
end

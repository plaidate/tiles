-- Spirit: input. D-pad moves 8-way, A throws talismans the way you move,
-- spinning the crank banks a wand sweep that clears everything nearby.

Input = {
    state = { mx = 0, my = 0, fire = false, sweep = false, confirm = false },
    charge = 0, -- crank degrees toward the next sweep
}

function Input.poll()
    local s = Input.state
    if Harness.enabled then
        Game.autopilot(s)
        if s.sweep then Input.charge = 0 end
        return
    end
    local pd = playdate
    s.mx, s.my, s.sweep = 0, 0, false
    if pd.buttonIsPressed(pd.kButtonLeft) then s.mx = -1 end
    if pd.buttonIsPressed(pd.kButtonRight) then s.mx = 1 end
    if pd.buttonIsPressed(pd.kButtonUp) then s.my = -1 end
    if pd.buttonIsPressed(pd.kButtonDown) then s.my = 1 end
    s.fire = pd.buttonIsPressed(pd.kButtonA)
    s.confirm = pd.buttonJustPressed(pd.kButtonA)
    Input.charge = Input.charge + math.abs(pd.getCrankChange())
    if Input.charge >= Config.SWEEP_CHARGE then
        Input.charge = 0
        s.sweep = true
    end
end

-- Relic: input. D-pad moves, A stabs, B throws the boomerang, winding
-- the crank charges a spin attack that releases on a full wind.

Input = {
    state = {
        mx = 0, my = 0, attack = false, spin = false, item = false,
        confirm = false, alt = false,
    },
    charge = 0,
}

function Input.poll()
    local s = Input.state
    if Harness.enabled then
        Game.autopilot(s)
        if s.spin then Input.charge = 0 end
        return
    end
    local pd = playdate
    s.mx, s.my, s.spin = 0, 0, false
    if pd.buttonIsPressed(pd.kButtonLeft) then s.mx = -1 end
    if pd.buttonIsPressed(pd.kButtonRight) then s.mx = 1 end
    if pd.buttonIsPressed(pd.kButtonUp) then s.my = -1 end
    if pd.buttonIsPressed(pd.kButtonDown) then s.my = 1 end
    s.attack = pd.buttonJustPressed(pd.kButtonA)
    s.confirm = pd.buttonJustPressed(pd.kButtonA)
    s.item = pd.buttonJustPressed(pd.kButtonB)
    s.alt = pd.buttonJustPressed(pd.kButtonB)
    Input.charge = Input.charge + math.abs(pd.getCrankChange())
    if Input.charge >= Config.SPIN_CHARGE then
        Input.charge = 0
        s.spin = true
    end
end

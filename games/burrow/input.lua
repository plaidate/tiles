-- Burrow: input. D-pad digs cell by cell; the crank pans the camera up
-- and down the shaft (it springs back when released).

Input = {
    state = { mx = 0, my = 0, confirm = false, peek = 0 },
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
    s.confirm = pd.buttonJustPressed(pd.kButtonA)
    s.peek = pd.getCrankChange()
end

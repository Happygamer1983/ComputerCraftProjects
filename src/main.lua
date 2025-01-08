local Screen = peripheral.wrap("right")

if peripheral.getType("right") ~= "monitor" then
    print("Monitor is not attached at [ right ] side, cannot run program")
    return
elseif peripheral.getType("right") == "monitor" then
    print("Monitor detected, loading program")
end

local UIF = require("UIFunctions")
local ScreenX, ScreenY = Screen.getSize()

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local Counter = 0

while true do
    UIF.Clear(Screen)

    UIF.DrawText(Screen, 1,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    UIF.ProgressBar(Screen, 2,3, ScreenX-2, Counter, 100, colors.white, colors.gray)

    Counter = Counter + 1
    sleep(0.5)
end


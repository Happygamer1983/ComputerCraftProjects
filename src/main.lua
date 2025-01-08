local Screen = peripheral.wrap("right")

if peripheral.getType("right") ~= "monitor" then
    print("Monitor is not attached at [ right ] side, cannot run program")
    return
elseif peripheral.getType("right") == "monitor" then
    print("Monitor detected, loading program")
end

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black
local UIF = require("UIFunctions")
local Counter = 0

while true do
    UIF.Clear(Screen)

    UIF.DrawText(Screen, 1,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    UIF.ProgressBar(Screen, 1,3, 50, Counter, 100, colors.green, colors.gray)

    Counter = Counter + 1
    sleep(0.5)
end


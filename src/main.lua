local Screen = peripheral.wrap("right")

if peripheral.getType("right") ~= "monitor" then
    print("Monitor is not attached at [ right ] side, cannot run program")
    return
elseif peripheral.getType("right") == "monitor" then
    print("Monitor detected, loading program")
end

local UIF = require("lib/UIFunctions.lua")
UIF.Clear(Screen)

UIF.DrawText(Screen, 1,0, "Test Program", color.write, color.black)
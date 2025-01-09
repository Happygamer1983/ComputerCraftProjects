local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
assert(peripheral.getType("right") == "monitor", "No Monitor detected on the right side!")
-- More checks

print("Done!")

local UIF = require("UIFunctions")

local Screen = peripheral.wrap("right")
local ScreenX, ScreenY = Screen.getSize()

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local BarColor = colors.green
local BackBarColor = colors.gray

local Counter = 0

while true do
    UIF.Clear(Screen)
    Screen.setTextScale(1)

    UIF.DrawText(Screen, 2,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    if Counter < 100 then
        UIF.DrawText(Screen, 2,3, "Test Progress: "..Counter.."%", DefaultTextColor, DefaultBackgroundColor)
        UIF.ProgressBar(Screen, 2,4, ScreenX-2, Counter, 100, BarColor, BackBarColor)
    else
        UIF.DrawText(Screen, 2,3, "Test Done!", DefaultTextColor, DefaultBackgroundColor)
    end

    

    Counter = math.clamp(Counter, 0, 100)
    sleep(0.5)
end


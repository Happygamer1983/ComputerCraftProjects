local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version")
assert(peripheral.getType("right") == "monitor", "No Monitor detected on the right side!")
-- More checks

print("Done!")

local UIF = require("UIFunctions")

local Screen = peripheral.wrap("right")
local ScreenX, ScreenY = Screen.getSize()

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black


while true do
    UIF.Clear(Screen)
    Screen.setTextScale(1)

    UIF.DrawText(Screen, 1,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    UIF.DrawText(Screen, 1,3, "Test Progress: "..Counter.."%", DefaultTextColor, DefaultBackgroundColor)
    UIF.ProgressBar(Screen, 2,4, ScreenX-2, Counter, 100, colors.white, colors.gray)

    Counter = Counter + 1
    sleep(0.5)
end


local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
assert(peripheral.getType("right") == "monitor", "No Monitor!")
assert(peripheral.getType("left") == "info_panel_advanced", "No Reactor Info!")
-- More checks

print("Done!")

local UIF = require("UIFunctions")

local Screen = peripheral.wrap("right")
local ScreenX, ScreenY = Screen.getSize()

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local BarColor = colors.green
local BackBarColor = colors.gray

local GetReactorCardData = function(CardData)
    local sortedTables = {}
    local cardSize = 6 -- Number of entries per card

    for i = 1, #CardData, cardSize do
        local cardData = {}

        -- Check if the card contains "Out of Range"
        if cardTable[i] == "Out of Range" then
            table.insert(cardData, "Out of Range")
        else
            for j = 0, cardSize - 1 do
                local value = cardTable[i + j]
                table.insert(cardData, value)
            end
        end

        table.insert(sortedTables, cardData)
    end

    return sortedTables
end

while true do
    UIF.Clear(Screen)
    Screen.setTextScale(1)

    UIF.DrawText(Screen, 2,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    local Retruned, DataError = pcall(function()
        return peripheral.wrap("left").getCardData()
    end)

    if DataError then
        UIF.DrawText(Screen, 2,1, DataError, colors.red, DefaultBackgroundColor)
        break
    end

    

    Counter = math.max(0, math.min(Counter + 1, 100))
    sleep(0.5)
end


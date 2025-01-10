local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
assert(peripheral.getType("right") == "monitor", "No Monitor!")
assert(peripheral.getType("left") == "info_panel_advanced", "No Reactor Info!")
-- More checks

print("Done!")

local UIF = require("UIFunctions")

local Mon = {}
Mon.screen = peripheral.wrap("right")
Mon.X, Mon.Y = Mon.screen.getSize()

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local StatusColor
local TempColor
local RemainingColor

local BarColor = colors.green
local BackBarColor = colors.gray

local GetReactorCardData = function(CardData)
    local sortedTables = {}
    local cardSize = 6 -- Number of entries per card

    for i = 1, #CardData, cardSize do
        local cardData = {}

        -- Check if the card contains "Out of Range"
        if CardData[i] == "Out of Range" then
            table.insert(cardData, "Out of Range")
        else
            for j = 0, cardSize - 1 do
                local value = CardData[i + j]
                table.insert(cardData, value)
            end
        end

        table.insert(sortedTables, cardData)
    end

    return sortedTables
end

while true do
    UIF.Clear(Mon)
    Mon.screen.setTextScale(1)

    UIF.DrawText(Mon, 2,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    local Success, Retruned = pcall(function()
        return GetReactorCardData(peripheral.wrap("left").getCardData())
    end)

    if not Success then
        UIF.DrawText(Mon, 2,1, Retruned, colors.red, DefaultBackgroundColor)
        break
    end

    for i,v in pairs(Retruned) do
        if v[2] == "Off" then
            StatusColor = colors.red
        else
            StatusColor = colors.lime
        end

        UIF.DrawTextLeftRight(Mon, 2,1,1, "Reactor Status ["..i.."]", v[2], DefaultTextColor, StatusColor, DefaultBackgroundColor)
    end
    sleep(0.5)
end


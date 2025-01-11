local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
assert(peripheral.getType("right") == "monitor", "No Monitor!")
assert(peripheral.getType("left") == "info_panel_advanced", "No Reactor Info!")
-- More checks

print("Done!")

local Screen = peripheral.wrap("right")
local ScreenX, ScreenY = Screen.getSize()
local Mon = {}
Mon.screen, Mon.X, Mon.Y = Screen, ScreenX, ScreenY

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local StatusColor = colors.red
local TempColor = colors.green
local TempBarColor = colors.green
local RemainingColor = colors.green

local UIF = require("UIFunctions")

local ConvertNumber = function(str)
    local cleanedStr = string.gsub(str, "%s", "")
    local number = tonumber(cleanedStr)
    return number
end

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

local StartReactor = function(event, x, y)
    rs.setBundledOutput("back", colors.black)
end

local ShutdownReactor = function(event, x, y)
    rs.setBundledOutput("back", 0)
end

while true do
    UIF.Clear(Mon)
    Mon.screen.setTextScale(1)

    UIF.DrawText(Mon, 2,1, "Test Program", DefaultTextColor, DefaultBackgroundColor)

    local Success, Retruned = pcall(function()
        return GetReactorCardData(peripheral.wrap("left").getCardData())
    end)

    --[[
    CardInfo = {
    [1] = temp          (number)
    [2] = on/off        (string)
    [3] = max heat      (number)
    [4] = meltdown temp (number)
    [5] = EU/t output   (number)
    [6] = remaining     (string)
    }
    ]]

    if not Success then
        UIF.DrawText(Mon, 2,1, Retruned, colors.red, DefaultBackgroundColor)
        break
    end

    for i,v in pairs(Retruned) do
        if v[1] == "Out of Range" then
            UIF.DrawText(Mon, 2, 1, "Out of Range", colors.red, DefaultBackgroundColor)
            return
        elseif ConvertNumber(v[1]) >= 7500 then
            TempColor = colors.red
            TempBarColor = colors.red
        elseif ConvertNumber(v[1]) >= 6500 then
            TempColor = colors.orange
            TempBarColor = colors.orange
        elseif ConvertNumber(v[1]) >= 4000 then
            TempColor = colors.yellow
        elseif ConvertNumber(v[1]) >= 2000 then
            TempColor = colors.lime
        else
            TempColor = colors.green
            TempBarColor = colors.green
        end

        if v[2] == "Off" then
            StatusColor = colors.red
        else
            StatusColor = colors.lime
        end

        UIF.DrawTextLeftRight(Mon, 2, 1, 1, "Reactor Status ["..i.."]", v[2], DefaultTextColor, StatusColor, DefaultBackgroundColor)

        UIF.DrawTextLeftRight(Mon, 2, 3, 1, "Reactor Temperature:", v[1].." °C", DefaultTextColor, TempColor, DefaultBackgroundColor)
        UIF.ProgressBar(Mon, 2, 4, Mon.X - 2, ConvertNumber(v[1]), ConvertNumber(v[3]), TempBarColor, colors.gray)

        UIF.DrawTextLeftRight(Mon, 2, 6, 1, "Reactor Output:", v[5].." / EU/t", DefaultTextColor, colors.white, DefaultBackgroundColor)
        UIF.ProgressBar(Mon, 2, 7, Mon.X - 2, ConvertNumber(v[5]), 6960, colors.green, colors.gray)

        UIF.DrawTextLeftRight(Mon, 2, 9, 1, "Fuel Time Left:", v[6], DefaultTextColor, colors.white, DefaultBackgroundColor)

        UIF.NewButton(Mon, 2, 12, 2, "Start Reactor", colors.white, colors.gray, StartReactor)
        UIF.NewButton(Mon, 2, 17, 2, "Shutdown", colors.white, colors.gray, ShutdownReactor)

    end
    sleep(0.1)
end


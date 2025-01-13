local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
--assert(peripheral.getType("right") == "monitor", "No Monitor!")
--assert(peripheral.getType("left") == "info_panel_advanced", "No Reactor Info!")
assert(peripheral.find("modem"), "No Modem attached!")
-- More checks

print("Done!")

--ocal Modem = peripheral.find("modem")
--Modem.open(0) -- Broadcast
--Modem.open(1) -- Computer 1
--Modem.open(2) -- Computer 2

local ReactorScreens = {}
local CoolantScreens = {}

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local StatusColor = colors.red
local TempColor = colors.green
local TempBarColor = colors.green
local RemainingColor = colors.green

local ReactorCardData

local UIF = require("UIFunctions")
local Config = require("PerfConfig")
local Taskmaster = require("taskmaster")()

local ConvertNumber = function(str)
    local cleanedStr = string.gsub(str, "%s", "")
    local number = tonumber(cleanedStr)
    return number
end

local GetReactorCardData = function()
    rednet.broadcast("GetCardData")
        
    local ID, message = rednet.receive()
    print("Message Recieved!")
    local CardData = textutils.unserialize(message)

    local sortedTables = {}
    for i = 1, #CardData, 6 do
        local cardData = {}
        if CardData[i] == "Out of Range" then
            table.insert(cardData, "Out of Range")
        else
            for j = 0, 5 do
                table.insert(cardData, CardData[i + j])
            end
        end
        table.insert(sortedTables, cardData)
    end

    ReactorCardData = sortedTables
end

local StartReactor = function(event, x, y)
    rs.setBundledOutput("back", colors.black)
end

local ShutdownReactor = function(event, x, y)
    rs.setBundledOutput("back", 0)
end

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

local DrawDynamicUI = function(i, v)
    for i,Mon in pairs(ReactorScreens) do
        UIF.Clear(Mon)
        UIF.DrawTextLeftRight(Mon, 2, 1, 0, "Reactor Status ["..i.."]", v[2], DefaultTextColor, StatusColor, DefaultBackgroundColor)

        UIF.DrawTextLeftRight(Mon, 2, 3, 0, "Reactor Temperature:", v[1].." °C", DefaultTextColor, TempColor, DefaultBackgroundColor)
        UIF.ProgressBar(Mon, 2, 4, Mon.X - 2, ConvertNumber(v[1]), ConvertNumber(v[3]), TempBarColor, colors.gray)
    
        UIF.DrawTextLeftRight(Mon, 2, 6, 0, "Reactor Output:", v[5].." EU/t", DefaultTextColor, colors.white, DefaultBackgroundColor)
        UIF.ProgressBar(Mon, 2, 7, Mon.X - 2, ConvertNumber(v[5]), 6960, colors.green, colors.gray)
    
        UIF.DrawTextLeftRight(Mon, 2, 9, 0, "Fuel Time Left:", v[6], DefaultTextColor, colors.white, DefaultBackgroundColor)
    
        UIF.NewButton(Mon, 2, 12, 2, "Start Reactor", colors.white, colors.gray, StartReactor)
        UIF.NewButton(Mon, 20, 12, 2, "Shutdown", colors.white, colors.gray, ShutdownReactor)
    end
end

local Init = function()
    assert(peripheral.wrap(Config["Reactor_Screen_1"]), "Invalid Config [1]")
    assert(peripheral.wrap(Config["Reactor_Coolant_Screen_1"]), "Invalid Config [2]")
    assert(peripheral.wrap(Config["Reactor_Screen_2"]), "Invalid Config [3]")
    assert(peripheral.wrap(Config["Reactor_Coolant_Screen_2"]), "Invalid Config [4]")

    rednet.open("bottom")

    local Reactor_Screen_1 = peripheral.wrap(Config["Reactor_Screen_1"])
    local Reactor_1_X, Reactor_1_Y = Reactor_Screen_1.getSize()

    local Reactor_Coolant_Screen_1 = peripheral.wrap(Config["Reactor_Coolant_Screen_1"])
    local Reactor_Coolant_1_X, Reactor_Coolant_1_Y = Reactor_Coolant_Screen_1.getSize()

    local Reactor_Screen_2 = peripheral.wrap(Config["Reactor_Screen_2"])
    local Reactor_2_X, Reactor_2_Y = Reactor_Screen_2.getSize()

    local Reactor_Coolant_Screen_2 = peripheral.wrap(Config["Reactor_Coolant_Screen_2"])
    local Reactor_Coolant_2_X, Reactor_Coolant_2_Y = Reactor_Coolant_Screen_2.getSize()

    ReactorScreens = {
        Screen_1 = {
            screen = Reactor_Screen_1,
            X = Reactor_1_X,
            Y = Reactor_1_Y,
        },
        Screen_2 = {
            screen = Reactor_Screen_2,
            X = Reactor_2_X,
            Y = Reactor_2_Y,
        },
    }

    CoolantScreens = {
        Screen_1 = {
            screen = Reactor_Coolant_Screen_1,
            X = Reactor_Coolant_1_X,
            Y = Reactor_Coolant_1_Y,
        },
        Screen_2 = {
            screen = Reactor_Coolant_Screen_2,
            X = Reactor_Coolant_2_X,
            Y = Reactor_Coolant_2_Y,
        },
    }

    for i,Mon in pairs(ReactorScreens) do
        UIF.Clear(Mon)
        Mon.screen.setTextScale(1)
    end

    for i,Mon in pairs(CoolantScreens) do
        UIF.Clear(Mon)
        Mon.screen.setTextScale(1)
    end

    --for i,v in pairs(ReactorCardData) do
    --    DrawDynamicUI(i, v)
    --end
end
Init()

local Update = function()
    while true do
        if ReactorCardData then
            GetReactorCardData()
    
            for i,v in pairs(ReactorCardData) do
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
        
                DrawDynamicUI(i, v)
            end
        end
        sleep(0.1)
    end
end

parallel.waitForAny(UIF.Event, Update)


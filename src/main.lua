local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
assert(peripheral.find("modem"), "No Modem attached!")
-- More checks

print("Done!")

local ReactorScreens = {}
local CoolantScreens = {}

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local StatusColor = colors.red
local TempColor = colors.green
local TempBarColor = colors.green
local RemainingColor = colors.green

local UIF = require("UIFunctions")
local Config = require("PerfConfig")
local Taskmaster = require("taskmaster")()

local ConvertNumber = function(str)
    local cleanedStr = string.gsub(str, "%s", "")
    local number = tonumber(cleanedStr)
    return number
end

local SortCardData = function(cardData, entrySize)
    local sortedTables = {}
    for i = 1, #cardData, entrySize do
        local cardEntry = {}
        if cardData[i] == "Out of Range" then
            table.insert(cardEntry, "Out of Range")
        else
            for j = 0, entrySize - 1 do
                table.insert(cardEntry, cardData[i + j])
            end
        end
        table.insert(sortedTables, cardEntry)
    end
    return sortedTables
end

local GetReactorCardData = function()
    rednet.broadcast("GetCardData")
        
    local ID, message = rednet.receive()
    if not message then
        print("Error: No message received!")
        return
    end

    local success, CardData = pcall(textutils.unserialize, message)
    if not success or not CardData then
        print("Error: Failed to parse card data!")
        return
    end

    for i, v in pairs(CardData) do
        print(i,v)
    end

    for i, v in pairs(ReactorScreens) do
        for _, screen in ipairs(CardData["Reactor"]) do
            print(screen.ScreenID, v.ScreenID)
            if tonumber(screen.ScreenID) == tonumber(v.ScreenID) then
                screen.ScreenData = sortCardData(screen.Data, 6)
            end
        end
    end

    for i, v in pairs(CoolantScreens) do
        for _, screen in ipairs(CardData["Heat"]) do
            if tonumber(screen.ScreenID) == tonumber(v.ScreenID) then
                screen.ScreenData = sortCardData(screen.Data, 6)
            end
        end
    end
end

local StartReactor = function(event, x, y)
    rs.setBundledOutput("back", colors.black)
end

local ShutdownReactor = function(event, x, y)
    rs.setBundledOutput("back", 0)
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

    local Reactor_ScreenID_1 = Config["ScreenID_1"]
    ------------------------------------------------------------------------------------------------------

    local Reactor_Screen_2 = peripheral.wrap(Config["Reactor_Screen_2"])
    local Reactor_2_X, Reactor_2_Y = Reactor_Screen_2.getSize()

    local Reactor_Coolant_Screen_2 = peripheral.wrap(Config["Reactor_Coolant_Screen_2"])
    local Reactor_Coolant_2_X, Reactor_Coolant_2_Y = Reactor_Coolant_Screen_2.getSize()

    local Reactor_ScreenID_2 = Config["ScreenID_2"]

    ReactorScreens = {
        Screen_1 = {
            screen = Reactor_Screen_1,
            X = Reactor_1_X,
            Y = Reactor_1_Y,
            ScreenID = Reactor_ScreenID_1,
            ScreenData = nil,
        },
        Screen_2 = {
            screen = Reactor_Screen_2,
            X = Reactor_2_X,
            Y = Reactor_2_Y,
            ScreenID = Reactor_ScreenID_2,
            ScreenData = nil,
        },
    }

    CoolantScreens = {
        Screen_1 = {
            screen = Reactor_Coolant_Screen_1,
            X = Reactor_Coolant_1_X,
            Y = Reactor_Coolant_1_Y,
            ScreenID = Reactor_ScreenID_1,
            ScreenData = nil,
        },
        Screen_2 = {
            screen = Reactor_Coolant_Screen_2,
            X = Reactor_Coolant_2_X,
            Y = Reactor_Coolant_2_Y,
            ScreenID = Reactor_ScreenID_2,
            ScreenData = nil,
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
end
Init()

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

local Update = function()
    while true do
        GetReactorCardData()

        for _, Screen in pairs(ReactorScreens) do
            local Mon = Screen
            if Screen.ScreenData then
                for i, v in pairs(Screen.ScreenData) do
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
        end

        
        for _, Screen in pairs(CoolantScreens) do
            local Mon = Screen

            --for i, v in pairs(Screen.ScreenData) do
            --    if Screen.ScreenData then
                    --TODO Add Coolant Info
            --    end
            --end
        end
        sleep(0.1)
    end
end

parallel.waitForAny(UIF.Event, Update)


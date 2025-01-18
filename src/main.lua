local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
print("Loading program...")

assert(http.get(VersionURL).readAll() == VersionFile.readAll(), "Outdated version, please run install.lua again")
assert(peripheral.find("modem"), "No Modem attached!")
-- More checks

print("Done!")
local UpdatingTick = 0

local ReactorScreens = {}
local CoolantScreens = {}

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local UIF = require("UIFunctions")
local Config = require("PerfConfig")
local Taskmaster = require("taskmaster")()
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local ConvertNumber = function(str)
    print(str)
    local success, result = pcall(function()
        expect(1, str, "string")
    end)

    if not success then
        return str
    end

    local cleanedStr = string.gsub(str, "%s", "")
    local number = tonumber(cleanedStr)

    if number then
        return number
    end

    return str
end


local SortCardData = function(cardData, entrySize)
    local sortedTables = {}
    for i = 1, #cardData, entrySize do
        local cardEntry = {}
        if cardData[i] == "Out of Range" or cardData[i] == "Error getting Heat Card Data" then
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

    local success, CardData = pcall(textutils.unserializeJSON, message)
    if not success or not CardData then
        print("Error: Failed to parse card data!")
        return
    end

    for i, Screen in pairs(ReactorScreens) do
        local ReactorData = CardData["Reactor"]
        if tonumber(ReactorData.ScreenID) == tonumber(Screen.ScreenID) then
            Screen.ScreenData = SortCardData(ReactorData.Data, 6)
        end
    end

    for i, Screen in pairs(CoolantScreens) do
        local HeatData = CardData["Heat"]
        if tonumber(HeatData.ScreenID) == tonumber(Screen.ScreenID) then
            Screen.ScreenData = SortCardData(HeatData.Data, 10)
        end
    end
end

local SetBundleState = function(side, color, state)
    if (type(side) == "string") and (type(color) == "string") and (type(state) == "boolean") then
        if state == true then
            rs.setBundledOutput(side, colors.combine(rs.getBundledOutput(side), colors[color]))
        elseif state == false then
            rs.setBundledOutput(side, colors.subtract(rs.getBundledOutput(side), colors[color]))
        end
    end
end

local StartReactor_1 = function(event, x, y)
    SetBundleState("back", "black", true)
end

local ShutdownReactor_1 = function(event, x, y)
    SetBundleState("back", "black", false)
end

local StartReactor_2 = function(event, x, y)
    SetBundleState("back", "gray", true)
end

local ShutdownReactor_2 = function(event, x, y)
    SetBundleState("back", "gray", false)
end

local CheckReactorState = function(ReactorData, CoolantData)
    for i,v in pairs(ReactorData) do
        if ConvertNumber(v[1]) >= 8000 then
            ShutdownReactor_1()
            ShutdownReactor_2()
        end
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

local Update = function()
    while true do
        GetReactorCardData()

        --[[
            Reactor Info:
            [1] = temp
            [2] = on/off
            [3] = max heat
            [4] = meltdown temp
            [5] = hU/t output (Fluid Reactor)
            [6] = remaining
        ]]
        for _, Screen in pairs(ReactorScreens) do
            local Mon = Screen
            UIF.Clear(Mon)

            local StatusColor = colors.red
            local TempColor = colors.green
            local TempBarColor = colors.green
            local RemainingColor = colors.green

            if Screen.ScreenData then
                for i, v in pairs(Screen.ScreenData) do
                    if ConvertNumber(v[1]) >= 7500 then
                        TempColor = colors.red
                        TempBarColor = colors.red
                        ShutdownReactor_1() --TODO add shutdown for option for both or only effected one
                        ShutdownReactor_2()
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

                    UIF.DrawTextLeftRight(Mon, 2, 1, 0, "Reactor Status ["..Mon.ScreenID.."]", v[2], DefaultTextColor, StatusColor, DefaultBackgroundColor)
            
                    UIF.DrawTextLeftRight(Mon, 2, 3, 0, "Reactor Temperature:", v[1].." °C", DefaultTextColor, TempColor, DefaultBackgroundColor)
                    UIF.ProgressBar(Mon, 2, 4, Mon.X - 2, ConvertNumber(v[1]), ConvertNumber(v[3]), TempBarColor, colors.gray)
                
                    UIF.DrawTextLeftRight(Mon, 2, 6, 0, "Reactor Output:", v[5].." hU/t", DefaultTextColor, colors.white, DefaultBackgroundColor)
                    UIF.ProgressBar(Mon, 2, 7, Mon.X - 2, ConvertNumber(v[5]), 35000, colors.green, colors.gray)
                
                    UIF.DrawTextLeftRight(Mon, 2, 9, 0, "Fuel Time Left:", v[6], DefaultTextColor, colors.white, DefaultBackgroundColor)
                
                    UIF.NewButton(Mon, 2, 12, 2, "Start Reactor", colors.white, colors.gray, StartReactor_1)
                    UIF.NewButton(Mon, 20, 12, 2, "Shutdown", colors.white, colors.gray, ShutdownReactor_1)
                end
            end  
        end

        -- Heat Gen Card + Advanced Fluid Card
        --[[
            Coolant Info:
            [1] = Name (Coolant name)
            [2] = Amount (mB)
            [3] = Free (mB)
            [4] = Capacity (mB)
            [5] = Fill (%)

            -- Hot Coolant
            [6] = Name (Coolant name)
            [7] = Amount (mB)
            [8] = Free (mB)
            [9] = Capacity (mB)
            [10] = Fill
        ]]
        for _, Screen in pairs(CoolantScreens) do
            local Mon = Screen
            UIF.Clear(Mon)

            local StatusColor = colors.red
            local CoolantAmount = colors.green
            local CoolantFill = colors.green
            local HotCoolantAmount = colors.green
            local HotCoolantFill = colors.green


            if Screen.ScreenData then
                for i, v in pairs(Screen.ScreenData) do
                    if ConvertNumber(v[5]) <= 20 then
                        CoolantFill = colors.red
                        ShutdownReactor_1() --TODO add shutdown for option for both or only effected one
                        ShutdownReactor_2()
                    elseif ConvertNumber(v[5]) <= 50 then
                        CoolantFill = colors.red
                    elseif ConvertNumber(v[5]) <= 75 then
                        CoolantFill = colors.orange
                    else
                        CoolantFill = colors.green
                    end

                    if ConvertNumber(v[7]) >= 4000 then
                        HotCoolantAmount = colors.red
                        HotCoolantFill = colors.red
                    elseif ConvertNumber(v[7]) >= 2000 then
                        HotCoolantAmount = colors.orange
                        HotCoolantFill = colors.orange
                    elseif ConvertNumber(v[7]) >= 1000 then
                        HotCoolantAmount = colors.yellow
                        HotCoolantFill = colors.yellow
                    else
                        HotCoolantAmount = colors.green
                        HotCoolantFill = colors.green
                    end

                    UIF.DrawText(Mon, 2, 1, "Reactor Coolant Status ["..Mon.ScreenID.."]", DefaultTextColor, DefaultBackgroundColor)

                    UIF.DrawText(Mon, 0, 3, UIF.LineBreakText(Mon, " Cool Coolant "), DefaultTextColor, DefaultBackgroundColor)

                    UIF.DrawTextLeftRight(Mon, 2, 4, 0, "Coolant Amount:", v[2].." mB", DefaultTextColor, CoolantAmount, DefaultBackgroundColor)
                    UIF.DrawTextLeftRight(Mon, 2, 5, 0, "Coolant Fill Stand:", v[5].." %", DefaultTextColor, CoolantFill, DefaultBackgroundColor)

                    UIF.DrawText(Mon, 0, 7, UIF.LineBreakText(Mon, " Hot Coolant "), DefaultTextColor, DefaultBackgroundColor)

                    UIF.DrawTextLeftRight(Mon, 2, 8, 0, "Coolant Amount:", v[7].." mB", DefaultTextColor, HotCoolantAmount, DefaultBackgroundColor)
                    UIF.DrawTextLeftRight(Mon, 2, 9, 0, "Coolant Fill Stand:", v[10].." %", DefaultTextColor, HotCoolantFill, DefaultBackgroundColor)
                end
            end
        end
        sleep(0.1)
    end
end

parallel.waitForAny(UIF.Event, Update)


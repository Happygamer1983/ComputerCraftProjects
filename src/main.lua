local VersionURL = "https://raw.githubusercontent.com/Happygamer1983/ComputerCraftProjects/refs/heads/main/src/VERSION"
local VersionFile = fs.open("VERSION", "r")
local Config = require("/lib/PerfConfig")

local LoadingErrorPrint = function(text, x, y)
    local Screen = peripheral.wrap(Config["Reactor_Screen_1"])
    Screen.clear()
    Screen.setBackgroundColor(colors.black)
    Screen.setTextColor(colors.red)
    Screen.setCursorPos(x,y)
    Screen.write(text)
end

print("Loading program...")
assert(http.get(VersionURL).readAll() == VersionFile.readAll(), LoadingErrorPrint("Outdated version, run installer.lua!", 1,1))
assert(peripheral.find("modem"), LoadingErrorPrint("No Modem attached!", 1,1))
-- More checks
print("Done!")

local UIF = require("/lib/UIFunctions")
local Taskmaster = require("/lib/taskmaster")()

local UpdatingTick = 0

local ReactorScreens = {}
local CoolantScreens = {}

local DefaultTextColor = colors.white
local DefaultBackgroundColor = colors.black

local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local ConvertNumber = function(str)
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
            Screen.ScreenData = SortCardData(HeatData.Data, 16)
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

local TempServerWarn = function()
    coroutine.wrap(function()
        while true do
            SetBundleState("back", "orange", true)
            sleep(1)
        end
    end)() 
end

local CoolantServerWarn = function()
    coroutine.wrap(function()
        while true do
            SetBundleState("back", "red", true)
            sleep(1)
        end
    end)() 
end

local EmergencyShutdown = function()
    SetBundleState("back", "yellow", true)
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
                        EmergencyShutdown()
                    elseif ConvertNumber(v[1]) >= 6500 then
                        TempColor = colors.orange
                        TempBarColor = colors.orange
                        TempServerWarn()
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
                    UIF.NewButton(Mon, 21, 12, 2, "Shutdown Reactor", colors.white, colors.gray, ShutdownReactor_1)
                end
            end  
        end

        -- Advanced Fluid Card
        --[[
            Heat Exchanger Info:
            -- Hot Coolant
            [-] = Name (Coolant name) -- REMOVED (Causes Java Error on server)
            [1] = Amount (mB)
            [2] = Free (mB)
            [3] = Capacity (mB)
            [4] = Fill (%)

            -- Cool Coolant
            [-] = Name (Coolant name) -- REMOVED (Causes Java Error on server)
            [5] = Amount (mB)
            [6] = Free (mB)
            [7] = Capacity (mB)
            [8] = Fill

            Fluid Port Info:
            -- Cool Coolant
            [-] = Name (Coolant name) -- REMOVED (Causes Java Error on server)
            [9] = Amount (mB)
            [10] = Free (mB)
            [11] = Capacity (mB)
            [12] = Fill (%)

            -- Hot Coolant
            [-] = Name (Coolant name) -- REMOVED (Causes Java Error on server)
            [13] = Amount (mB)
            [14] = Free (mB)
            [15] = Capacity (mB)
            [16] = Fill
        ]]

        local CheckHEHotCoolant = function(v, index)
            local ConvertedNumber = ConvertNumber(v[index])

            if ConvertedNumber >= 75 then
                EmergencyShutdown()
                return colors.red
            elseif ConvertedNumber >= 50 then
                return colors.orange
            elseif ConvertedNumber >= 20 then
                return colors.yellow
            else
                return colors.green
            end
        end

        local CheckHECoolant = function(v, index)
            local ConvertedNumber = ConvertNumber(v[index])

            if ConvertedNumber >= 80 then
                return colors.red
            elseif ConvertedNumber >= 60 then
                return colors.orange
            elseif ConvertedNumber >= 40 then
                return colors.yellow
            else
                return colors.green
            end
        end


        local CheckFPCoolant = function(v, index)
            local ConvertedNumber = ConvertNumber(v[index])

            if ConvertedNumber <= 40 then
                EmergencyShutdown()
                return colors.red
            elseif ConvertedNumber <= 60 then
                return colors.orange
            elseif ConvertedNumber <= 80 then
                return colors.yellow
            else
                return colors.green
            end
        end

        local CheckFPHotCoolant = function(v, index)
            local ConvertedNumber = ConvertNumber(v[index])

            if ConvertedNumber >= 70 then
                EmergencyShutdown()
                return colors.red
            elseif ConvertedNumber >= 50 then
                return colors.orange
            elseif ConvertedNumber >= 20 then
                return colors.yellow
            else
                return colors.green
            end
        end

        local HEHotCoolant = colors.green
        local HECoolant = colors.green

        local FPHotCoolant = colors.green
        local FPCoolant = colors.green

        for _, Screen in pairs(CoolantScreens) do
            local Mon = Screen
            UIF.Clear(Mon)

            if Screen.ScreenData then
                for i, v in pairs(Screen.ScreenData) do

                    HEHotCoolant = CheckHEHotCoolant(v, 4)
                    HECoolant = CheckHECoolant(v, 8)

                    UIF.DrawText(Mon, 2, 1, "Reactor Coolant Status ["..Mon.ScreenID.."]", DefaultTextColor, DefaultBackgroundColor)
                    UIF.DrawText(Mon, 0, 3, UIF.LineBreakText(Mon, " Heat Exchanger Info "), DefaultTextColor, DefaultBackgroundColor)

                    UIF.DrawTextLeftRight(Mon, 2, 5, 0, "Hot Coolant Amount:", v[1].." mB", DefaultTextColor, HEHotCoolant, DefaultBackgroundColor)
                    UIF.DrawTextLeftRight(Mon, 2, 6, 0, "Hot Coolant Fill Stand:", v[4].." %", DefaultTextColor, HEHotCoolant, DefaultBackgroundColor)

                    UIF.DrawTextLeftRight(Mon, 2, 8, 0, "Coolant Amount:", v[5].." mB", DefaultTextColor, HECoolant, DefaultBackgroundColor)
                    UIF.DrawTextLeftRight(Mon, 2, 9, 0, "Coolant Fill Stand:", v[8].." %", DefaultTextColor, HECoolant, DefaultBackgroundColor)


                    FPCoolant = CheckFPCoolant(v, 12)
                    FPHotCoolant = CheckFPHotCoolant(v, 16)

                    UIF.DrawText(Mon, 0, 11, UIF.LineBreakText(Mon, " Fluid Port Info "), DefaultTextColor, DefaultBackgroundColor)

                    UIF.DrawTextLeftRight(Mon, 2, 13, 0, "Coolant Amount:", v[9].." mB", DefaultTextColor, FPCoolant, DefaultBackgroundColor)
                    UIF.DrawTextLeftRight(Mon, 2, 14, 0, "Coolant Fill Stand:", v[12].." %", DefaultTextColor, FPCoolant, DefaultBackgroundColor)

                    UIF.DrawTextLeftRight(Mon, 2, 16, 0, "Hot Coolant Amount:", v[13].." mB", DefaultTextColor, FPHotCoolant, DefaultBackgroundColor)
                    UIF.DrawTextLeftRight(Mon, 2, 17, 0, "Hot Coolant Fill Stand:", v[16].." %", DefaultTextColor, FPHotCoolant, DefaultBackgroundColor)
                end
            end
        end
        sleep(0.1)
    end
end

parallel.waitForAny(UIF.Event, Update)


rednet.open("bottom")
local ScreenID

local file = fs.open("ID.lua", "r")
ScreenID = file.readAll()
file.close()

while true do
    local ID, message = rednet.receive()
    
    local CardData = {}
    local HeatCard = peripheral.wrap("left")
    local ReactorCard = peripheral.wrap("right")
    
    local HeatData
    local ReactorData
    
    local success, fail = pcall(function()
        HeatData = HeatCard.getCardData()
    end)
    
    if not success then
        HeatData = {"Error getting Heat Card Data!"}
    end
    
    local success, fail = pcall(function()
        ReactorData = ReactorCard.getCardData()
    end)
    
    if not success then
        ReactorData = {"Error getting Reactor Card Data!"}
    end
    
    CardData["Heat"] = {Data = HeatData, ScreenID = ScreenID}
    CardData["Reactor"] = {Data = ReactorData, ScreenID = ScreenID}
    rednet.send(ID, textutils.serialize(CardData))
    sleep(0.1)
end
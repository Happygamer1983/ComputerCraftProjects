local Modem = peripheral.find("modem")
local ID
Modem.open(0) -- 0 is broadcast channel

local event, side, channel, replyChannel, message, distance
repeat
    event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
  until channel == 0

if fs.exists("ID") then
    local file = fs.open("ID", "r")
    ID = file.readAll()
    file.close()

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

    CardData["Heat"] = HeatData
    CardData["Reactor"] = ReactorData
    Modem.transmit(tonumber(ID), tonumber(ID), textutils.serializeJSON(CardData))
end
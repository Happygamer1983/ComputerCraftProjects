
rednet.open("bottom")

local ID, message = rednet.receive()
print("Message Recieved!")

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
print("Sending Back")
rednet.send(ID, textutils.serializeJSON(CardData))


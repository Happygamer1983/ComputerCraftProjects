local UIF = {}
local Buttons = {}
local touchX, touchY = {}

local Event = function()
    while true do
        _, _, touchX, touchY = os.pullEvent("monitor_touch") 
    end
end

local ButtonUpdate = function()
    for i,v in pairs(Buttons) do
        if touchX >= v.x and touchX < v.x + string.len(v.text) + 2 and touchY >= v.y and touchY < v.y + height then
            v.callback(event, x, y)   
        end  
    end
    --for i,v in pairs(Callback) do
    --    v()
    --    table.remove(Callback, i)
    --end
end

function UIF.FormatNum(number)
    number = number or 0  -- Default to 0 if nil
    local minus, int, fraction = tostring(number):match('([-]?)(%d+)([.]?%d*)')
  
    -- Add commas to the integer part
    int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  
    -- Combine the parts
    return minus .. int .. fraction
end

function UIF.DrawText(Mon, x, y, text, text_color, background_color)
    Mon.screen.setBackgroundColor(background_color)
    Mon.screen.setTextColor(text_color)
    Mon.screen.setCursorPos(x,y)
    Mon.screen.write(text)
end

function UIF.DrawTextRight(Mon, x, y, text, text_color, background_color)
    Mon.screen.setBackgroundColor(background_color)
    Mon.screen.setTextColor(text_color)
    Mon.screen.setCursorPos(Mon.X-string.len(tostring(text))-x,y)
    Mon.screen.write(text)
end

function UIF.DrawTextLeftRight(Mon, x, y, offset, text1, text2, text1_color, text2_color, background_color)
    UIF.DrawText(Mon, x, y, text1, text1_color, background_color)
	UIF.DrawTextRight(Mon, offset, y, text2, text2_color, background_color)
end

function UIF.DrawLine(Mon, x, y, length, color)
    if length < 0 then
        length = 0
      end
      Mon.screen.setBackgroundColor(color)
      Mon.screen.setCursorPos(x,y)
      Mon.screen.write(string.rep(" ", length))
end

function UIF.ProgressBar(Mon, x, y, length, value, maxVal, bar_color, background_color)
    value = math.max(0, math.min(value, maxVal))
    local barSize = math.floor((value / maxVal) * length)

    UIF.DrawLine(Mon, x + barSize, y, length - barSize, background_color)

    UIF.DrawLine(Mon, x, y, barSize, bar_color)
end

function UIF.NewButton(Mon, x, y, height, text, text_color, button_color, callback)
    for i = 0, height, 1 do 
        UIF.DrawLine(Mon, x, y + i, string.len(text) + 2, button_color)
    end
    UIF.DrawText(Mon, x + 1, y + height / 2, text, text_color, button_color)

    table.insert(Buttons, {
        Mon = Mon,
        x = x,
        y = y,
        height = height,
        text = text,
        text_color = text_color,
        button_color = button_color,
        callback = callback
    })
end

function UIF.Clear(Mon)
    --term.clear()
    --term.setCursorPos(1,1)
    Mon.screen.setBackgroundColor(colors.black)
    Mon.screen.clear()
    Mon.screen.setCursorPos(1,1)
end

parallel.waitForAny(Event, ButtonUpdate)

--coroutine.wrap(function()
    --Event()
--end)()

return UIF
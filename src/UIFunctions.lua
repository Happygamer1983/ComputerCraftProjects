local UIF = {}

function UIF.DrawLine(screen, x, y, length, color)
    if length < 0 then
        length = 0
      end
      screen.setBackgroundColor(color)
      screen.setCursorPos(x,y)
      screen.write(string.rep(" ", length))
end

function UIF.FormatNum(number)
    number = number or 0  -- Default to 0 if nil
    local minus, int, fraction = tostring(number):match('([-]?)(%d+)([.]?%d*)')
  
    -- Add commas to the integer part
    int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
  
    -- Combine the parts
    return minus .. int .. fraction
end

function UIF.DrawText(screen, x, y, text, text_color, background_color)
    screen.setBackgroundColor(background_color)
    screen.setTextColor(text_color)
    screen.setCursorPos(x,y)
    screen.write(text)
end

function UIF.DrawTextRight(screen, x, y, text, text_color, background_color)
    screen.setBackgroundColor(background_color)
    screen.setTextColor(text_color)
    screen.setCursorPos(mon.X-string.len(tostring(text))-offset,y)
    screen.write(text)
end

function UIF.DrawTextMultiColor(screen, x, y, offset, text1, text2, text1_color, text2_color, background_color)
    UIF.DrawText(screen, x, y, text1, text1_color, background_color)
	UIF.DrawTextRight(screen, offset, y, text2, text2_color, background_color)
end

function UIF.ProgressBar(screen, x, y, length, value, maxVal, bar_color, background_color)
   UIF.DrawLine(screen, x, y, length, background_color)

   value = math.max(0, math.min(value, maxVal))
   local barSize = math.floor((value / maxVal) * length)
   print("Bar size:", barSize, "Length:", length)
   UIF.DrawLine(screen, x, y, barSize, bar_color)
end

function UIF.Clear(screen)
    term.clear()
    term.setCursorPos(1,1)
    screen.setBackgroundColor(colors.black)
    screen.clear()
    screen.setCursorPos(1,1)
end

return UIF

--[[
function UIF.DrawLine()
   
end
]]
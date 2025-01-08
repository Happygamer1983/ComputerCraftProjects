function draw_line(screen, x, y, length, color)
    if length < 0 then
      length = 0
    end
    screen.setBackgroundColor(color)
    screen.setCursorPos(x,y)
    screen.write(string.rep(" ", length))
end

local screen = peripheral.wrap("right")

draw_line(screen, 2,2,10, colors.gray)
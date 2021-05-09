rednet.open("left")
local id = rednet.lookup("ttns")

function getOrientation()
    local loc1 = vector.new(gps.locate(2, false))
    turtle.forward()
    local loc2 = vector.new(gps.locate(2, false))
    local heading = loc2 - loc1
    return ((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))
end

function check(x, y, z, ok, block)
    local x, y, z = getCoords(x, y, z)
    if ok then
        rednet.send(id, textutils.serialize({request = "set", x = x, y = y, z = z, block = block.name}))
        return false
    end
    return true
end

function left()
    if turtle.turnLeft() then
        o = o -1
        if o == 0 then
            o = 4
        end
    end
end

function right()
    if turtle.turnRight() then
        o = o + 1
        if o == 5 then
            o = 1
        end
    end
end

function getCoords(x, y, z)   
    if (o == 1) then
        x = x - 1
    elseif (o == 2) then
        z = z - 1
    elseif (o == 3) then
        x = x + 1
    elseif (0 == 4) then
        z = z + 1
    end
    
    return x, y, z
end

local o = getOrientation()

while true do
    x, y, z = gps.locate(2, false)
    front = check(x, y, z, turtle.inspect())
    left()
    dleft = check(x, y, z, turtle.inspect())
    right()
    right()
    dright = check(x, y, z, turtle.inspect())
    left()
    up = check(x, y + 1, z, turtle.inspectUp())
    down = check(x, y - 1, z, turtle.inspectDown())
    
    if front then
        turtle.forward()
    elseif dleft then
        left()
        turtle.forward()
    elseif dright then
        right()
        turtle.forward()
    elseif up then
        turtle.up()
    elseif down then
        turtle.down()
    else
        right()
        right()
        turtle.forward()
    end
end
rednet.open("left")
id = rednet.lookup("ttns")

function getOrientation()
	loc1 = vector.new(gps.locate(2, false))
	if not turtle.forward() then
		for j=1,6 do
            if not turtle.forward() then
                turtle.dig()
			else break end
		end
	end
	loc2 = vector.new(gps.locate(2, false))
	heading = loc2 - loc1
	return ((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))
end

function check(ok, block, x, y, z)

	if ok then
		rednet.send(id, textutils.serialize({request = "set", x = x, y = y, z = z, block = block.name}))
	end
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

function getCoords()
	x, y, z = gps.locate(2, false)
	
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

function explore()

	check(turtle.inspect(), getCoords())

	left()
	
	check(turtle.inspect(), getCoords())
	
	right()
	right()
	
	check(turtle.inspect(), getCoords())
	
	left()
	
	x, y, z = gps.locate(2, false)
	
	check(turtle.inspectUp(), x, y + 1, z)
	
	check(turtle.inspectDown(), x, y - 1, z)
end

function go()
	if not turtle.detect() then
		turtle.forward()
	end
	
	left()
	
	if not turtle.detect() then
		turtle.forward()
	end
	
	right()
    right()
	
	if not turtle.detect() then
		turtle.forward()
	end
	
	left()
	
	if not turtle.detectUp() then
		turtle.up()
	end
	
	if not turtle.detectDown() then
		turtle.down()
	end
end

o = getOrientation()

while true do
	explore()
	go()
end
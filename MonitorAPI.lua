------------
-- Simple monitor GUI API for ComputerCraft
-- @module MonitorAPI
-- @release https://pastebin.com/D325xpYJ
-- @author Deleranax

local objects = {n=0}

--- Reset Workspace

function reset()
	objects = {n=0}
end

--- Add a button
-- @tparam number x Abscissa of the button
-- @tparam number y Ordinate of the button
-- @tparam number width Width of the button
-- @tparam number length Length of the button
-- @tparam color bcolor Color of the button (background)
-- @tparam color fcolor Color of the button (text)
-- @tparam func f Command of the button
-- @tparam string ... Label of the button
-- @treturn number id ID of the button

function addButton(x, y, width, length, bcolor, fcolor, f, ...)
	for i, val in ipairs({x, y, width, length, bcolor, fcolor, f, arg}) do if val == nil then error("Arg#"..i.." is not optional.") end end
	table.insert(objects, {"Button", x, y, width, length, bcolor, fcolor, f, arg})
	return table.getn(objects)
end

--- Add a progress bar
-- @tparam number x Abscissa of the button
-- @tparam number y Ordinate of the button
-- @tparam number width Width of the button
-- @tparam number length Length of the button
-- @tparam color color Color of the progress bar
-- @tparam[opt=black] color bcolor Color of the background
-- @tparam number value Current value
-- @tparam number maxValue Max value
-- @tparam[opt=false] bool vertical Make this bar vertical

function addProgressBar(x, y, width, length, color, bcolor, value, maxValue, vertical)
	vertical = vertical or false
	bcolor = bcolor or colors.black
	for i, val in ipairs({x, y, width, length, color, bcolor, value, maxValue}) do if val == nil then error("Arg#"..i.." is not optional.") end end
	if not vertical then
		table.insert(objects, {"ProgressBar", x, y, width, length, color, bcolor, value, maxValue})
	else
		table.insert(objects, {"VerticalProgressBar", x, y, width, length, color, bcolor, value, maxValue})
	end
	return table.getn(objects)
end

--- Modify button
-- @param id Object ID
-- @tparam[opt=Old value] number x Abscissa of the button
-- @tparam[opt=Old value] number y Ordinate of the button
-- @tparam[opt=Old value] number width Width of the button
-- @tparam[opt=Old value] number length Length of the button
-- @tparam[opt=Old value] color bcolor Color of the button (background)
-- @tparam[opt=Old value] color fcolor Color of the button (text)
-- @tparam[opt=Old value] func f Command of the button
-- @tparam[opt=Old value] string ... Label of the button
-- @treturn number id ID of the button

function modifyButton(id, x, y, width, length, bcolor, fcolor, f, ...)
	local button = objects[id]
	if button == nil or button[1] ~= "Button" then error("Invalid object: got "..pb[1].." expected Button") end
	x = x or button[2]
	y = y or button[3]
	width = width or button[4]
	length = length or button[5]
	bcolor = bcolor or button[6]
	fcolor = bcolor or button[7]
	f = f or button[8]
	text = arg or button[9]
	objects[id] = {"Button", x, y, width, length, bcolor, fcolor, f, text}
end

--- Modify progress bar
-- @param id Object ID
-- @tparam[opt=Old value] number x Abscissa of the button
-- @tparam[opt=Old value] number y Ordinate of the button
-- @tparam[opt=Old value] number width Width of the button
-- @tparam[opt=Old value] number length Length of the button
-- @tparam[opt=Old value] color color Color of the progress bar
-- @tparam[opt=Old Value] color bcolor Color of the background
-- @tparam[opt=Old value] number value Current value
-- @tparam[opt=Old value] number maxValue Max value

function modifyProgressBar(id, x, y, width, length, color, bcolor, value, maxValue)
	local pb = objects[id]
	if pb == nil or (pb[1] ~= "ProgressBar" and pb[1] ~= "VerticalProgressBar") then error("Invalid object: got "..pb[1].." expected ProgressBar or VerticalProgressBar") end
	x = x or pb[2]
	y = y or pb[3]
	width = width or pb[4]
	length = length or pb[5]
	color = color or pb[6]
	bcolor = bcolor or pb[7]
	value = value or pb[8]
	maxValue = maxValue or pb[9]
	objects[id] = {pb[1], x, y, width, length, color, bcolor, value, maxValue}
end

local function filledRect(monitor, x, y, dx, dy, color)
	monitor.setTextColor(color)
	for y, y+dy-1 do
		for x, x+dx-1 do
			monitor.setCursorPos(x,y)
			monitor.write(" ")
		end
	end
end

local function rect(monitor, x, y, dx, dy, color1, color2)
	cx, cy, cdx, cdy = x, y, dx+x-1, dy+y-1
	for y=cy, cdy do
		for x=cx, cdx do
			monitor.setCursorPos(x,y)
			if x == cx or y == cy or x = cdx or y = cdy then
				monitor.setBackgroundColor(color1)
			else
				monitor.setBackgroundColor(color2)
			end
			monitor.write(" ")
		end
	end
end

--- Draw the registered objects
-- @tparam peripheral monitor Monitor on which draw

function draw(monitor)
	if monitor == nil then error("Vous devez specifier un peripherique valide.") end
	for _, val in ipairs(objects) do
		if val[1] == "Button" then
			monitor.setTextColor(val[7])
			filledRect(val[2],val[3],val[4],val[5], val[6])
			y = val[3] + math.ceil((val[5]/2) - (table.getn(val[9])/2))
			for __, val2 in ipairs(val[9]) do
				x = val[2] + math.ceil((val[4]/2) - (val2:len()/2))
				monitor.setCursorPos(x,y)
				monitor.write(val2)
			end
		elseif val[1] == "ProgressBar" then
			filledRect(val[2],val[3],val[4],val[5], val[7])
			dvalue = val[8]/val[9]
			dx = math.floor(val[2] + (val[4]*dvalue))
			filledRect(val[2], val[3], dx, val[5], val[6])
		elseif val[1] == "VerticalProgressBar" then
			filledRect(val[2],val[3],val[4],val[5], val[7])
			dvalue = val[8]/val[9]
			dy = math.floor(val[3] + (val[5]*dvalue))
			filledRect(val[2], val[3], val[4], dy, val[6])
		end
	end
end

--- Main loop (pull events and draw)
-- @tparam peripheral monitor Monitor on which draw

function mainLoop(monitor)
	draw(monitor)
	event, side, x, y = os.pullEvent("monitor_touch")
	for _, val in ipairs(objects) do
		if val[1] == "Button" then
			if x >= val[2] and y >= val[3] then
				if x <= val[2] + val[4]-1 and y <= val[3] + val[5]-1 then
					pcall(val[8])
				end
			end
		end
	end
end

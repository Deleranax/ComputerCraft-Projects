------------
-- Simple monitor GUI API for ComputerCraft
-- @module MonitorAPI
-- @release https://pastebin.com/D325xpYJ
-- @author Deleranax

local objects = {n=0}

-- @section Declaring objects

--- Add a button
-- @tparam number x Button abscissa
-- @tparam number y Button ordinate
-- @tparam number width Button width
-- @tparam number length Button length
-- @tparam color bcolor Background color
-- @tparam color fcolor Text color
-- @tparam func f Command of the button
-- @tparam strings ... Label of the button
-- @treturn number id Object ID

function addButton(x, y, width, length, bcolor, fcolor, f, ...)
	for i, val in ipairs({x, y, width, length, bcolor, fcolor, f, arg}) do if val == nil then error("Arg#"..i.." is not optional.") end end
	table.insert(objects, {"Button", x, y, width, length, bcolor, fcolor, f, arg})
	return table.getn(objects)
end

--- Add a progress bar
-- @tparam number x Progress bar abscissa
-- @tparam number y Progress bar ordinate
-- @tparam number width Progress bar max width
-- @tparam number length Progress bar max length
-- @tparam color color Progress bar color
-- @tparam[opt=gray] color bcolor Background color
-- @tparam number value Current value
-- @tparam number maxValue Max value
-- @tparam[opt=false] bool vertical Make this bar vertical
-- @treturn number id Object ID

function addProgressBar(x, y, width, length, color, bcolor, value, maxValue, vertical)
	vertical = vertical or false
	bcolor = bcolor or colors.gray
	for i, val in ipairs({x, y, width, length, color, bcolor, value, maxValue}) do if val == nil then error("Arg#"..i.." is not optional.") end end
	if value>maxValue then error("value can't be greater than maxValue") end
	if not vertical then
		table.insert(objects, {"ProgressBar", x, y, width, length, color, bcolor, value, maxValue})
	else
		table.insert(objects, {"VerticalProgressBar", x, y, width, length, color, bcolor, value, maxValue})
	end
	return table.getn(objects)
end

--- Add a label
-- @tparam number x Label abscissa
-- @tparam number y Label ordinate
-- @tparam color color Text color
-- @tparam[opt=black] color bcolor Background color
-- @treturn number id Object ID

function addLabel(x, y, color, bcolor, ...)
	bcolor = bcolor or colors.black
	for i, val in ipairs({x, y, color, bcolor, arg}) do if val == nil then error("Arg#"..i.." is not optional.") end end
	table.insert(objects, {"Label", x, y, color, bcolor, arg})
	return table.getn(objects)
end

--- Add a container
-- @tparam number x Progress bar abscissa
-- @tparam number y Progress bar ordinate
-- @tparam number width Progress bar max width
-- @tparam number length Progress bar max length
-- @tparam color color Border color
-- @tparam[opt] color bcolor Background color
-- @tparam[opt] string label Container title
-- @treturn number id Object ID

function addContainer(x, y, width, length, color, bcolor, label)
	for i, val in ipairs({x, y, width, length, color}) do if val == nil then error("Arg#"..i.." is not optional.") end end
	table.insert(objects, {"Container", x, y, width, length, color, bcolor, label})
	return table.getn(objects)
end

-- @section Modifying objects

--- Modify button
-- @param id Object ID
-- @tparam[opt=Old value] color bcolor Background color
-- @tparam[opt=Old value] color fcolor Text color
-- @tparam[opt=Old value] func f Button command
-- @tparam[opt=Old value] string ... Button label

function modifyButton(id, bcolor, fcolor, f, ...)
	local button = objects[id]
	if button == nil or button[1] ~= "Button" then error("Invalid object: got "..button[1].." expected Button") end
	local bcolor = bcolor or button[6]
	local fcolor = bcolor or button[7]
	local f = f or button[8]
	local text = arg or button[9]
	objects[id] = {button[1], button[2], button[3], button[4], button[5], width, length, bcolor, fcolor, f, text}
end

--- Modify progress bar
-- @param id Object ID
-- @tparam[opt=Old value] color color Color of the progress bar
-- @tparam[opt=Old Value] color bcolor Color of the background
-- @tparam[opt=Old value] number value Current value
-- @tparam[opt=Old value] number maxValue Max value

function modifyProgressBar(id, color, bcolor, value, maxValue)
	local pb = objects[id]
	if pb == nil or (pb[1] ~= "ProgressBar" and pb[1] ~= "VerticalProgressBar") then error("Invalid object: got "..pb[1].." expected ProgressBar or VerticalProgressBar") end
	local color = color or pb[6]
	local bcolor = bcolor or pb[7]
	local value = value or pb[8]
	local maxValue = maxValue or pb[9]
	if value>maxValue then error("value can't be greater than maxValue") end
	objects[id] = {pb[1], pb[2], pb[3], pb[4], pb[5], color, bcolor, value, maxValue}
end

--- Set values of progress bar
-- @param id Object ID
-- @tparam[opt=Old value] number value Current value
-- @tparam[opt=Old value] number maxValue Max value

function setProgressBarValues(id, value, maxValue)
	local pb = objects[id]
	if pb == nil or (pb[1] ~= "ProgressBar" and pb[1] ~= "VerticalProgressBar") then error("Invalid object: got "..pb[1].." expected ProgressBar or VerticalProgressBar") end
	local value = value or pb[8]
	local maxValue = maxValue or pb[9]
	if value>maxValue then error("value can't be greater than maxValue") end
	objects[id] = {pb[1], pb[2], pb[3], pb[4], pb[5], pb[6], pb[7], value, maxValue}
end

--- Set text of label
-- @param id Object ID
-- @tparam string ... Label text

function setLabelText(id, ...)
	local l = objects[id]
	if l == nil or l[1] ~= "Label" then error("Invalid object: got "..l[1].." expected Label") end
	objects[id] = {l[1], l[2], l[3], l[4], l[5], arg}
end

--- Modify container
-- @param id Object ID
-- @tparam[opt=Old value] color color Border color
-- @tparam[opt=Old value] color bcolor Background color
-- @tparam[opt=Old value] string label Container title

function modifyContainer(id, color, bcolor, label)
	local c = objects[id]
	if c == nil or c[1] ~= "Container" then error("Invalid object: got "..c[1].." expected Container") end
	local color = color or c[6]
	local bcolor = bcolor or c[7]
	local label = label or c[8]
	objects[id] = {l[1], l[2], l[3], l[4], l[5], color, bcolor, label}
end

-- @section Deleting objects

--- Reset Workspace (delete all objects)

function reset()
	objects = {n=0}
end

--- Delete object
-- @param id Object ID

function delete(id)
	objects[id] = nil
end

local function filledRect(monitor, cx, cy, dx, dy, color)
	monitor.setBackgroundColor(color)
	for y=cy, (cy+dy-1) do
		for x=cx, (cx+dx-1) do
			monitor.setCursorPos(x,y)
			monitor.write(" ")
		end
	end
end

local function rect(monitor, x, y, dx, dy, color1, color2)
	local cx, cy, cdx, cdy = x, y, dx+x-1, dy+y-1
	for y=cy, cdy do
		for x=cx, cdx do
			monitor.setCursorPos(x,y)
			if x == cx or y == cy or x == cdx or y == cdy then
				monitor.setBackgroundColor(color1)
				monitor.write(" ")
			elseif color2 ~= nil then
				monitor.setBackgroundColor(color2)
				monitor.write(" ")
			end
		end
	end
end

-- @section Drawing objects

--- Draw the registered objects
-- @tparam peripheral monitor Monitor on which draw

function draw(monitor)
	local oldfcolor = monitor.getTextColor()
	local oldbcolor = monitor.getBackgroundColor()
	local oldx, oldy = monitor.getCursorPos()
	if monitor == nil then error("Vous devez specifier un peripherique valide.") end
	for _, val in ipairs(objects) do
		if val[1] == "Button" then
			monitor.setTextColor(val[7])
			filledRect(monitor, val[2],val[3],val[4],val[5], val[6])
			local y = val[3] + math.ceil((val[5]/2) - (table.getn(val[9])/2))
			for i, val2 in ipairs(val[9]) do
				local x = val[2] + math.ceil((val[4]/2) - (val2:len()/2))
				monitor.setCursorPos(x,y+i-1)
				monitor.write(val2)
			end
		elseif val[1] == "ProgressBar" then
			filledRect(monitor, val[2],val[3],val[4],val[5], val[7])
			local dvalue = val[8]/val[9]
			local dx = math.floor(val[4]*dvalue)
			filledRect(monitor, val[2], val[3], dx, val[5], val[6])
		elseif val[1] == "VerticalProgressBar" then
			filledRect(monitor, val[2],val[3],val[4],val[5], val[7])
			local dvalue = val[8]/val[9]
			local dy = math.floor(val[5]*dvalue)
			filledRect(monitor, val[2], val[3], val[4], dy, val[6])
		elseif val[1] == "Label" then
			monitor.setBackgroundColor(val[5])
			monitor.setTextColor(val[4])
			for i, val2 in ipairs(val[6]) do
				monitor.setCursorPos(val[2],val[3]+i-1)
				monitor.write(val2)
			end
		elseif val[1] == "Container" then
			rect(monitor, val[2], val[3], val[4], val[5], val[6], val[7])
			if val[8] ~= nil then
				local text = " "..val[8].." "
				local x = val[2] + math.ceil((val[4]/2) - (text:len()/2))
				monitor.setCursorPos(x, val[3])
				monitor.setBackgroundColor(oldbcolor)
				monitor.setTextColor(val[6])
				monitor.write(text)
			end
		end
	end
	monitor.setBackgroundColor(oldbcolor)
	monitor.setTextColor(oldfcolor)
	monitor.setCursorPos(oldx, oldy)
end

--- Main loop (pull events and draw)
-- @tparam peripheral monitor Monitor on which draw

function mainLoop(monitor)
	draw(monitor)
	local event, side, x, y = os.pullEvent("monitor_touch")
	for _, val in ipairs(objects) do
		if val[1] == "Button" then
			if x >= val[2] and y >= val[3] then
				if x <= val[2] + val[4]-1 and y <= val[3] + val[5]-1 then
					val[8]()
				end
			end
		end
	end
end

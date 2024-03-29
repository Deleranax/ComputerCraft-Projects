----------------------
-- Simple monitor GUI API for ComputerCraft
-- @license MIT
-- @module MonitorAPI
-- @release https://pastebin.com/D325xpYJ
-- @author Deleranax

_G.mapiObjects = {}

-- @section Declaring

--- Add a button
-- @within Declaring
-- @tparam number x Button abscissa
-- @tparam number y Button ordinate
-- @tparam number width Button width
-- @tparam number length Button length
-- @tparam color bcolor Background color
-- @tparam color fcolor Text color
-- @tparam func f Command of the button
-- @tparam strings ... Label of the button
-- @treturn number id Object ID

local function addButton(x, y, width, length, bcolor, fcolor, f, ...)
	for i, val in ipairs({x, y, width, length, bcolor, fcolor, f, arg}) do if val == nil then error("bad argument #"..i.." (got nil)") end end
	table.insert(_G.mapiObjects, {"Button", x, y, width, length, bcolor, fcolor, f, arg})
	return table.getn(_G.mapiObjects)
end

--- Add a progress bar
-- @within Declaring
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

local function addProgressBar(x, y, width, length, color, bcolor, value, maxValue, vertical)
	vertical = vertical or false
	bcolor = bcolor or colors.gray
	for i, val in ipairs({x, y, width, length, color, bcolor, value, maxValue}) do if val == nil then error("bad argument #"..i.." (got nil)") end end
	if value>maxValue then error("value can't be greater than maxValue") end
	if not vertical then
		table.insert(_G.mapiObjects, {"ProgressBar", x, y, width, length, color, bcolor, value, maxValue})
	else
		table.insert(_G.mapiObjects, {"VerticalProgressBar", x, y, width, length, color, bcolor, value, maxValue})
	end
	return table.getn(_G.mapiObjects)
end

--- Add a label
-- @within Declaring
-- @tparam number x Label abscissa
-- @tparam number y Label ordinate
-- @tparam color color Text color
-- @tparam[opt=black] color bcolor Background color
-- @treturn number id Object ID

local function addLabel(x, y, color, bcolor, ...)
	bcolor = bcolor or colors.black
	for i, val in ipairs({x, y, color, bcolor, arg}) do if val == nil then error("bad argument #"..i.." (got nil)") end end
	table.insert(_G.mapiObjects, {"Label", x, y, color, bcolor, arg})
	return table.getn(_G.mapiObjects)
end

--- Add a container
-- @within Declaring
-- @tparam number x Progress bar abscissa
-- @tparam number y Progress bar ordinate
-- @tparam number width Progress bar max width
-- @tparam number length Progress bar max length
-- @tparam color color Border color
-- @tparam[opt] color bcolor Background color
-- @tparam[opt] string label Container title
-- @treturn number id Object ID

local function addContainer(x, y, width, length, color, bcolor, label)
	for i, val in ipairs({x, y, width, length, color}) do if val == nil then error("bad argument #"..i.." (got nil)") end end
	table.insert(_G.mapiObjects, {"Container", x, y, width, length, color, bcolor, label})
	return table.getn(_G.mapiObjects)
end

-- @section Modifying

--- Modify button ; make arguments nil to keep old values
-- @within Modifying
-- @param id Object ID
-- @tparam[opt] color bcolor Background color
-- @tparam[opt] color fcolor Text color
-- @tparam[opt] func f Button command
-- @tparam[opt] string ... Button label

local function modifyButton(id, bcolor, fcolor, f, ...)
	local button = _G.mapiObjects[id]
	if button == nil or button[1] ~= "Button" then error("invalid object: got "..button[1].." expected Button") end
	local bcolor = bcolor or button[6]
	local fcolor = fcolor or button[7]
	local f = f or button[8]
	local text = arg or button[9]
	_G.mapiObjects[id] = {button[1], button[2], button[3], button[4], button[5], bcolor, fcolor, f, text}
end

--- Modify progress bar ; make arguments nil to keep old values
-- @within Modifying
-- @param id Object ID
-- @tparam[opt] color color Color of the progress bar
-- @tparam[opt] color bcolor Color of the background
-- @tparam[opt] number value Current value
-- @tparam[opt] number maxValue Max value

local function modifyProgressBar(id, color, bcolor, value, maxValue)
	local pb = _G.mapiObjects[id]
	if pb == nil or (pb[1] ~= "ProgressBar" and pb[1] ~= "VerticalProgressBar") then error("invalid object: got "..pb[1].." expected ProgressBar or VerticalProgressBar") end
	local color = color or pb[6]
	local bcolor = bcolor or pb[7]
	local value = value or pb[8]
	local maxValue = maxValue or pb[9]
	if value>maxValue then error("value can't be greater than maxValue") end
	_G.mapiObjects[id] = {pb[1], pb[2], pb[3], pb[4], pb[5], color, bcolor, value, maxValue}
end

--- Set values of progress bar ; make arguments nil to keep old values
-- @within Modifying
-- @param id Object ID
-- @tparam[opt] number value Current value
-- @tparam[opt] number maxValue Max value

local function setProgressBarValues(id, value, maxValue)
	local pb = _G.mapiObjects[id]
	if pb == nil or (pb[1] ~= "ProgressBar" and pb[1] ~= "VerticalProgressBar") then error("invalid object: got "..pb[1].." expected ProgressBar or VerticalProgressBar") end
	local value = value or pb[8]
	local maxValue = maxValue or pb[9]
	if value>maxValue then error("value can't be greater than maxValue") end
	_G.mapiObjects[id] = {pb[1], pb[2], pb[3], pb[4], pb[5], pb[6], pb[7], value, maxValue}
end

--- Set text of label
-- @within Modifying
-- @param id Object ID
-- @tparam string ... Label text

local function setLabelText(id, ...)
	local l = _G.mapiObjects[id]
	if l == nil or l[1] ~= "Label" then error("invalid object: got "..l[1].." expected Label") end
	_G.mapiObjects[id] = {l[1], l[2], l[3], l[4], l[5], arg}
end

--- Modify container ; make arguments nil to keep old values
-- @within Modifying
-- @param id Object ID
-- @tparam[opt] color color Border color
-- @tparam[opt] color bcolor Background color
-- @tparam[opt] string label Container title

local function modifyContainer(id, color, bcolor, label)
	local c = _G.mapiObjects[id]
	if c == nil or c[1] ~= "Container" then error("invalid object: got "..c[1].." expected Container") end
	local color = color or c[6]
	local bcolor = bcolor or c[7]
	local label = label or c[8]
	_G.mapiObjects[id] = {l[1], l[2], l[3], l[4], l[5], color, bcolor, label}
end

-- @section Deleting

--- Reset Workspace (delete all _G.mapiObjects)
-- @within Deleting

local function reset()
	_G.mapiObjects = {}
end

--- Delete object
-- @within Deleting
-- @param id Object ID

local function delete(id)
	_G.mapiObjects[id] = nil
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

-- @section Drawing

--- Draw the registered _G.mapiObjects
-- @within Drawing
-- @tparam peripheral monitor Monitor on which draw

function draw(monitor)
	ok = pcall(monitor.clear)
	if not ok then error("Invalid peripheral.") end
	local oldfcolor = monitor.getTextColor()
	local oldbcolor = monitor.getBackgroundColor()
	local oldx, oldy = monitor.getCursorPos()
	for _, val in ipairs(_G.mapiObjects) do
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
-- @within Drawing
-- @tparam peripheral monitor Monitor on which draw

function mainLoop(monitor)
	draw(monitor)
	local event, side, x, y = os.pullEvent("monitor_touch")
	for _, val in ipairs(_G.mapiObjects) do
		if val[1] == "Button" then
			if x >= val[2] and y >= val[3] then
				if x <= val[2] + val[4]-1 and y <= val[3] + val[5]-1 then
					val[8]()
				end
			end
		end
	end
end

return {addButton = addButton, addContainer = addContainer, addLabel = addLabel, addProgressBar = addProgressBar, modifyButton = modifyButton, modifyContainer = modifyContainer, modifyProgressBar = modifyProgressBar, setLabelText = setLabelText, setProgressBarValues = setProgressBarValues, delete = delete, draw = draw, reset = reset, mainLoop = mainLoop}
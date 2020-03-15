------------
-- Simple monitor GUI API for ComputerCraft
-- (LDoc)
-- @module MonitorAPI
-- @author Deleranax

local objects = {n=0}


--- Ajouter un bouton
-- @tparam number x Abscissa of the button
-- @tparam number y Ordinate of the button
-- @tparam number width Width of the button
-- @tparam number height Height of the button
-- @tparam color bcolor Color of the button (background)
-- @tparam color fcolor Color of the button (text)
-- @tparam func f Command of the button
-- @tparam string ... Label of the button
-- @treturn number id ID of the button

function addButton(x, y, width, height, bcolor, fcolor, f, ...)
	for i, val in ipairs({x, y, width, height, bcolor, fcolor, f, arg}) do if val == nil then error("Arg#"..i.." n'est pas optionnel.") end end
	table.insert(objects, {"Button", x, y, width, height, bcolor, fcolor, f, arg})
	return table.getn(objects)
end

--- Modifier un bouton
-- @param id ID de l'objet
-- @tparam[opt=Old Value] number x Abscissa of the button
-- @tparam[opt=Old Value] number y Ordinate of the button
-- @tparam[opt=Old Value] number width Width of the button
-- @tparam[opt=Old Value] number height Height of the button
-- @tparam[opt=Old Value] color bcolor Color of the button (background)
-- @tparam[opt=Old Value] color fcolor Color of the button (text)
-- @tparam[opt=Old Value] func f Command of the button
-- @tparam[opt=Old Value] string ... Label of the button
-- @treturn number id ID of the button

function modifyButton(id, x, y, width, height, bcolor, fcolor, f, ...)
	local button = objects[id]
	if button == nil then error("ID non valide.") end
	x = x or button[2]
	y = y or button[3]
	width = width or button[4]
	height = height or button[5]
	bcolor = bcolor or button[6]
	fcolor = bcolor or button[7]
	f = f or button[8]
	text = arg or button[9]
	objects[id] = {"Button", x, y, width, height, bcolor, fcolor, f, text}
end


--- Draw the registered objects
-- @tparam peripheral monitor Monitor on which draw

function draw(monitor)
	if monitor == nil then error("Vous devez specifier un peripherique valide.") end
	for _, val in ipairs(objects) do
		if val[1] == "Button" then
			monitor.setBackgroundColor(val[6])
			monitor.setTextColor(val[7])
			for y=val[3], val[3]+val[5]-1 do
				for x=val[2], val[2]+val[4]-1 do
					monitor.setCursorPos(x,y)
					monitor.write(" ")
				end
			end
			y = val[3] + math.ceil((val[5]/2) - (table.getn(val[9])/2))
			for __, val2 in ipairs(val[9]) do
				x = val[2] + math.ceil((val[4]/2) - (val2:len()/2))
				monitor.setCursorPos(x,y)
				monitor.write(val2)
			end
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

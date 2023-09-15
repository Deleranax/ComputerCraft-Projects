----------------------
-- Simple message script for ComputerCraft
-- @license MIT
-- @module console-api
-- @author Deleranax

--- Define a title
-- @tparam string title Title

local function setTitle(title)
   prog = title
end

--- Initialize GUI

local function init()
	popup("", "m")
	term.setCursorPos(1,2)
	_G.consoleTemp = {x=1,y=2}
end

local function savePos()
	sx,sy = term.getCursorPos()
	_G.consoleTemp = {x=sx,y=sy}
end

local function restorePos()
	term.setCursorPos(_G.consoleTemp.x,_G.consoleTemp.y)
end

local function drawHeader()
	back = term.getBackgroundColor()
		x,y = term.getCursorPos()
		term.setCursorPos(1,1)
		term.setBackgroundColor(512)	
		write(prog.." - (c) Temver Inc.															        ")
		term.setBackgroundColor(back)
		term.setCursorPos(x,y)
end

local function ms(message, mode)
	 popup(message, mode)
end

--- Draw a message
-- @alias ms
-- @tparam string message
-- @tparam[opt=m] string mode Mode of the message (can be 'm', 'a' or 'e')

local function popup(message, mode)
	restorePos()
	mode = mode or "m"
	term.setTextColor(32768)
	local x,y = term.getSize()
	if mode == "m" then
		term.setBackgroundColor(1)
		term.clear()
		drawHeader()
		term.setCursorPos(math.ceil((x / 2) - (message:len() / 2)), 9)
		write(message)
	elseif mode == "a" then
		term.setBackgroundColor(2)
		term.clear()
		drawHeader()
		term.setCursorPos(math.ceil((x / 2) - (message:len() / 2)), 9)
		write(message)
	elseif mode == "e" then
		term.setBackgroundColor(16384)
		term.clear()
		drawHeader()
		term.setCursorPos(math.ceil((x / 2) - (message:len() / 2)), 9)
		write(message)
	end
	savePos()
end

--- Draw a message in console
-- @tparam string string Message
-- @tparam[opt="m"] string mode Mode of the message (can be "m" for message, "a" for advert, "e" for error)

local function console(string, mode)
	restorePos()
	mode = mode or "m"
	term.setBackgroundColor(1)
	term.setTextColor(32768)
	local date = os.date("%T")
	if mode == "m" then
		print("["..date.."] "..string)
	term.setBackgroundColor(1)
	elseif mode == "a" then
		term.setBackgroundColor(2)
		print("["..date.."] "..string)
	term.setBackgroundColor(1)
	elseif mode == "e" then
		term.setBackgroundColor(16384)
		print("["..date.."] "..string)
	term.setBackgroundColor(1)
	end
	drawHeader()
	savePos()
end

--- Log message in file
-- @tparam string log Message

local function log(log)
	if fs.exists("Logs") then
		local sfile = fs.open("Logs", "r")
		local plm = sfile.readAll()
		sfile.close()
		local sfile = fs.open("Logs", "w")
		sfile.write(plm.."\n")
		sfile.writeLine(log)
		sfile.close()
	else
		local sfile = fs.open("Logs", "w")
		sfile.writeLine("Starting of Logs")
		sfile.close()
	end
end

--- Draw a message in console and log it
-- @tparam string string Message
-- @tparam[opt="m"] string mode Mode of the message (can be "m" for message, "a" for advert, "e" for error)

local function loggedConsole(string, mode)
	restorePos()
	mode = mode or "m"
	term.setBackgroundColor(1)
	term.setTextColor(32768)
	local time = os.date("%T")
	local date = os.date("%D %T")
	if mode == "m" then
		 print("["..time.."] "..string)
		 log("["..date.."] "..string)
		 term.setBackgroundColor(1)
	elseif mode == "a" then
		 term.setBackgroundColor(2)
		 print("["..time.."] "..string)
		 log("["..date.."] Warning : "..string)
		 term.setBackgroundColor(1)
	elseif mode == "e" then
		 term.setBackgroundColor(16384)
		 print("["..time.."] "..string)
		 log("["..date.."] Error : "..string)
		 term.setBackgroundColor(1)
	end
	drawHeader()
	savePos()
end

local function input()
	x, y = term.getSize()
	setCursorPos(1,y)
	write("> ")
	rtn = read()
	setCursorPos(1,y)
	write(">                                                                    ")
	return rtn
end

return {setTitle = setTitle, init = init, popup = popup, console = console, log = log, loggedConsole = loggedConsole, input = input}
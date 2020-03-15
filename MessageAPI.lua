------------
-- Simple message script for ComputerCraft
-- @module MessageAPI
-- @release https://pastebin.com/umGH65FP
-- @author Deleranax

ts = peripheral.wrap("timeSensor_1")

--- Define a title
-- @tparam string title Title

function setTitle(title)
   prog = title
end

local function gDate()
	ok = pcall(ts.getDate)
	if not ok then d = os.day() else d = ts.getDate()["day"].."/"..ts.getDate()["month"].." "..ts.getDate()["hour"]..":"..ts.getDate()["minute"] end
	return d
end

--- Initialize GUI

function init()
	popup("", "m")
	term.setCursorPos(1,2)
end

local function drawHeader()
	back = term.getBackgroundColor()
		x,y = term.getCursorPos()
		term.setCursorPos(1,1)
		term.setBackgroundColor(512)	
		write(prog.." - (c) Temver Inc.															 ")
		term.setBackgroundColor(back)
		term.setCursorPos(x,y)
end

function ms(message, mode)
	 popup(message, mode)
end

--- Draw a message
-- @alias ms
-- @tparam string message
-- @tparam[opt=m] string mode Mode of the message (can be 'm', 'a' or 'e')

function popup(message, mode)
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
		sleep(3)
		os.reboot()
	end
end

--- Draw a message in console
-- @tparam string string Message
-- @tparam[opt="m"] string mode Mode of the message (can be "m" for message, "a" for advert, "e" for error)

function console(string, mode)
	mode = mode or "m"
	term.setBackgroundColor(1)
	term.setTextColor(32768)
	local date = gDate()
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
end

--- Log message in file
-- @tparam string log Message

function log(log)
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

function loggedConsole(string, mode)
	mode = mode or "m"
	term.setBackgroundColor(1)
	term.setTextColor(32768)
	local date = gDate()
	if mode == "m" then
		 print("["..date.."] "..string)
		 log("["..date.."] "..string)
		 term.setBackgroundColor(1)
	elseif mode == "a" then
		 term.setBackgroundColor(2)
		 print("["..date.."] "..string)
		 log("["..date.."] Warning : "..string)
		 term.setBackgroundColor(1)
	elseif mode == "e" then
		 term.setBackgroundColor(16384)
		 print("["..date.."] "..string)
		 log("["..date.."] Error : "..string)
		 term.setBackgroundColor(1)
	end
	drawHeader()
end
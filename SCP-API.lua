------------
-- Secure Communication Protocol API for ComputerCraft
-- @see HashAPI
-- @module Secure-Communication-Protocol
-- @release https://pastebin.com/5wZVe9wZ
-- @alias scp
-- @author Deleranax

if not os.loadAPI("HashAPI") then
	error("HashAPI is required.")
end

local function checkModem()
	mod = false
	for _, side in pairs(rs.getSides()) do
  		if peripheral.isPresent(side) and peripheral.getType(side) == "modem" and rednet.isOpen(side, "isWireless") then
			mod = true
		end
	end
	if not mod then
		log("No opened modem.", "e")
		error("No opened modem.")
	end
end

--- Change password
-- @tparam string p New password

function setPass(p)
	pass = p
end

--- Enable/Disable verbose
-- @tparam bool mode 
-- @see MessageAPI

function setConsole(mode)
	console = mode
	if console then
		if not os.loadAPI("MessageAPI") then
			error("MessageAPI is required.")
		end
		MessageAPI.setTitle("SCP")
	end
end

local function log(message, mode)
	if console == true then
		MessageAPI.loggedConsole(message, mode)
	else
		MessageAPI.log(message, mode)
	end
end

--- Set Host ID
-- @tparam number nb ID of the host

function setHostId(nb)
	hostId = tonumber(nb)
end

--- Send message through SCP communication
-- @tparam[opt] number id ID of the receiver (Server Only)
-- @treturn bool Status (receive, timed out)

function send(...)
	if host == nil then
		log("Attempt to receive without a initied communication", "e")
		error("SCP communication not initied.")
	end
	if host then
		id = table.remove(arg, 1)
		data = textutils.serialize({HashAPI.sha256(id..""..pass..""..os.getComputerID()), arg})
		rednet.send(id, data, "SCP")
		sender, message = rednet.receive("SCP", 5)
		if sender == nil or sender ~= id then
			log("ID"..id.." timed out.", "a")
			log("ID"..id.." disconnected.", "a")
			return false
		else
			return true
		end
	else
		data = textutils.serialize({HashAPI.sha256(hostId..""..pass..""..os.getComputerID()), arg})
		rednet.send(hostId, data, "SCP")
		sender, message = rednet.receive("SCP", 5)
		if sender == nil or sender ~= hostId then
			log("ID"..hostId.." timed out.", "a")
			host = nil
			log("Client connections closed.", "a")
			return false
		else
			return true
		end
	end
end

--- Receive message through
-- @tparam[opt=nil] number timeout Maximum waiting time
-- @treturn nil|table Return the message or nil if nothing has been received (or if the format/password is invalid)
-- @warning Will return the Service Messages (PING, PONG, CLOSE...)

function receive(timeout)
	if host == nil then
		log("Attempt to receive without a initied communication", "e")
		error("SCP communication not initied.")
	end
	sender, message = rednet.receive("SCP", timeout)
	if sender == nil then
		return nil
	else
		message = textutils.unserialize(message)
		log("Receive packet from ID"..sender, "m")
		for i, val in pairs(trustedComputers) do
			if HashAPI.sha256(os.getComputerID()..""..val[2]..""..val[1]) == message[1] then
				if message[2][1] == "PING" and host then
					data = textutils.serialize({HashAPI.sha256(sender..""..pass..""..os.getComputerID()), "PONG"})
					rednet.send(sender, data, "SCP")
					log("ID"..sender.." connected.", "m")
				elseif message[2][1] == "PING" and not host then
					data = textutils.serialize({HashAPI.sha256(sender..""..pass..""..os.getComputerID()), "PONG"})
					rednet.send(data, "SCP")
				elseif message[2][1] == "CLOSE" and host then
					log("ID"..sender.." disconnected.", "m")
					data = textutils.serialize({HashAPI.sha256(sender..""..pass..""..os.getComputerID()), "PONG"})
					rednet.send(sender, data, "SCP")
				elseif message[2][1] ~= "PONG" and host then
					data = textutils.serialize({HashAPI.sha256(sender..""..pass..""..os.getComputerID()), "PONG"})
					rednet.send(sender, data, "SCP")
				elseif message[2][1] ~= "PONG" and not host then
					data = textutils.serialize({HashAPI.sha256(sender..""..pass..""..os.getComputerID()), "PONG"})
					rednet.send(data, "SCP")
				end
				return sender, message[2]
			end
		end
		log("Invalid suspicious packet from ID"..sender, "a")
		return nil
	end
end

--- Add trusted ID
-- @tparam number  id ID of the computer
-- @tparam string p Password

function addTrusted(id, p)
	if trustedComputers == nil then trustedComputers = {} end
	log("Adding ID"..id.." to trusted devices.", "m")
	table.insert(trustedComputers, {id, p})
end

--- Initialize a server
-- @tparam string name Host name
-- @tparam string pass Password

function initHost(name, pass)
	if trustedComputers == nil then trustedComputers = {} end
	checkModem()
	if host ~= nil then
		log("Host already initied.", "e")
		error("Host already initied.")
	end
	log("Initiating SCP connection...", "m")
	setHostId(os.getComputerID())
	setPass(pass)
	rednet.host("SCP", name)
	hostName = name
	host = true
	log("Socket initied for "..name.." (ID"..hostId..") over SCP.", "m")
	log("Host initied.", "m")
	return true
end

--- Close connections

function close()
	if host == nil then
		log("Attempt to close without a initied communication", "e")
		error("SCP communication not initied.")
	end
	if host then
		host = nil
		rednet.unhost("SCP", hostName)
		log("Host connections closed.", "m")
	else
		send("CLOSE")
		host = nil
		log("Client connections closed.", "m")
	end
end

--- Initialize a client connection
-- @tparam number hostId ID of the host
-- @tparam string p Password

function initClient(hostId, p)
	if trustedComputers == nil then trustedComputers = {} end
	checkModem()
	if host ~= nil then
		log("Client already initied.", "e")
		error("Client already initied.")
	end
	host = false
	log("Attempt to initiate a connection...", "m")		
	setHostId(hostId)
	setPass(p)
	addTrusted(hostId, p)
	if send("PING") then
		log("Connected to ID"..hostId.." over SCP.", "m")
		log("Client initied.", "m")
		return true
	else
		host = nil
		log("Can't resolve host ID"..hostId, "a")
		return false
	end
end

--- Search a server by host name
-- @tparam string hname Host name
-- @treturn nil|number Number of the host (nil if unreachable)

function hostLookUp(hname)
	return rednet.lookup("SCP", hname)
end
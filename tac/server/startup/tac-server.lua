local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local req = require("/apis/tac-request")
local com = require("/apis/tac-server-command")

local present = false
for _, side in pairs(rs.getSides()) do
    if peripheral.getType(side) == "modem" then
        present = true
        rednet.open(side)
    end
end

if not present then
    error("A modem was not found, please attach one and re-run this program")
end

_G["tacServerTemp"] = {undergoingCom = false, comID = nil, comDest = nil, active = true, state = "Idle", userInput = false}

vui.setVendor("TAC SERVER - © TEMVER INCORPORATED")
vui.setUpMessage("")

local command, args, status, message, sender, dest, id

local function backendLoop()
    if _G.tacServerTemp.state == "Idle" then
        status, message, sender, dest, id = tac.secureReceive()
    end

    _G.tacServerTemp.userInput = false
end

local function commandLoop()
    command, args = vui.consoleInput()
    _G.tacServerTemp.userInput = true
end

local function process()
    if _G.tacServerTemp.userInput then
        com(command, args)
    else
        if dest ~= nil and dest ~= os.getComputerID() then
            vui.consoleLog("Ignored message from "..tostring(sender).." via "..tostring(sender).." for "..tostring(dest))
        end
        if status == 130 then
            vui.consoleLog("Incoming communication initiation request from "..tostring(sender).." via "..tostring(id))
            _G.tacServerTemp.comID = id
            _G.tacServerTemp.comDest = sender
            _G.tacServerTemp.undergoingCom = true
        elseif status ~= 0 then
            vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
            return
        else
            vui.consoleLog("Processing request from "..tostring(sender).." via "..tostring(id))
            local e, userHash = tac.decryptFrom(message[1], sender)

            if e ~= 0 then
                vui.consoleLog("Error "..tostring(e)..": "..tostring(userHash))
                local e, mess = tac.secureSend(id, {error=400}, sender)
                if e == 0 then
                    return
                end
                return
            end

            local e, code tac.decryptFrom(message[2], sender)

            if e ~= 0 then
                vui.consoleLog("Error "..tostring(e)..": "..tostring(code))
                local e, mess = tac.secureSend(id, {error=400}, sender)
                if e == 0 then
                    return
                end
                return
            end

            if not _G.tacTemp.database.users[userHash] then
                vui.consoleLog("Refused: Unregistered user")
                local e, mess = tac.secureSend(id, {error=401}, sender)
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end

            local localUser = _G.tacTemp.database.users[userHash]

            local e, h = tac.hash(code)

            if e ~= 0 then
                vui.consoleLog("Error "..tostring(e)..": "..tostring(h))
                local e, mess = tac.secureSend(id, {error=400}, sender)
                if e == 0 then
                    return
                end
                return
            end

            if not localUser.passHash ~= h then
                vui.consoleLog("Refused: Wrong credentials")
                local e, mess = tac.secureSend(id, {error=401})
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end
            table.remove(message, 1)
            table.remove(message, 1)
            return req(message)
        end
    end
end

_G.tacServerTemp.state = vui.printConsoleStatus("Initialisation")

vui.consoleLog("Initialisation...")

status, message = tac.initialise()

if not _G.tacTemp.database.users then
    _G.tacTemp.database.users = {}
end

if status ~= 0 then
    vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
end

vui.consoleLog("Done.")

_G.tacServerTemp.state = vui.printConsoleStatus("Idle")

while _G.tacServerTemp.active do
    parallel.waitForAny(backendLoop, commandLoop)

    _G.tacServerTemp.state = vui.printConsoleStatus("Busy")

    process()

    _G.tacServerTemp.state = vui.printConsoleStatus("Idle")
    command, args, status, message, sender, dest, id = nil
end

tac.saveDatabase()
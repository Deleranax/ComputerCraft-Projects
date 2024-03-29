local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local req = require("/apis/tac-server-request")
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

_G["tacServerTemp"] = {undergoingCom = false, comID = nil, comDest = nil, active = true, userInput = false}

vui.setVendor("TAC SERVER - © TEMVER INCORPORATED")
vui.setUpMessage("")

local command, args, status, message, sender, dest, id

local function backendLoop()
    if vui.getStatus() == "Idle" then
        status, message, sender, dest, id = tac.secureReceive(300)
    end

    if status == 91 then
        status, message =  tac.saveDatabase()

        if status ~= 0 then
            vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
        end

        backendLoop()
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

        status, message =  tac.saveDatabase()

        if status ~= 0 then
            vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
        end
    else
        if dest ~= nil and dest ~= os.getComputerID() then
            vui.consoleLog("Ignored message from ID"..tostring(sender).." via ID"..tostring(sender).." for ID"..tostring(dest))
        end
        if status == 42 then

        elseif status == 130 then
            vui.consoleLog("Incoming communication initiation request from ID"..tostring(sender).." via ID"..tostring(id))
            _G.tacServerTemp.comID = id
            _G.tacServerTemp.comDest = sender
            _G.tacServerTemp.undergoingCom = true
        elseif status ~= 0 then
            vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
            return
        else
            vui.consoleLog("Processing request from ID"..tostring(sender).." via ID"..tostring(id))
            local e, userHash = tac.client.decryptFrom(message[1], sender)

            if e ~= 0 then
                vui.consoleLog("Error "..tostring(e)..": "..tostring(userHash))
                local e, mess = tac.secureSend(id, {code=400}, sender)
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end

            local e, code = tac.client.decryptFrom(message[2], sender)

            if e ~= 0 then
                vui.consoleLog("Error "..tostring(e)..": "..tostring(code))
                local e, mess = tac.secureSend(id, {code=400}, sender)
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end

            if not _G.tacTemp.database.users[userHash] then
                vui.consoleLog("Refused: Unregistered user")
                local e, mess = tac.secureSend(id, {code=401}, sender)
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end

            local localUser = _G.tacTemp.database.users[userHash]

            local e, h = tac.client.hash(code)

            if e ~= 0 then
                vui.consoleLog("Error "..tostring(e)..": "..tostring(h))
                local e, mess = tac.secureSend(id, {code=400}, sender)
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end

            if localUser.code ~= h then
                vui.consoleLog("Refused: Wrong credentials")
                local e, mess = tac.secureSend(id, {code=401}, sender)
                if e == 0 then
                    return
                end
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end
            table.remove(message, 1)
            table.remove(message, 1)
            return req(userHash, message, id, sender)
        end
    end
end

vui.setStatus("Init")

vui.consoleLog("Initialisation...")

status, message = tac.initialise()

if not _G.tacTemp.database.users then
    _G.tacTemp.database.users = {}
end

if not _G.tacTemp.database.actions then
    _G.tacTemp.database.actions = {}
end

if status ~= 0 then
    vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
end

vui.consoleLog("Done.")

vui.setStatus("Idle")

while _G.tacServerTemp.active do
    vui.setStatus("Idle")

    parallel.waitForAny(backendLoop, commandLoop)

    vui.setStatus("Busy")

    process()

    vui.setStatus("Idle")
    command, args, status, message, sender, dest, id = nil
end

tac.saveDatabase()
local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local tpm = require("/apis/tpm")
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

_G["tacServerTemp"] = {undergoingCom = false, comID = nil, comDest = nil}

vui.setVendor("TAC SERVER - © TEMVER INCORPORATED")
vui.setUpMessage("")

local active = true
local userInput = false
local state
local command, args, status, message, sender, dest, id

local function backendLoop()
    if state == "Idle" then
        status, message, sender, dest, id = tac.secureReceive()
    end

    userInput = false
end

local function commandLoop()
    command, args = vui.consoleInput()
    userInput = true
end

local function process()
    if userInput then
        if command == "accept" then
            if not _G.tacServerTemp.undergoingCom then
                vui.console("There is no communication initiation waiting for approval.")
            else
                status, message =  tac.confirmCommunication(_G.tacServerTemp.comID, tostring(args[1]), _G.tacServerTemp.comDest)
                if status == 0 then
                    vui.consoleLog("Communication initiation successfully confirmed for "..tostring(_G.tacServerTemp.comDest).." via ".._G.tacServerTemp.comID)
                    _G.tacServerTemp.undergoingCom = false
                else
                    vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
                    _G.tacServerTemp.undergoingCom = false
                end
            end
        elseif command == "exit" then
            tac.saveDatabase()
            active = false
            term.clear()
            term.setCursorPos(1,1)
        elseif command == "reboot" then
            tac.saveDatabase()
            active = false
            os.reboot()
        elseif command == "update" then
            tac.saveDatabase()
            active = false
            term.clear()
            term.setCursorPos(1,1)
            tpm.updateDatabase()
            local update = 0
            local installed = 0
            for k, v in pairs(tpm.getInstalledPackages()) do
                if (tpm.get(k) == nil) then
                    print(k .. " is no longer available, skipping.")
                elseif v.version ~= tpm.get(k)["version"] then
                    update = update + 1
                    print("\nUpdating " .. k .. "...")
                    tpm.remove(k, true)
                    installed = installed + tpm.install(k, args[2] == "-force") - 1
                end
            end
            if update == 0 then
                print("All packages are up to date.")
                return
            end
            print(update .. " upgraded, " .. installed .. " newly installed.")
            sleep(5)
            os.reboot()
        end
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

            vui.console(tostring(message[3]))
        end
    end
end

state = vui.printConsoleStatus("Initialisation")

vui.consoleLog("Initialisation...")

status, message = tac.initialise()

if not _G.tacTemp.database.users then
    _G.tacTemp.database.users = {}
end

if status ~= 0 then
    vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
end

vui.consoleLog("Done.")

state = vui.printConsoleStatus("Idle")

while active do
    parallel.waitForAny(backendLoop, commandLoop)

    state = vui.printConsoleStatus("Busy")

    process()

    state = vui.printConsoleStatus("Idle")
    command, args, status, message, sender, dest, id = nil
end

tac.saveDatabase()
local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")

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

state = vui.printConsoleStatus("Initialisation")

vui.consoleLog("Initialisation...")

status, message = tac.initialise()

if status ~= 0 then
    vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
end

vui.consoleLog("Done.")

state = vui.printConsoleStatus("Idle")

while active do
    parallel.waitForAny(backendLoop, commandLoop)

    state = vui.printConsoleStatus("Busy")
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
            active = false
            term.clear()
            term.setCursorPos(1,1)
        end
    else
        if dest ~= nil and dest ~= os.getComputerID() then
            vui.consoleLog("Ignored message from "..tostring(sender).." via "..tostring(sender).." for "..tostring(dest))
        end
        if status == 130 then
            vui.consoleLog("Incoming communication initiation request from "..tostring(sender).." via "..tostring(id))
            _G.tacServerTemp.comID = id
            _G.tacServerTemp.comDest = dest
            _G.tacServerTemp.undergoingCom = true
        elseif status ~= 0 then
            vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
        end
    end

    state = vui.printConsoleStatus("Idle")
    command, args, status, message, sender, dest, id = nil
end
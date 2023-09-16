local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")

_G["tacServerTemp"] = {comID = nil, comDest = nil}

vui.setVendor("TEMVER ACCESS CONTROL SERVER - © TEMVER INCORPORATED")
vui.setUpMessage("")

local active = true
local state = vui.printConsoleStatus("Idle")
local userInput = false
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

while active do
    parallel.waitForAny(backendLoop, commandLoop)

    state = vui.printConsoleStatus("Busy")
    if userInput then
        if command == "accept" then
            status, message =  tac.confirmCommunication(_G.tacServerTemp.comID, tostring(args[1]), _G.tacServerTemp.comDest)
            if status == 0 then
                vui.consoleLog("Communication initiation successfully confirmed for "..tostring(_G.tacServerTemp.comDest).." via ".._G.tacServerTemp.comID)
            else
                vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
            end
        end
    else
        if dest ~= nil and dest ~= os.getComputerID() then
            vui.consoleLog("Ignored message from "..tostring(sender).." via "..tostring(sender).." for "..tostring(dest))
        end
        if status == 130 then
            vui.consoleLog("Incoming communication initiation request from "..tostring(sender).." via "..tostring(id))
            vui.console("Type 'accept <passcode>' confirm")
        elseif status ~= 0 then
            vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
        end
    end

    state = vui.printConsoleStatus("Idle")
    command, args, r1, r2, r3, r4, r5 = nil
end
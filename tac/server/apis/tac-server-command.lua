local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local tpm = require("/apis/tpm-api")

local function com(command, args)
    if command == "accept" then
        if not _G.tacServerTemp.undergoingCom then
            vui.console("There is no communication initiation waiting for approval.")
        else
            local status, message =  tac.confirmCommunication(_G.tacServerTemp.comID, tostring(args[1]), _G.tacServerTemp.comDest)
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
        _G.tacServerTemp.active = false
        term.clear()
        term.setCursorPos(1,1)
    elseif command == "reboot" then
        tac.saveDatabase()
        _G.tacServerTemp.active = false
        os.reboot()
    elseif command == "update" then
        tac.saveDatabase()
        _G.tacServerTemp.active = false
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
        else
            print(update .. " upgraded, " .. installed .. " newly installed.")
        end
        sleep(5)
        os.reboot()
    end
end

return com
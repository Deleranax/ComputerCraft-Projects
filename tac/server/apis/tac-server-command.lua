local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local tpm = require("/apis/tpm-api")

local function com(command, args)
    if command == "help" then
        vui.console("-- Usage --")
        vui.console("accept <passcode>")
        vui.console("doubt <id>")
        vui.console("action <update/remove> <name> [perm] [id] [dest]")
        vui.console("actions")
        vui.console("perm <user> [level]")
        vui.console("user <update/remove> <username> <passcode>")
        vui.console("users")
        vui.console("update")
        vui.console("clear")
        vui.console("reboot")
        vui.console("exit")
        vui.console("-- Usage --")
        return
    elseif command == "accept" then
        if not _G.tacServerTemp.undergoingCom then
            vui.console("There is no communication initiation waiting for approval.")
            return
        else
            local status, message =  tac.confirmCommunication(_G.tacServerTemp.comID, tostring(args[1]), _G.tacServerTemp.comDest)
            if status == 0 then
                vui.consoleLog("Communication initiation successfully confirmed for ID"..tostring(_G.tacServerTemp.comDest).." via ID".._G.tacServerTemp.comID)
                _G.tacServerTemp.undergoingCom = false
                return
            else
                vui.consoleLog("Error "..tostring(status)..": "..tostring(message))
                _G.tacServerTemp.undergoingCom = false
                return
            end
        end
    elseif command == "doubt" then
        local id = tonumber(args[1])

        if type(id) == "number" then
            local e, mess = tac.doubt(id)
            if e ~= 0 then
                vui.console("Error "..tostring(e)..": "..tostring(mess))
                return
            end
            vui.log("Doubting ID"..id)
            vui.console("Successfully flagged host as unverified")
            return
        end
    elseif command == "exit" then
        tac.saveDatabase()
        _G.tacServerTemp.active = false
        term.clear()
        term.setCursorPos(1,1)
        return
    elseif command == "clear" then
        term.clear()
        vui.console("Cleared")
        return
    elseif command == "reboot" then
        tac.saveDatabase()
        _G.tacServerTemp.active = false
        os.reboot()
        return
    elseif command == "update" then
        tac.saveDatabase()
        _G.tacServerTemp.active = false
        tpm.updateDatabase()
        local update = 0
        local installed = 0
        for k, v in pairs(tpm.getInstalledPackages()) do
            if (tpm.get(k) == nil) then
                vui.console(k .. " is no longer available, skipping.")
            elseif v.version ~= tpm.get(k)["version"] then
                update = update + 1
                vui.console("\nUpdating " .. k .. "...")
                tpm.remove(k, true)
                installed = installed + tpm.install(k, args[2] == "-force") - 1
            end
        end
        if update == 0 then
            vui.console("All packages are up to date.")
        else
            vui.console(update .. " upgraded, " .. installed .. " newly installed.")
        end
        sleep(5)
        os.reboot()
        return
    elseif command == "user" then
        if args[1] == "update" then
            local name = args[2]
            local passcode = args[3]

            if type(name) == "string" and type(passcode) == "string" then
                local e, hashName = tac.client.hash(name)

                if e ~= 0 then
                    vui.console("Error "..tostring(e)..": "..tostring(hashName))
                    return
                end

                local e, hashCode = tac.client.hash(passcode)

                if e ~= 0 then
                    vui.console("Error "..tostring(e)..": "..tostring(hashCode))
                    return
                end

                _G.tacTemp.database.users[hashName] = {name = name, code = hashCode, perm = 0}
                vui.log("Creating user "..name)
                vui.console("User successfully created")
                return
            end
        elseif args[1] == "remove" then
            local name = args[2]
            local passcode = args[3]

            if type(name) == "string" then
                local e, hashName = tac.client.hash(name)

                if e ~= 0 then
                    vui.console("Error "..tostring(e)..": "..tostring(hashName))
                    return
                end

                _G.tacTemp.database.users[hashName] = nil
                vui.log("Deleting user "..name)
                vui.console("User successfully updated")
                return
            end
        end
    elseif command == "users" then
        vui.console("-- Users --")
        vui.console(string.format("%20s | %4s", "Name of the User", "Perm"))
        vui.console(string.format("---------------------+-----"))
        for k, v in pairs(_G.tacTemp.database.users) do
            vui.console(string.format("%20s | %4d", v.name, v.perm))
        end
        vui.console("-- Users --")
        return
    elseif command == "action" then
        if args[1] == "update" then
            local name = args[2]
            local perm = tonumber(args[3])
            local id = tonumber(args[4])
            local dest = tonumber(args[5]) or id

            if type(name) == "string" and type(perm) == "number" and type(id) == "number" and type(dest) == "number" then
                _G.tacTemp.database.actions[name] = {perm = perm, id = id, dest = dest}
                vui.log("Creating action "..name.." requiring permission level "..perm.." performed on ID"..dest.." via ID"..id)
                vui.console("Action successfully updated")
                return
            end
        elseif args[1] == "remove" then
            local name = args[2]

            if type(name) == "string" then
                _G.tacTemp.database.actions[name] = nil
                vui.log("Deleting action "..name)
                vui.console("Action successfully deleted")
                return
            end
        end
    elseif command == "actions" then
        vui.console("-- Actions --")
        vui.console(string.format("%20s | %4s | %4s | %4s", "Name of the Action", "Perm", "ID", "Dest"))
        vui.console(string.format("---------------------+------+-----+-----"))
        for k, v in pairs(_G.tacTemp.database.actions) do
            vui.console(string.format("%20s | %4d | %4d | %4d", k, v.perm, v.id, v.dest))
        end
        vui.console("-- Actions --")
        return
    elseif command == "perm" then
        local name = args[1]
        local perm = tonumber(args[2])
        if type(name) == "string" and type(perm) == "number" then
            local e, hashName = tac.client.hash(name)

            if e ~= 0 then
                vui.console("Error "..tostring(e)..": "..tostring(hashName))
                return
            end

            if not _G.tacTemp.database.users[hashName] then
                vui.console("User not found")
                return
            end

            _G.tacTemp.database.users[hashName].perm = perm

            vui.log("Updating permission of user "..name.." to "..perm)
            vui.console("Permission successfully updated")
            return
        end
    end
    vui.console("Invalid command, type 'help' to show usage")
end

return com
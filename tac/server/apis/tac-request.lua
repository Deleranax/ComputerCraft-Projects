local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local tpm = require("/apis/tpm-api")

local function request(userHash, args, id, sender)

    local userdata = _G.tacTemp.database.users[userHash]

    local function returnCode(code)
        local e, mess = tac.secureSend(id, {code=code}, sender)
        if e == 0 then
            return
        end
        vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
    end


    if args[1] == "auth" then
        returnCode(200)
    elseif args[1] == "require_action" then
        local name = args[2]
        local modification = args[3]

        if type(name) == "string" and type(modification) == "string" then

            local action = _G.tacTemp.database.actions[name]

            if not action then
                returnCode(400)
                return
            end

            if userdata.perm < action.perm then
                returnCode(403)
                vui.consoleLog(userdata.name.." got not enough permission to trigger action "..name..":"..modification)
                return
            end

            local e, mess = tac.secureSend(action.id, {"trigger_action", name, modification}, action.dest)
            if e ~= 0 then
                returnCode(503)
                vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
                return
            end

            returnCode(200)
            vui.consoleLog("Action "..name..":"..modification.." triggered by "..userdata.name)
            return
        else
            returnCode(400)
            return
        end
    end

    vui.consoleLog("Unimplemented request")
    returnCode(501)
end

return request
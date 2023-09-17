local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")
local tpm = require("/apis/tpm-api")

local function request(userHash, args, id, sender)
    if args[1] == "auth" then
        local e, mess = tac.secureSend(id, {code=200}, sender)
        if e == 0 then
            return
        end
        vui.consoleLog("Error "..tostring(e)..": "..tostring(mess))
        return
    end
end

return request
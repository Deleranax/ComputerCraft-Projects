local ecc = require("/apis/ecc")
local err = require("/apis/tac-error")
local tac = _G.tac

local function encryptFor(mess, dest)
    local publicKey = _G.tacTemp.database.verifiedHosts[dest]

    if type(publicKey) ~= "table" then
        return err.parse(151)
    end

    local ss
    local status = pcall(function()  ss = ecc.exchange(_G.tacTemp.privateKey, publicKey) end)

    if not status or type(ss) ~= "table" then
        return err.parse(152)
    end

    local eh
    status = pcall(function() eh = string.char(unpack(ecc.encrypt(mess, ss)))  end)

    if not status or type(eh) ~= "string" then
        return err.parse(153)
    end

    return 0, eh
end

local function decryptFrom(mess, sender)
    local publicKey = _G.tacTemp.database.verifiedHosts[sender]

    if type(publicKey) ~= "table" then
        return err.parse(151)
    end

    local ss
    local status = pcall(function()  ss = ecc.exchange(_G.tacTemp.privateKey, publicKey) end)

    if not status or type(ss) ~= "table" then
        return err.parse(152)
    end

    local eh
    status = pcall(function() eh = string.char(unpack(ecc.decrypt(mess, ss)))  end)

    if not status or type(eh) ~= "string" then
        return err.parse(153)
    end

    return 0, eh
end

local function hash(mess)
    local h
    local status = pcall(function()  h = string.char(unpack(ecc.sha256.digest(mess))) end)

    if not status or type(h) ~= "string" then
        return err.parse(134)
    end

    return 0, h
end

local function connect(host, id, userHash, userCode)

    if not userHash or not userCode then
        return err.parse(171)
    end

    local e, sHash = encryptFor(userHash, host)

    if e ~= 0 then
        return e, sHash
    end

    local e, sCode = encryptFor(userCode, host)

    if e ~= 0 then
        return e, sCode
    end

    local function sendRequest(requestType, ...)
        local request = {...}
        table.insert(request, 1, sHash)
        table.insert(request, 2, sCode)
        table.insert(request, 3, requestType)

        return tac.secureSend(id, request, host)
    end

    local function waitRequest(timeout)
        local e, rData, rSender, rDest, rId
        for i = 1, 5, 1 do
            e, rData, rSender, rDest, rId = tac.secureReceive(timeout)

            if rSender == host and rDest == os.getComputerID() then
                break
            end
        end

        if e == 91 or rSender ~= host or rDest ~= os.getComputerID() then
            return err.parse(172)
        end

        if e ~= 0 then
            return e, rData
        end

        return 0, rData
    end

    local function boundUser(newUserHash, newUserCode, newId)
        local e, data = sendRequest("bound_user", newUserHash, newUserCode, newId)

        if e ~= 0 then
            return e, data
        end

        e, data = waitRequest(2)

        if e ~= 0 then
            return e, data
        else
            return 0, data.code
        end
    end

    local function requireAction(name, action)
        local e, data = sendRequest("require_action", name, action)

        if e ~= 0 then
            return e, data
        end

        e, data = waitRequest(2)

        if e ~= 0 then
            return e, data
        else
            return 0, data.code
        end
    end

    local function confirmAction(name, action)
        local e, data = sendRequest("confirm_action", name, action)

        if e ~= 0 then
            return e, data
        end

        e, data = waitRequest(2)

        if e ~= 0 then
            return e, data
        else
            return 0, data.code
        end
    end

    local connection = {host = host, id = id, userHash = sHash, userCode = sCode, boundUser = boundUser, requireAction = requireAction, confirmAction = confirmAction}

    local e, mess = sendRequest("auth")

    if e ~= 0 then
        return e, mess
    end

    local e, mess = waitRequest(2)

    if e ~= 0 then
        return e, mess
    end

    if mess.code ~= 200 then
        return err.parse(173, tonumber(mess.code))
    end

    return 0, connection
end

return {encryptFor = encryptFor, decryptFrom = decryptFrom, hash = hash, connect = connect}
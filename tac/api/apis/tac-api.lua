ecc = require("apis/ecc")
net = require("apis/tac-network")
err = require("apis/tac-error")

_G["tacTemp"] = {database = {seed = ecc.random.random(), verifiedHosts = {}}, publicKey = {}, privateKey = {}, waitForPong = false}

local function loadDatabase()

    if fs.exists("/.tac") then
        local file = fs.open("/.tac", "r")
        local msg = file.readAll()
        file.close()

        if not msg then
            return err.parse(11)
        end

        local database = textutils.unserialise(msg)

        if not database then
            return err.parse(12)
        end

        _G.tacTemp.database = database
    else
        return err.parse(13)
    end

    return 0
end

local function saveDatabase()
    local msg = textutils.serialise(_G.tacTemp.database)

    if type(msg) ~= "string" then
        return err.parse(21)
    end

    local file = fs.open("/.tac", "w")
    file.write(msg)
    file.close()

    return 0
end

local function initialise()
    local e, msg = loadDatabase()

    _G.tacTemp.privateKey, _G.tacTemp.publicKey = ecc.keypair(_G.tacTemp.database.seed)

    if not _G.tacTemp.privateKey or not _G.tacTemp.publicKey then
        return err.parse(111)
    end

    if e == 13 then
        saveDatabase()
    end

    if e ~= 0 then
        return e, msg
    end
end

local function sign(data)
    local msg = textutils.serialise(data)

    if not msg then
        return err.parse(31)
    end

    local signature = ecc.sign(_G.tacTemp.privateKey, msg)

    if not signature then
        return err.parse(32)
    end

    return 0, textutils.serialise({signature = signature, data = msg})
end

local function verify(packetMsg, id, dest)
    local publicKey = _G.tacTemp.database.verifiedHosts[id]

    if type(packetMsg) ~= "string" or type(id) ~= "number" then
        return err.parse(41)
    end

    if type(publicKey) ~= "table" then
        return err.parse(42)
    end

    local packet = textutils.unserialise(packetMsg)

    if type(packet) ~= "table" then
        return err.parse(43)
    end

    local signature = packet.signature

    if type(signature) ~= "table" then
        return err.parse(44)
    end

    local msg = packet.data

    if type(msg) ~= "string" then
        return err.parse(45)
    end

    if not ecc.verify(publicKey, msg, signature) then
        return err.parse(46)
    end

    local data = textutils.unserialise(msg)

    if type(data) ~= "table" then
        return err.parse(47)
    end

    return 0, data, id, dest
end

local function trust(id, publicKey)
    if type(id) ~= "number" or type(publicKey) ~= "table" then
        return err.parse(51)
    end

    table.insert(_G.tacTemp.database.verifiedHosts, id, publicKey)
    return 0
end

local function secureSend(id, data)
    local e, packet = sign(data)

    if e == 0 then
        return net.send(packet, os.getComputerID(), id)
    else
        return e, packet
    end
end

local function handleService(data, sender, dest)
    if data.serviceMessage == "ping" then
        secureSend(sender, {service = true, serviceMessage = "pong"})
    elseif data.serviceMessage == "pong" and _G.tacTemp.waitForPong then
        return "pong"
    end
end

local function secureReceive(timeout)
    local e, packet, sender, dest = net.receive(timeout)

    if e == 0 then
        local e2, data, sender2, dest2 = verify(packet, sender, dest)

        if data.service then
            local rtn = handleService(data, sender, dest)
            if not rtn then
                return secureReceive(timeout)
            else
                return 0, rtn, sender, dest
            end
        end
    else
        return e, packet, sender, dest
    end
end

local function verifyCommunication(id)
    local e, mess = secureSend(id, {service = true, serviceMessage = "ping"})

    if e ~= 0 then
        return e, mess
    end

    _G.tacTemp.waitForPong = true

    local e, data, sender, dest

    for i = 1, 5, 1 do

        e, data, sender, dest = secureReceive(2)

        if e == 0 and sender == id then
            break
        end
    end

    _G.tacTemp.waitForPong = false

    if e ~= 0 then
        return err.parse(121)
    end
end


tac = {initialise = initialise, loadDatabase = loadDatabase, saveDatabase = saveDatabase, sign = sign, verify = verify, trust = trust, secureReceive = secureReceive, secureSend = secureSend, verifyCommunication, retrievePublicKey = retrievePublicKey}

return tac
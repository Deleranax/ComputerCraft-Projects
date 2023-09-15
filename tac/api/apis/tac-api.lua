ecc = require("apis/ecc")
net = require("apis/tac-network")

_G["tacTemp"] = {database = {seed = ecc.random.random(), verifiedHosts = {}}, publicKey = nil, privateKey = nil}

local function loadDatabase()

    if fs.exists("/.tac") then
        local file = fs.open("/.tac", "r")
        local msg = file.readAll()
        file.close()

        if not msg then
            return 11, "Unable to load DataBase's File"
        end

        local database = textutils.unserialise(msg)

        if not database then
            return 12, "Unable to load DataBase"
        end

        _G.tacTemp.database = database
        _G.tacTemp.privateKey, _G.tacTemp.publicKey = ecc.keypair(_G.tacTemp.database.seed)
    else
        return 13, "DataBase is missing"
    end

    return 0
end

local function saveDatabase()
    local msg = textutils.serialise(_G.tacTemp.database)

    if type(msg) ~= "string" then
        return 21, "Unable to save database"
    end

    local file = fs.open("/.tac", "w")
    file.write(msg)
    file.close()

    return 0
end

local function sign(data)
    local msg = textutils.serialise(data)

    if not msg then
        return 31, "Unable to write data"
    end

    local signature = ecc.sign(_G.tacTemp.privateKey, msg)

    if not signature then
        return 32, "Unable to compute certificate"
    end

    return 0, textutils.serialise({signature = signature, data = msg})
end

local function verify(packetMsg, id, dest)
    local publicKey = _G.tacTemp.database.verifiedHosts[id]

    if type(packetMsg) ~= "string" or type(id) ~= "number" then
        return 41, "Unable to read packet (wrong type) or ID"
    end

    if type(publicKey) ~= "table" then
        return 42, "Host is not verified"
    end

    local packet = textutils.unserialise(packetMsg)

    if type(packet) ~= "table" then
        return 43, "Unable to read packet"
    end

    local signature = packet.signature

    if type(signature) ~= "table" then
        return 44, "Unable to read signature"
    end

    local msg = packet.data

    if type(msg) ~= "string" then
        return 45, "Unable to read data"
    end

    if ecc.verify(publicKey, msg, signature) then
        return 46, "Invalid certificate: Host("..h..") and Local("..h2..")"
    end

    local data = textutils.unserialise(msg)

    if type(data) ~= "table" then
        return 47, "Unable to unpack data"
    end

    return 0, data, id, dest
end

local function trust(id, publicKey)
    if type(id) ~= "number" or type(publicKey) ~= "table" then
        return 51, "Invalid ID or public key"
    end

    table.insert(_G.tacTemp.database.verifiedHosts, id, publicKey)
    return 0
end

local function secureReceive(timeout)
    local err, packet, sender, dest = net.receive(timeout)

    if err == 0 then
        return verify(packet, sender, dest)
    else
       return err, packet
    end
end

local function secureSend(id, data)
    local err, packet = sign(data)

    if err == 0 then
        return net.send(packet, os.getComputerID(), id)
    else
        return err, packet
    end
end

-- Retrieve public key for directly connected computers only
local function retrievePublicKey(id, timeout)
    rednet.send(id, "public_key", "tac_key")

    local rid, msg = -1

    while rid ~= id do
        msg = nil
        rid, msg = rednet.receive("tac_key", timeout)
        if msg == nil then
            break
        end
    end

    if rid ~= id then
        return 61, "Unable to contact host"
    end

    if type(msg) ~= "table" then
        return 62, "Unable to read key"
    end

    return 0, msg
end

tac = {loadDatabase = loadDatabase, saveDatabase = saveDatabase, sign = sign, verify = verify, trust = trust, secureReceive = secureReceive, secureSend = secureSend, retrievePublicKey = retrievePublicKey}

return tac
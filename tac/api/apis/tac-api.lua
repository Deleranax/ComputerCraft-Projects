sha256 = require("apis/sha256")
rsa = require("apis/rsa-crypt")
net = require("apis/tac-network")

_G["tacTemp"] = {database = {verifiedHosts = {}}, publicKey = nil, privateKey = nil}

local function loadDatabase()
    if fs.exists("/public.key") and fs.exists("/private.key") then
        _G.tacTemp.publicKey, _G.tacTemp.privateKey = rsa.loadLocalKeys();
    else
        return 1, "RSA keys are missing"
    end

    if not _G.tacTemp.publicKey or not _G.tacTemp.privateKey then
        return 2, "Can't load RSA keys"
    end

    if fs.exists("/.tac") then
        file = fs.open("/.tac")
        msg = file.readAll()
        file.close()

        if not msg then
            return 3, "Unable to load DataBase's File"
        end

        database = textutils.unserialise(msg)

        if not database then
            return 4, "Unable to load DataBase"
        end

        _G.tacTemp.database = database
    else
        return 5, "DataBase is missing"
    end

    return 0
end

saveDatabase()

local function sign(data)
    local msg = textutils.serialise(data)

    if not msg then
        return 1, "Unable to write data"
    end

    local h = sha256.hash(msg)

    if not h then
        return 2, "Unable to hash data"
    end

    local certificate = rsa.encryptString(h, _G.tacTemp.privateKey)

    if not certificate then
        return 3, "Unable to compute certificate"
    end

    return 0, textutils.serialise({certificate = certificate, data = msg})
end

local function verify(packetMsg, id)
    local publicKey = _G.tacTemp.database.verifiedHosts[id]

    if type(packetMsg) ~= "string" or type(id) ~= "number" then
        return 1, "Unable to read packet (wrong type) or ID"
    end

    if type(publicKey) ~= "table" then
        return 2, "Host is not verified"
    end

    local packet = textutils.unserialise(packetMsg)

    if type(packet) ~= "table" then
        return 3, "Unable to read packet"
    end

    local certificate = packet.certificate

    if type(certificate) ~= "string" then
        return 4, "Unable to read certificate"
    end

    local h = rsa.decryptString(certificate)

    if type(h) ~= "string" then
        return 5, "Unable to decrypt certificate"
    end

    local msg = packet.data

    if type(msg) ~= "string" then
        return 6, "Unable to read data"
    end

    local h2 = sha256.hash(msg)

    if type(h2) ~= "string" then
        return 7, "Unable to hash data"
    end

    if h2 ~= h then
        return 8, "Invalid certificate: Host("..h..") and Local("..h2..")"
    end

    local data = textutils.unserialise(msg)

    if type(data) ~= "table" then
        return 9, "Unable to unpack data"
    end

    return 0, data
end

local function trust(id, publicKey)
    if type(id) ~= "number" or type(publicKey) ~= "table" then
        return 1, "Invalid ID or public key"
    end

    table.insert(_G.tacTemp.database.verifiedHosts)
end

tac = {loadDatabase = loadDatabase, sign = sign, verify = verify, net = net}

return tac
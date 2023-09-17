local ecc = require("/apis/ecc")
local net = require("/apis/tac-network")
local err = require("/apis/tac-error")

_G["tacTemp"] = {database = {seed = ecc.random.random(), verifiedHosts = {}}, publicKey = {}, privateKey = {}, waitForPong = false, busy = false, initiation = {}}

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

    local status = pcall(function() _G.tacTemp.privateKey, _G.tacTemp.publicKey = ecc.keypair(_G.tacTemp.database.seed) end)

    if not status or not _G.tacTemp.privateKey or not _G.tacTemp.publicKey then
        return err.parse(111)
    end

    if e == 13 then
        saveDatabase()
    end

    if e ~= 0 then
        return e, msg
    end

    return 0
end

local function sign(data)
    local msg = textutils.serialise(data)

    if not msg then
        return err.parse(31)
    end

    local signature
    local status = pcall(function() signature = ecc.sign(_G.tacTemp.privateKey, msg) end)

    if not status or not signature then
        return err.parse(32)
    end

    return 0, textutils.serialise({signature = signature, data = msg})
end

local function verify(packetMsg, sender)
    local publicKey = _G.tacTemp.database.verifiedHosts[sender]

    if type(packetMsg) ~= "string" or type(sender) ~= "number" then
        return err.parse(41)
    end

    local packet = textutils.unserialise(packetMsg)

    if type(packet) ~= "table" then
        return err.parse(43)
    end

    if packet.initCom then
        _G.tacTemp.initiation = packet.hash
        return err.parse(130)
    end

    if type(publicKey) ~= "table" then
        return err.parse(42)
    end

    local signature = packet.signature

    if type(signature) ~= "table" then
        return err.parse(44)
    end

    local msg = packet.data

    if type(msg) ~= "string" then
        return err.parse(45)
    end

    local flag
    local status = pcall(function() flag = ecc.verify(publicKey, msg, signature) end)

    if not status or not flag then
        return err.parse(46)
    end

    local data = textutils.unserialise(msg)

    if type(data) ~= "table" then
        return err.parse(47)
    end

    return 0, data
end

local function trust(id, publicKey)
    if type(id) ~= "number" or type(publicKey) ~= "table" then
        return err.parse(51)
    end

    table.insert(_G.tacTemp.database.verifiedHosts, id, publicKey)
    return 0
end

local function doubt(id)
    if type(id) ~= "number" then
        return err.parse(141)
    end

    if not _G.tacTemp.database.verifiedHosts[id] then
        return err.parse(142)
    end

    _G.tacTemp.database.verifiedHosts[id] = nil
    return 0
end

local function secureSend(id, data, dest)
    dest = dest or id
    local e, packet = sign(data)

    if e == 0 then
        return net.send(packet, os.getComputerID(), id, dest)
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
    local e, packet, sender, dest, id = net.receive(timeout)

    if e == 0 then
        local e2, data = verify(packet, sender)

        if e2 ~= 0 then
            return e2, data, sender, dest, id
        end

        if data.service then
            local rtn = handleService(data, sender, dest)
            if not rtn then
                return secureReceive(timeout)
            else
                return 0, rtn, sender, dest, id
            end
        end

        return e2, data, sender, dest, id
    else
        return e, packet
    end
end

local function verifyCommunication(id, dest)
    dest = dest or id
    local e, mess = secureSend(id, {service = true, serviceMessage = "ping"})

    if e ~= 0 then
        return e, mess
    end

    _G.tacTemp.waitForPong = true
    _G.tacTemp.busy = true

    local e, data, sender, dest

    for i = 1, 5, 1 do

        e, data, sender, dest = secureReceive(2)

        if e == 0 and sender == id then
            rednet.send(id, "pong", "service")
            break
        end
    end

    _G.tacTemp.waitForPong = false
    _G.tacTemp.busy = false

    if e ~= 0 then
        return e, data
    end
end

local function initiateCommunication(id, pass, dest)
    dest = dest or id

    if type(id) ~= "number" or type(pass) ~= "string" then
        return err.parse(131)
    end

    if _G.tacTemp.database.verifiedHosts[id] then
        return err.parse(136)
    end

    local e, publicKey = net.retrievePublicKey(id, 2)

    if e ~= 0 then
        return e, publicKey
    end

    local ss
    local status = pcall(function()  ss = ecc.exchange(_G.tacTemp.privateKey, publicKey) end)

    if not status or type(ss) ~= "table" then
        return err.parse(135)
    end

    local h
    status = pcall(function()  h = string.char(unpack(ecc.sha256.digest(pass))) end)

    if not status or type(h) ~= "string" then
        return err.parse(134)
    end

    local eh
    status = pcall(function() eh = string.char(unpack(ecc.encrypt(h, ss)))  end)

    if not status or type(eh) ~= "string" then
        return err.parse(132)
    end

    local e, msg = net.send(textutils.serialise({initCom = true, hash = eh}), os.getComputerID(), id)

    if e ~= 0 then
        return e, msg
    end

    _G.tacTemp.busy = true

    local e, packet, sender, dest2, id2

    for i = 1, 30, 1 do
        e, packet, sender, dest2, id2 = net.receive(10)

        if sender == dest then
            rednet.send(id2, "pong", "service")
            break
        end
    end

    if e ~= 0 then
        return e, packet
    end

    _G.tacTemp.busy = false
    local a
    status = pcall(function()  a = string.char(unpack(ecc.decrypt(packet, ss))) end)

    if not status or type(a) ~= "string" then
        return err.parse(132)
    end

    if a ~= pass then
        return err.parse(133)
    end

    return trust(dest, publicKey)
end

local function confirmCommunication(id, pass, dest)
    dest = dest or id
    local e, publicKey = net.retrievePublicKey(id, 2)

    if _G.tacTemp.database.verifiedHosts[id] then
        return err.parse(136)
    end

    if e ~= 0 then
        return e, publicKey
    end

    local ss
    local status = pcall(function()  ss = ecc.exchange(_G.tacTemp.privateKey, publicKey) end)

    local h
    status = pcall(function()  h = string.char(unpack(ecc.sha256.digest(pass))) end)

    if not status or type(h) ~= "string" then
        return err.parse(134)
    end

    if not status or type(ss) ~= "table" then
        return err.parse(135)
    end

    local a
    local status = pcall(function()  a = string.char(unpack(ecc.decrypt(_G.tacTemp.initiation, ss))) end)

    if not status or type(a) ~= "string" then
        return err.parse(132)
    end

    if a ~= h then
        net.send("pass", os.getComputerID(), id)
        return err.parse(133)
    end

    local e, mess = trust(dest, publicKey)

    if e ~= 0 then
        return e, mess
    end

    local status = pcall(function()  a = string.char(unpack(ecc.encrypt(pass, ss))) end)

    if not status or type(a) ~= "string" then
        return err.parse(132)
    end

    local e, msg = net.send(a, os.getComputerID(), id)

    if e ~= 0 then
        return e, msg
    end

    return 0
end

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
    status = pcall(function()  h = string.char(unpack(ecc.sha256.digest(pass))) end)

    if not status or type(h) ~= "string" then
        return err.parse(134)
    end

    return 0, h
end

-- TODO: Add Relays

tac = {initialise = initialise, loadDatabase = loadDatabase, saveDatabase = saveDatabase, sign = sign, verify = verify, trust = trust, secureReceive = secureReceive, secureSend = secureSend, verifyCommunication, initiateCommunication = initiateCommunication, confirmCommunication = confirmCommunication, encryptFor = encryptFor, decryptFrom = decryptFrom, hash = hash}

return tac
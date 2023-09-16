local err = require("apis/tac-error")

local function handle(frame, id)
    if type(frame) ~= "table" then
        return err.parse(71)
    end

    local header = frame.header

    if type(header) ~= "table" then
        return err.parse(72)
    end

    local sender = header.sender
    local dest = header.dest

    if type(sender) ~= "number" or type(dest) ~= "number" then
        return err.parse(73)
    end

    local packet = frame.packet

    if type(packet) ~= "string" then
        return err.parse(74)
    end

    return 0, packet, sender, dest, id
end

local function prepare(packet, sender, dest)
    if type(packet) ~= "string" or type(sender) ~= "number" or type(dest) ~= "number" then
        return err.parse(81)
    end

    return 0, {header = {sender = sender, dest = dest}, packet = packet}
end

local function handleService(msg, id, protocol)
    if msg == "ping" then
        rednet.send(id, "pong", "service")
    elseif msg == "public_key" then
        rednet.send(id, _G.tacTemp.publicKey, "service")
    end
end


local function receive(timeout)
    local id, frame, protocol = rednet.receive(timeout)

    if type(id) ~= "number" then
        return err.parse(91)
    end

    if not _G.tacTemp.busy then
        rednet.send(id, "pong", "service")
    end

    if protocol ~= "tac" then
        local rtn = handleService(frame, id, protocol)
        return receive(timeout)
    end

    if type(frame) ~= "table" then
        return err.parse(92)
    end

    return handle(frame, id)
end

local function send(packet, sender, id, dest)
    dest = dest or id

    local e, frame = prepare(packet, sender, dest)

    if e ~= 0 or type(frame) ~= "table" then
        return e, frame
    end

    for i = 1, 5, 1 do
        rednet.send(id, frame, "tac")
        local id, msg = rednet.receive("service", 2)
        if id == dest then
            return 0
        end
    end

    return err.parse(101)
end

local function retrievePublicKey(id, timeout)
    local rid, msg = -1

    while rid ~= id do
        msg = nil
        rednet.send(id, "public_key", "service")
        rid, msg = rednet.receive("service", timeout)
        if msg == nil then
            break
        end
    end

    if rid ~= id then
        return err.parse(61)
    end

    if type(msg) ~= "table" then
        return err.parse(62)
    end

    return 0, msg
end

return { handle = handle, prepare = prepare, receive = receive, send = send, retrievePublicKey = retrievePublicKey }
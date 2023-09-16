tac = {}
err = require("apis/tac-error")

local function handle(frame)
    if not tac or not _G.tacTemp then
        printError("TAC-Network: Unable to find TAC-API (is it loaded?)")
    end

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

    return 0, packet, sender, dest
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
    end

    if protocol == "tac_key" then
        if msg == "public_key" then
            rednet.send(id, _G.tacTemp.publicKey, protocol)
        end
    end
end


local function receive(timeout)
    local id, frameMsg, protocol = rednet.receive(timeout)
    rednet.send(id, "pong", "service")

    if protocol ~= "tac" then
        handleService(frameMsg, id, protocol)
        return receive(timeout)
    end

    if type(frameMsg) ~= "table" then
        return err.parse(91)
    end

    return handle(frameMsg)
end

local function send(packet, sender, dest)
    local e, frame = prepare(packet, sender, dest)

    if e ~= 0 or type(frame) ~= "table" then
        return e, frame
    end

    for i = 1, 5, 1 do
        rednet.send(dest, frame, "tac")
        local id, msg, protocol = rednet.receive(2)
        if id == dest then
            return 0
        end
    end

    return err.parse(101)
end

return { handle = handle, prepare = prepare, receive = receive, send = send }
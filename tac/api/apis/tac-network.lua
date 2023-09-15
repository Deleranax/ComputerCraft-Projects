tac = {}

local function handle(frameMsg)
    if not tac or not _G.tacTemp then
        printError("TAC-Network: Unable to find TAC-API (is it loaded?)")
    end

    if type(packetMsg) ~= "string" then
        return 1, "Unable to read frame (wrong type)"
    end

    local frame = textutils.unserialise(frameMsg)

    if type(frame) ~= "table" then
        return 2, "Unable to read frame"
    end

    local header = frame.header

    if type(header) ~= "table" then
        return 3, "Missing header"
    end

    local sender, dest = table.unpack(header)

    if type(sender) ~= "number" or type(dest) ~= "number" then
        return 4, "Malformed header or unable to read it"
    end

    local packet = data.packet

    if type(packet) ~= "string" then
        return 5, "Unable to read content"
    end

    return 0, packet, sender, dest
end

local function prepare(packet, sender, dest)
    if type(content) ~= "string" or type(sender) ~= "number" or type(dest) ~= "number" then
        return 1, "Invalid content or sender or dest"
    end

    return 0, {header = {sender = sender, dest = dest}, packet = packet}
end

local function handleService(msg, id, protocol)
    if msg == "ping" then
        rednet.send(id, "pong", protocol)
    end

    if protocol == "tac_key" then
        if msg == "public_key" then
            rednet.send(id, _G.tacTemp.publicKey, protocol)
        end
    end
end


local function receive(timeout)
    local time = os.time() * 60
    local frameMsg, id, protocol = rednet.receive("tac", timeout)

    if protocol ~= "tac" then
        handleService(frameMsg, id, protocol)
        return receive((os.time() * 60) - time)
    end

    if type(frameMsg) ~= "string" then
        return 1, "Timed Out"
    end

    return handle(frameMsg)
end

local function send(packet, sender, dest)
    local err, frame = prepare(packet, sender, dest)

    if err ~= 0 or type(frame) ~= "table" then
        return err, frame
    end

    rednet.send(dest, frame)
end

return { handle = handle, prepare = prepare, receive = receive, send = send }
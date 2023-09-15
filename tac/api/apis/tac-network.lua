tac = {}

local function handle(frame)
    if not tac or not _G.tacTemp then
        printError("TAC-Network: Unable to find TAC-API (is it loaded?)")
    end

    if type(frame) ~= "table" then
        return 71, "Unable to read frame"
    end

    local header = frame.header

    if type(header) ~= "table" then
        return 72, "Missing header"
    end

    local sender, dest = table.unpack(header)

    if type(sender) ~= "number" or type(dest) ~= "number" then
        return 73, "Malformed header or unable to read it"
    end

    local packet = data.packet

    if type(packet) ~= "string" then
        return 74, "Unable to read content"
    end

    return 0, packet, sender, dest
end

local function prepare(packet, sender, dest)
    if type(packet) ~= "string" or type(sender) ~= "number" or type(dest) ~= "number" then
        return 81, "Invalid content or sender or dest"
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

    if type(frameMsg) ~= "string" then
        return 91, "Timed Out"
    end

    return handle(frameMsg)
end

local function send(packet, sender, dest)
    local err, frame = prepare(packet, sender, dest)

    if err ~= 0 or type(frame) ~= "table" then
        return err, frame
    end

    for i = 1, 5, 1 do
        rednet.send(dest, frame)
        local id, msg, protocol = rednet.receive(2)
        if id == os.getComputerID() then
            return 0
        end
    end

    return 101, "No response after 5 retry"
end

return { handle = handle, prepare = prepare, receive = receive, send = send }
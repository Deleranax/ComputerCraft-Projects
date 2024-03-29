local errors = {
    [11] = "Unable to load DataBase File",
    [12] = "Unable to load DataBase",
    [13] = "DataBase is missing",
    [21] = "Unable to save database",
    [31] = "Unable to write data",
    [32] = "Unable to compute certificate",
    [41] = "Invalid packet or ID",
    [42] = "Host is not verified",
    [43] = "Unable to read packet",
    [44] = "Unable to read signature",
    [45] = "Unable to read data",
    [46] = "Invalid signature: Wrong key or compromised communication",
    [47] = "Unable to unpack data",
    [51] = "Invalid ID or public key",
    [61] = "Unable to contact host",
    [62] = "Unable to read key",
    [63] = "Invalid ID",
    [71] = "Unable to read frame",
    [72] = "Missing header",
    [73] = "Malformed header or unable to read it",
    [74] = "Unable to read content",
    [81] = "Invalid content or sender or dest",
    [91] = "Timed Out",
    [92] = "Incorrect message",
    [101] = "No response after 5 retry",
    [111] = "Unable to generate keypair",
    [121] = "Unable to verify communication",
    [130] = "Communication initiation",
    [131] = "Invalid passcode or ID",
    [132] = "Unable to encrypt/decrypt",
    [133] = "Wrong passcode",
    [134] = "Unable to hash",
    [135] = "Unable to compute shared secret",
    [136] = "Already initiated",
    [141] = "Invalid ID",
    [142] = "Host is not marked as trusted",
    [151] = "Host is not verified",
    [152] = "Unable to compute shared secret",
    [153] = "Unable to encrypt/decrypt",
    [161] = "Unable to hash",
    [171] = "Unauthenticated user",
    [172] = "Request timed out",
    [173] = "Server refused request (Error %d)",
    [174] = "Network is flooded",
    [181] = "Received invalid command",
    [182] = "Received command for wrong action"
}

local function parse(int, ...)
    local err = errors[int]

    err = err or "Unknown: %s"

    return int, string.format(err, ...)
end

return {parse = parse, list = errors}
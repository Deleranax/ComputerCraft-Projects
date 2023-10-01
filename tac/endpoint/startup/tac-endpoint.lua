local tac = require("/apis/tac-api")
local vui = require("/apis/vintage-ui")

local function fatalError(err)
    sleep(5)
    term.clear()
    term.setCursorPos(1, 1)
    error("Fatal error has occurred (Error "..err..")")
end

local present = false
for _, side in pairs(rs.getSides()) do
    if peripheral.getType(side) == "modem" then
        present = true
        rednet.open(side)
    end
end

if not present then
    error("A modem was not found, please attach one and re-run this program")
end

_G["tacEndpointTemp"] = {diskSide = ""}

vui.setVendor("TAC ENDPOINT - © TEMVER INCORPORATED")
vui.setStatus("Init")
vui.setUpMessage("Initialising...")

local err, mess = tac.initialise()

if err ~= 0 then
    vui.setUpMessage("Error occurred at initialisation")
    vui.printMessage("Error "..tostring(err)..": "..tostring(mess))
    fatalError(err)
end

if not _G.tacTemp.database.endPoint then
    _G.tacTemp.database.endPoint = true
    _G.tacTemp.database.serverID = tonumber(vui.prompt("Enter Server ID"))
    _G.tacTemp.database.serverDest = tonumber(vui.prompt("Enter Server Destination"))

    if not tac.isVerified(_G.tacTemp.database.serverDest) then
        local err, mess = tac.initiateCommunication(2, vui.prompt("Enter pairing Passcode"))

        if err ~= 0 then
            error(err.. " / "..mess)
        end
    end

    local err, mess = tac.verifyCommunication(_G.tacTemp.database.serverID, _G.tacTemp.database.serverDest)

    if err ~= 0 then
        error(err.. " / "..mess)
    end

    vui.setUpMessage("Configuration completed.")
    tac.saveDatabase()
    sleep(5)
end

while true do
    vui.denyEscape()
    vui.setStatus("Idle")
    vui.setUpMessage("Insert PDA to login")
    vui.printMessage("Or press CTRL+T to administrate", colors.lightgray)
    local event, side = os.pullEventRaw("disk")

    if event == "disk" then
        _G.tacEndpointTemp.diskSide = side
        local ok, err = pcall(require("/apis/tac-endpoint-client"), tac, vui)
        if not ok then
            vui.setUpMessage("FATAL: "..tostring(err))
        end
        sleep(5)
    end

    if event == "terminate" then
        _G.tacEndpointTemp.diskSide = side
        local ok, err = pcall(require("/apis/tac-endpoint-admin"), tac, vui)
        if not ok then
            vui.setUpMessage("FATAL: "..tostring(err))
        end
        sleep(5)
    end
end
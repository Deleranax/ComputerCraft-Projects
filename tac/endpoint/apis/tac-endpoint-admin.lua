local tac = {}
local vui = {}

local function fatalError(err)
    sleep(5)
    term.clear()
    term.setCursorPos(1, 1)
    error("Fatal error has occurred (Error "..err..")")
end

local function import(t, v)
    tac = t
    vui = v

    local name = vui.prompt("Enter Username")

    local err, h = tac.client.hash(name)

    if err ~= 0 then
        vui.setUpMessage("Invalid Username")
        sleep(5)
        return
    end

    local pass = vui.promptPassword("Enter Password", 6)

    vui.setUpMessage("Connecting...")

    local err, co = tac.client.connect(_G.tacTemp.database.serverDest, _G.tacTemp.database.serverID, h, pass)

    if err == 173 then
        vui.setUpMessage("Invalid credentials")
        sleep(5)
        return
    elseif err ~= 0 then
        vui.setUpMessage("Error"..tostring(err).. ": "..tostring(co))
        sleep(5)
        return
    end

    local err, su = co.superUser()

    if err ~= 0 then
        vui.setUpMessage("Error"..tostring(err).. ": "..tostring(co))
        sleep(5)
        return
    end

    if not su then
        vui.setUpMessage("Access denied")
        sleep(5)
        return
    end

    vui.allowEscape()
    vui.setUpMessage("Access granted")
    sleep(5)
end

return import
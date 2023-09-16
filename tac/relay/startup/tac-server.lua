local tac = require("/apis/tac-api")
local capi = require("/apis/console-api")

capi.setTitle("Temver Access Control Server")
capi.init()

local function backendLoop()

end

local function commandLoop()
    local active = true

    while active do
        input = capi.input()
    end
end

parallel.waitForAny(backendLoop, commandLoop)
tac = require("apis/tac-api")
capi = require("apis/console-api")

capi.setTitle("Temver Access Control Server")
capi.init()

function backendLoop()

end

function commandLoop()
    local active = true

    while active do
        input = capi.input()
    end
end

parallel.waitForAny(backendLoop, commandLoop)
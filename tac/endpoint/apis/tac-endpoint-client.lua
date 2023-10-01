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
end

return import
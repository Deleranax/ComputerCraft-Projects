local x,y = term.getSize()
_G["vuiTemp"] = {allowEscape = true, vendor = "Vintage UI Corp.", x = x, y = y}

function setVendor(v)
    _G.vuiTemp.vendor = v
end

function allowEscape()
    _G.vuiTemp.allowEscape = true
end

function denyEscape()
    _G.vuiTemp.allowEscape = false
end

function multipleChoice(title, ...)

    local x,y = term.getSize()

    local escape = 0

    printVendor()
    computeAlignment(title, math.floor(y/4))
    textutils.slowWrite(title)

    local choices = {...}

    local nb = table.getn(choices)

    if _G.vuiTemp.allowEscape then
        escape = 1
        table.insert(choices, "Quit")
    end

    local line = math.floor(y/2)

    local places = {}

    for i, v in ipairs(choices) do
        if _G.vuiTemp.allowEscape and i == (nb + 1) then
            computeAlignment(v, line + (2 * i) + 1)
        else
            computeAlignment(v, line + (2 * i))
        end
        places[i] = {term.getCursorPos()}
        textutils.slowWrite(v)
    end

    local rtn = 1
    local old = 1

    while true do
        printSelection(choices, places, old, rtn)
        old = rtn

        local event, key, is_held

        if _G.vuiTemp.allowEscape then
            event, key, is_held = os.pullEvent("key")
        else
            event, key, is_held = os.pullEventRaw()
            if event ~= "key" then
                key = 0
            end
        end

        if key == keys.up then
            rtn = math.max(rtn - 1, 1)
        elseif key == keys.down then
            rtn = math.min(rtn + 1, nb + escape)
        elseif key == keys.enter then
            if rtn > nb then
                return 0
            end
            return rtn
        end
    end
end

function printVendor()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    term.clear()
    computeAlignment(_G.vuiTemp.vendor, 19)
    term.write(_G.vuiTemp.vendor)
    term.setTextColor(colors.white)
end

function computeAlignment(message, line)
    term.setCursorPos(math.ceil((x / 2) - (message:len() / 2)), line)
end

function printSelection(choices, places, old, new)
    term.setCursorPos(places[old][1] - 2,places[old][2])
    term.blit(" ", "f", "f")

    term.setCursorPos(places[old][1] + choices[old]:len() + 1,places[old][2])
    term.blit(" ", "f", "f")

    term.setCursorPos(places[new][1] - 2,places[new][2])
    term.blit("[", "0", "f")

    term.setCursorPos(places[new][1] + choices[new]:len() + 1,places[new][2])
    term.blit("]", "0", "f")
end

return {setVendor = setVendor, allowEscape = allowEscape, denyEscape = denyEscape, multipleChoice = multipleChoice}
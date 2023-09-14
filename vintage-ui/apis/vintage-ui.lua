_G["vuiTemp"] = {allowEscape = true, vendor = "Vintage UI Corp."}

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

    printVendor()
    computeAlignment(title, math.floor(y/4))
    textutils.slowWrite(title)

    local choices = {...}

    local line = math.floor((y / 2) - (table.getn(choices) / 2)) - 2

    local places = {}

    for i, v in ipairs(choices) do
        computeAlignment(v, line + (2 * i))
        places[i] = {term.getCursorPos()}
        term.slowWrite(v)
    end

    local rtn = 1
    local old = 1

    while true do
        old = rtn
        printSelection(choices, places, old, rtn)

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
            rtn = math.min(rtn + 1, table.getn(choices))
        elseif key == keys.enter then
            return rtn
        end
    end
end

function printVendor()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    term.clear()
    computeAlignment(message, 19)
    term.write(_G.vuiTemp.vendor)
    term.setTextColor(colors.white)
end

function computeAlignment(message, line)
    term.setCursorPos(math.ceil((x / 2) - (message:len() / 2)), line)
end

function printSelection(choices, places, old, new)
    term.setCursorPos(places[old][1] - 2,places[old][2])
    term.blit(" ", "0", "0")

    term.setCursorPos(places[old][1] + choices[old]:len() + 1,places[old][2])
    term.blit(" ", "0", "0")

    term.setCursorPos(places[new][1] - 2,places[new][2])
    term.blit("[", "0", "0")

    term.setCursorPos(places[new][1] + choices[new]:len() + 1,places[new][2])
    term.blit("]", "0", "0")
end

return {setVendor = setVendor, allowEscape = allowEscape, denyEscape = denyEscape, multipleChoice = multipleChoice}
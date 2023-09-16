local x,y = term.getSize()
_G["vuiTemp"] = {allowEscape = true, vendor = "Vintage UI Corp.", x = x, y = y, cx = 1, cy = 1}

local function setVendor(v)
    _G.vuiTemp.vendor = v
end

local function allowEscape()
    _G.vuiTemp.allowEscape = true
end

local function denyEscape()
    _G.vuiTemp.allowEscape = false
end

local function saveCursorPos()
    _G.vuiTemp.cx, _G.vuiTemp.cy = term.getCursorPos()
end

local function restoreCursorPos()
    term.setCursorPos(_G.vuiTemp.cx, _G.vuiTemp.cy)
end

local function completeLine(str, char)
    while str:len() < _G.vuiTemp.x do
        str = str..char
    end

    return str
end

local function printVendor()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(1, _G.vuiTemp.y)
    term.write(completeLine(_G.vuiTemp.vendor, " "))
    term.setTextColor(colors.white)
end

local function clearVendor()
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, _G.vuiTemp.y)
    term.write(completeLine("", " "))
end

local function computeAlignment(message, line)
    term.setCursorPos(math.floor((_G.vuiTemp.x / 2) - (message:len() / 2)), line)
end

local function printSelection(choices, places, old, new)
    term.setCursorPos(places[old][1] - 2,places[old][2])
    term.blit(" ", "f", "f")

    term.setCursorPos(places[old][1] + choices[old]:len() + 1,places[old][2])
    term.blit(" ", "f", "f")

    term.setCursorPos(places[new][1] - 2,places[new][2])
    term.blit("[", "0", "f")

    term.setCursorPos(places[new][1] + choices[new]:len() + 1,places[new][2])
    term.blit("]", "0", "f")
end

local function printPassword(current, size)
    term.setCursorPos(math.floor((_G.vuiTemp.x / 2) - (size - 0.5)), math.floor(_G.vuiTemp.y/2))
    for i = 1, size, 1 do
        if i <= current then
            term.write("# ")
        else
            term.write("_ ")
        end
    end
end

local function setUpMessage(title)
    term.clear()
    printVendor()
    computeAlignment(title, math.floor(_G.vuiTemp.y/4))
    textutils.slowWrite(title)
    term.setCursorPos(1, _G.vuiTemp.y/2)
end

local function multipleChoice(title, ...)
    local escape = 0

    setUpMessage(title)

    local choices = {...}

    local nb = table.getn(choices)

    if _G.vuiTemp.allowEscape then
        escape = 1
        table.insert(choices, "Quit")
    end

    local line = math.floor(_G.vuiTemp.y/2) - 1

    local places = {}

    for i, v in ipairs(choices) do
        if _G.vuiTemp.allowEscape and i == (nb + 1) then
            computeAlignment(v, line + i + 1)
        else
            computeAlignment(v, line + i)
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

local function promptPassword(title, size)
    setUpMessage(title)

    if _G.vuiTemp.allowEscape then
        computeAlignment("Press ENTER to confirm and CTRL to quit.", math.floor(3 * (_G.vuiTemp.y/4)))
        term.write("Press ENTER to confirm and CTRL to quit.")
    end

    local pass = ""

    while true do
        printPassword(pass:len(), size)

        local event, key, is_held

        if _G.vuiTemp.allowEscape then
            event, key = os.pullEvent()
        else
            event, key = os.pullEventRaw()
        end

        if event == "key" then

            if (key == keys.leftCtrl or key == keys.rightCtrl) and _G.vuiTemp.allowEscape then
                return nil
            elseif key == keys.enter and pass:len() == size then
                return pass
            elseif key == keys.backspace and pass:len() > 1 then
                pass = string.sub(pass, 1, pass:len() - 1)
            elseif key == keys.backspace and pass:len() == 1 then
                pass = ""
            end
        elseif event == "char" then
            if pass:len() < 6  then
                pass = pass..key
            end
        end
    end
end

local function console(mess)
    clearVendor()

    term.setCursorPos(1, _G.vuiTemp.y - 4)

    local date = os.date("%T")
    print("["..date.."] "..mess)

    local x, y = term.getCursorPos()

    term.scroll(math.min(y - _G.vuiTemp.y + 4, 0))

    printVendor()
end

local function log(mess)
    local date = os.date("%D %T")
    if fs.exists("logs") then
        local file = fs.open("logs", "r")
        local plm = file.readAll()
        file.close()
        file = fs.open("logs", "w")
        file.write(plm.."\n")
        file.writeLine("["..date.."] "..mess)
        file.close()
    else
        local sfile = fs.open("logs", "w")
        sfile.writeLine("Starting the Logs of ".._G.vuiTemp.vendor)
        sfile.close()
    end
end

local function consoleLog(mess)
    console(mess)
    log(mess)
end

local function consoleInput()
    term.setCursorPos(1, _G.vuiTemp.y - 3)
    term.write("> ")
    local args = {}
    for word in s:gmatch("%w+") do table.insert(args, word) end
    local command = table.remove(args, 1)
    return command
end

local function printConsoleStatus(mess)
    saveCursorPos()
    term.setCursorPos(1, _G.vuiTemp.x - mess:len())
    term.write(mess)
    restoreCursorPos()
    return mess
end

return { setVendor = setVendor, allowEscape = allowEscape, denyEscape = denyEscape, multipleChoice = multipleChoice, promptPassword = promptPassword, setUpMessage = setUpMessage, console = console, log = log, consoleLog = consoleLog, consoleInput = consoleInput, printConsoleStatus = printConsoleStatus, saveCursorPos = saveCursorPos, restoreCursorPos = restoreCursorPos, completeLine = completeLine}
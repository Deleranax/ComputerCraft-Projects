if not fs.exist(".pda") then
    file = fs.open(".pda", "w")
    file.write(textutils.serialise({id = os.getComputerID(), userHash = nil, pdaCode = nil}))
    file.close()
end
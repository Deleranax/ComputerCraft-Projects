ttns = require("/apis/ttns-api")
log = require("/apis/console-api")

log.setTitle("TTNS Server")

log.init()
ttns.init()

rednet.open("left")
rednet.host("ttns", "main")

while true do
    id, msg = rednet.receive()
    
    if data.sType == "get" then
        r = ttns.getBlock(data.x, data.y, data.z)
        rednet.send(id, textutils.serialize(r))
        log.console("Getting block ("..data.x..", "..data.y..", "..data.z..") by ID"..id, "m")
    end
    
    if data.sType == "set" then
        ttns.setBlock(data.x, data.y, data.z, data.block)
        log.console("Setting block ("..data.x..", "..data.y..", "..data.z..") by ID"..id, "m")
    end
    
    ttns.saveAll()
end
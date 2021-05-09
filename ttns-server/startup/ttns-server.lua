ttns = require("/apis/ttns-api")

ttns.init()

rednet.open("left")
rednet.host("ttns", "main")

while true do
    id, msg = rednet.receive()
    
    if data.sType == "get" then
        r = ttns.getBlock(data.x, data.y, data.z)
        rednet.send(id, textutils.serialize(r))
        print("Getting block ("..data.x..", "..data.y..", "..data.z..") by ID"..id)
    end
    
    if data.sType == "set" then
        ttns.setBlock(data.x, data.y, data.z, data.block)
        print("Setting block ("..data.x..", "..data.y..", "..data.z..") by ID"..id)
    end
    
    ttns.saveAll()
end
ttns = require("apis/ttns-api")

ttns.init()

rednet.open("left")
rednet.host("ttns")

while true do
	id, msg = rednet.receive(10)
	data = textutils.unserialize(msg)
	
	if data.request == "get" then
		r = ttns.getBlock(data.x, data.y, data.z)
		rednet.send(id, textutils.serialize(r))
		print("Getting block ("..data.x..", "..data.y..", "..data.z..") by ID"..id)
	end
	
	if data.request == "set" then
		ttns.setBlock(data.x, data.y, data.z, data.block)
		print("Setting block ("..data.x..", "..data.y..", "..data.z..") by ID"..id)
	end
end
if not _G.ttnsTemp then
	_G.ttnsTemp = {sectorIndex = {}, sectors = {}, turtles = {}}
end

ttns = {}

ttns.MODEM = "left"

function ttns.toSectorCoords(x, z)
	return math.floor(x / 64), math.floor(z / 64), math.mod(x, 64), math.mod(z, 64)
end

function ttns.getSectorCoords(id)
	if not _G.ttnsTemp.sectorIndex[id] then
		return nil
	end
	return table.unpack(_G.ttnsTemp.sectorIndex[id])
end

function ttns.getSectorId(x, z)
	for k, v in ipairs(_G.ttnsTemp.sectorIndex) do
		if v == {x, z} then
			return k
		end
	end
	return nil
end

function ttns.loadConfigs()
	if not fs.exists(".ttns") then
		return false
	end
	
	f = fs.open(".ttns", "r")
	_G.ttnsTemp.sectorIndex = textutils.unserialize(f.readAll())
	f.close()
	return true
end

function ttns.saveConfigs()
	f = fs.open(".ttns", "wb")
	f.write(textutils.serialize(_G.ttnsTemp.sectorIndex))
	f.close()
	return true
end

function ttns.loadSector(id)
	if not fs.exists("disk"..id.."/data.ttns") then
		return false
	end

	f = fs.open("disk"..id.."/data.ttns", "r")
	_G.ttnsTemp.sector[id] = textutils.unserialize(f.readAll())
	f.close()
	return true
end

function ttns.saveSector(id)
	if not fs.exists("disk"..id..) then
		printError("Can't save sector "..id..", add disks")
		return false
	end

	f = fs.open("disk"..id.."/data.ttns", "wb")
	f.write(textutils.serialize(_G.ttnsTemp.sector[id]))
	f.close()
	return true
end

function ttns.newSector(x, z)
	if not ttns.getSectorId(x, z) then
		table.insert(_G.ttnsTemp.sectorIndex, {x, z})
		id = table.getn(_G.ttnsTemp.sectorIndex)
		_G.ttnsTemp.sectors[id] = {}
		return table.getn(id)
	end
end

function ttns.setBlock(x, y, z, block)
	sx, sz = ttns.toSectorCoords(x, z)
	
	id = ttns.getSectorId(sx, sz)
	
	if not id then
		id = ttns.newSector(sx, sz)
	end
	
	if not _G.ttnsTemp.sectors[id][x] then
		_G.ttnsTemp.sectors[id][x] = {}
	end
	
	if not _G.ttnsTemp.sectors[id][x][y] then
		_G.ttnsTemp.sectors[id][x][y] = {}
	end
		
	_G.ttnsTemp.sectors[id][x][y][z] = block
end

function ttns.getBlock(x, y, z)
	sx, sz = ttns.toSectorCoords(x, z)
	
	id = ttns.getSectorId(sx, sz)
	
	if not id then
		if not _G.ttnsTemp.sectors[id][x] then
			return nil
		end
		
		if not _G.ttnsTemp.sectors[id][x][y] then
			return nil
		end
		
		return _G.ttnsTemp.sectors[id][x][y][z]
	end
end

function ttns.init()
	write("Loading configs... ")
	ttns.loadConfigs()
	print("Done")
	
	print("Loading sectors... ")
	for k, v in ipairs(_G.ttnsTemp.sectorIndex) do
		ttns.loadSector(k)
		print("Sector "..k.." loaded")
	end
	print("Done")
end

function ttns.saveAll()
	print("Saving sectors... ")
	for k, v in ipairs(_G.ttnsTemp.sectorIndex) do
		ttns.saveSector(k)
		print("Sector "..k.." saved")
	end
	print("Done")
end

return ttns
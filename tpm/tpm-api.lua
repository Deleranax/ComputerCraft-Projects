local BASE_URL = "https://raw.githubusercontent.com/Deleranax/ComputerCraft-Projects/master/"

if not _G.tpmTemp then
	_G.tpmTemp = {database = {}, installed = {}}
end

function httpGet(url)
    if not http then
        printError("HTTP is not available.")
        return nil
    end
 
    local ok, err = http.checkURL(url)
 
    if not ok then
        printError(err or "Invalid URL.")
        return nil
    end
    return http.get(url).readAll()
end

function httpGetLines(url)
    if not http then
        printError("HTTP is not available.")
        return nil
    end
	
	local rtn = {}

	local data, err = http.get(url)

	if not data then
		printError(url)
        printError(err or "Invalid URL.")
        return nil
    end

	local line = data.readLine()
	
	while line do
		table.insert(rtn, line)
		line = data.readLine()
	end
	
    return rtn
end

function get(name)
	if name == "" then
		return _G.tpmTemp.database
	end

	local cwd = _G.tpmTemp.database

	for v in name:gmatch("[^/]+") do
		cwd = cwd[v]
		if not cwd then
			break
		end
	end
	
	return cwd
end

function getInstalled(name)
	return _G.tpmTemp.installed[name]
end

function checkDir(url)
	local index = httpGetLines(BASE_URL..url.."CCINDEX")
		
	for i, v in ipairs(index) do
		if v:sub(-1) == "/" then
			get(url)[v:sub(1,-2)] = {}
			checkDir(url..v)
		else
			get(url)[v] = checkPack(url, v)
		end
	end
end

function checkPack(url, name)
	local manifest = httpGetLines(BASE_URL..url..name.."/CCMANIFEST")
	
	local version = tonumber(manifest[1])

	table.remove(manifest, 1)
	
	return {name = name, version = version, url = BASE_URL..url..name.."/", files = manifest}
end

function listEntries(url, rtn)
	local index = get(url)
		
	for k, v in pairs(index) do
		if not v.name then
			if url == "" then
				listEntries(url..k, rtn)
			else
				listEntries(url.."/"..k, rtn)
			end
		else
			if url == "" then
				table.insert(rtn, k)
			else
				table.insert(rtn, url.."/"..k)
			end
		end
	end
end

function getPackageList()
	local rtn = {}
	listEntries("", rtn)
	return rtn
end

function getInstalledPackages()
	return _G.tpmTemp.installed
end

function getInstalledList()
	local keys = {}
	
	for k, v in pairs(_G.tpmTemp.installed) do
		table.insert(keys, k)
	end
	return keys
end

function getPackage(url)
	if not get(url) then
		printError("Unable to locate package "..url)
		return
	end
	
	if not get(url).name then
		printError("Unable to locate package "..url)
		return
	end
	
	return get(url)
end

function reloadDatabase()
	write("Reading package list... ")
	if not fs.exists(".tpm") then
		printError("Missing database. Try to update database.")
		return
	end
	file = fs.open(".tpm", "r")
	data = textutils.unserialize(file.readAll())
	_G.tpmTemp.database = data.database
	_G.tpmTemp.installed = data.installed
	file.close()
	print("Done")
end

function updateDatabase()
	write("Connecting... ")
	httpGet(BASE_URL.."CCINDEX")
	print("Success")
	
	write("Updating package list... ")
	checkDir("")
	print("Done")
	
	saveDatabase()
end

function install(url)

	reloadDatabase()

	if not get(url) then
		printError("Unable to locate package "..url)
		return false
	end
	
	print("Fetching files...")
	
	for i, v in ipairs(get(url).files) do
		print("GET: "..v)
		file = fs.open(v, "wb")
		file.write(httpGet(BASE_URL..url.."/"..v))
		file.close()
	end

	local name = ""
	local urls = ""

	for v in url:gmatch("[^/]+") do
		urls = urls..name
		name = v
	end
	
	_G.tpmTemp.installed[url] = checkPack(urls.."/", name)
	
	saveDatabase()
	
	print("Package successfully installed")
	return true
end

function remove(url)

	reloadDatabase()
	
	if not get(url) then
		printError("Unable to locate package "..url)
	end
	if not _G.tpmTemp.installed[url] then
		printError("Package "..url.." is not installed, so not removed")
		return false
	end
	
	print("Deleting files...")
	
	for i, v in ipairs(_G.tpmTemp.installed[url].files) do
		print("DEL: "..v)
		fs.delete(v)
	end
	
	_G.tpmTemp.installed[url] = nil
	
	saveDatabase()
	
	print("Package successfully removed")
	return true
end

function saveDatabase()
	write("Saving database... ")
	file = fs.open(".tpm", "wb")
	data = textutils.serialize({database = _G.tpmTemp.database, installed = _G.tpmTemp.installed})
	file.write(data)
	file.close()
	print("Done")
end

return {BASE_URL = BASE_URL, httpGet = httpGet, httpGetLines = httpGetLines, reloadDatabase = reloadDatabase, updateDatabase = updateDatabase, saveDatabase = saveDatabase, get = get, getPackage = getPackage, getPackageList = getPackageList, getInstalledPackages = getInstalledPackages, getInstalledList = getInstalledList, install = install, remove = remove}
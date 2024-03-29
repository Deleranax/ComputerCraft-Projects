local BASE_URL = "https://raw.githubusercontent.com/Deleranax/ComputerCraft-Projects/master/"

if not _G.tpmTemp then
	_G.tpmTemp = {database = {}, installed = {}}
end

local function httpGet(url, verbose)
    if not http then
		if verbose then
			error("HTTP is not available.")
		end
        return nil
    end
 
	local data, err = http.get(url, nil, true)

	if not data then
		printError(url..": "..(err or "Invalid URL."))
        return nil
    end
	
    return data.readAll()
end

local function httpGetLines(url, verbose)
    if not http then
		if verbose then
			printError("HTTP is not available.")
		end
        return nil
    end
	
	local rtn = {}

	local data, err = http.get(url, nil, true)

	if not data then
		if verbose then
			printError(url)
			printError(err or "Invalid URL.")
		else
			return nil
		end
        return nil
    end

	local line = data.readLine()
	
	while line do
		table.insert(rtn, line)
		line = data.readLine()
	end
	
    return rtn
end

local function get(name)
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

local function getInstalled(name)
	return _G.tpmTemp.installed[name]
end

local function checkPack(url, name)
	local manifest = httpGetLines(BASE_URL..url.."/"..name.."/CCMANIFEST", true)
	local dependencies = httpGetLines(BASE_URL..url.."/"..name.."/CCDEPENDENCIES", false)
	
	if not manifest then
		printError("Package "..name.." is not properly structured.")
		return nil
	end

	local version = tonumber(manifest[1])
	local maintainer = manifest[2]

	if not dependencies then
		dependencies = {}
	end

	table.remove(manifest, 1)
	table.remove(manifest, 1)
	
	return {name = name, version = version, maintainer = maintainer, url = BASE_URL..url..name.."/", dependencies = dependencies, files = manifest}
end

local function checkDir(url)
	local index = httpGetLines(BASE_URL..url.."CCINDEX", true)

	if not index then
		return
	end

	for i, v in ipairs(index) do
		if v:sub(-1) == "/" then
			get(url)[v:sub(1,-2)] = {}
			checkDir(url..v)
		else
			get(url)[v] = checkPack(url, v)
		end
	end
end

local function listEntries(url, rtn)
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

local function getPackageList()
	local rtn = {}
	listEntries("", rtn)
	return rtn
end

local function getInstalledPackages()
	return _G.tpmTemp.installed
end

local function getInstalledList()
	local keys = {}
	
	for k, v in pairs(_G.tpmTemp.installed) do
		table.insert(keys, k)
	end
	return keys
end

local function saveDatabase()
	write("Saving database... ")
	local file = fs.open(".tpm", "wb")
	local data = textutils.serialise({database = _G.tpmTemp.database, installed = _G.tpmTemp.installed})
	file.write(data)
	file.close()
	print("Done")
end

local function reloadDatabase()
	write("Reading package list... ")
	local file = fs.open(".tpm", "r")

	if not file then
		print("Missing Database.")
		return
	end

	local data = textutils.unserialise(file.readAll())
	_G.tpmTemp.database = data.database
	_G.tpmTemp.installed = data.installed
	file.close()
	print("Done.")
end

local function updateDatabase()

	reloadDatabase()

	write("Connecting... ")
	local err = httpGet(BASE_URL.."CCINDEX")
	if not err then
		printError("Failed.")
		return
	end
	print("Success.")

	write("Updating package list... ")
	checkDir("")
	print("Done.")

	saveDatabase()
end

local function getPackage(url)
	reloadDatabase()

	if not get(url) then
		printError("Unable to locate package '"..url.."'.")
		return
	end

	if not get(url).name then
		printError("Unable to locate package '"..url.."'.")
		return
	end
	
	return get(url)
end

local function resolveDependencies(url, previous)

	for i, v in ipairs(previous) do
		if v == url then
			printError("Circular dependency detected between "..url.." and "..previous[1]..".")
			return nil
		end
	end

	table.insert(previous, 1, url)

	if not get(url) then
		printError("Unable to locate package '"..url.."' while resolving dependencies.")
		return nil
	end

	local dependencies = get(url).dependencies

	if not dependencies then
		get(url)["dependencies"] = {}
		return {}
	end

	local set = {}

	for i, v in ipairs(dependencies) do
		set[v] = true
		local dep = resolveDependencies(v, previous)
		if dep then
			for i2, v2 in pairs(dep) do
				set[v2] = true
			end
		else
			return nil
		end
	end

	local list = {url}

	for k, v in pairs(set) do
		if v then
			table.insert(list, k)
		end
	end

	return list
end

local function checkDependencies(url)
	if not get(url) then
		printError("Unable to locate package '"..url.."' while checking dependencies.")
		return nil
	end

	local dependencies = get(url).dependencies

	if not dependencies then
		get(url)["dependencies"] = {}
		return true
	end

	for i, v in ipairs(dependencies) do
		local check = false
		for i2, v2 in ipairs(getInstalledList()) do
			if v2 == v then
				check = true
				break
			end
		end

		if not check then
			return false
		end
	end

	return true
end

local function install(url, dep, force)

	dep = dep or false
	force = force or false

	reloadDatabase()

	if not get(url) then
		printError("Unable to locate package '"..url.."'.")
		return 0
	end

	for k, v in pairs(_G.tpmTemp.installed) do
		if k == url then
			printError("The package is already installed.")
			return 0
		end
	end

	local count = 0

	if not dep and not checkDependencies(url) then
		local prelist = resolveDependencies(url, {})

		if not prelist then
			print("Cannot resolve dependencies.")
			return 0
		end

		local list = {}

        for i, v in ipairs(prelist) do
			local flag = true
            for k, v2 in pairs(_G.tpmTemp.installed) do
			    if v == k then
				   flag = false
			    end
           end
			if flag then
				table.insert(list, v)
			end
        end

		print("The following package(s) will be installed:")
		print(table.concat(list, ", "))

		local a

		if not force then
			write("Do you want to continue ? [Y/n] ")

			a = read()
		else
			a = "yes"
		end

		if a == "n" or a == "N" then
			return 0
		end

		table.remove(list, 1)

		for i, v in ipairs(list) do
			print("Installing "..v.."...")
			install(v, true)
			count = count + 1
		end

		print("Installing "..url.."...")
	end
	
	print("Fetching files...")

	local error = 0
	
	for i, v in ipairs(get(url).files) do
		print("GET: "..v)
		local content = httpGet(BASE_URL..url.."/"..v)

		if not content then
			error = error + 1
		else
			local file = fs.open(v, "wb")
			file.write(content)
			file.close()
		end
	end

	local name = ""
	local urls = ""

	for v in url:gmatch("[^/]+") do
		urls = urls..name
		name = v
	end
	
	local pack = checkPack(urls, name)

	if pack then
		_G.tpmTemp.installed[url] = pack
		_G.tpmTemp.installed[url].installedAsDependency = dep
	end
	
	saveDatabase()

	count = count + 1

	if error == 0 then
		print("Package successfully installed.")
	else
		print("Package installed with errors.")
	end
	return count
end

local function remove(url, force)

	reloadDatabase()

	if not _G.tpmTemp.installed[url] then
		printError("Package "..url.." is not installed.")
		return false
	end

	if not force and _G.tpmTemp.installed[url].installedAsDependency then
		print(url.." is flagged as dependency.")

		write("Do you want to continue ? [y/N] ")

		local a = read()

		if a ~= "y" and a ~= "Y" then
			return false
		end
	end
	
	print("Deleting files...")
	
	for i, v in ipairs(_G.tpmTemp.installed[url].files) do
		print("DEL: "..v)
		fs.delete(v)
	end
	
	_G.tpmTemp.installed[url] = nil
	
	saveDatabase()
	
	print("Package successfully removed.")
	return true
end

return {BASE_URL = BASE_URL, httpGet = httpGet, httpGetLines = httpGetLines, reloadDatabase = reloadDatabase, updateDatabase = updateDatabase, saveDatabase = saveDatabase, get = get, getInstalled = getInstalled, getPackage = getPackage, getPackageList = getPackageList, getInstalledPackages = getInstalledPackages, getInstalledList = getInstalledList, install = install, remove = remove}
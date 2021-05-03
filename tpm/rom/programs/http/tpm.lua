local BASE_URL = "https://raw.githubusercontent.com/Deleranax/ComputerCraft-Projects/master/"
projects = {}

function complete(shell, index, arg, prev)
	rtn = {}
	if index == 1 then
		rtn = { "update",  "install", "remove" }
	elseif index == 2 then
		if projects[args[2]] ~= nil then
			for k, v in pairs(projects) do
				table.insert(rtn, k)
			end
		end
	end
	
	rtn2 = {}
	
	for i, v in ipairs(rtn) do
		if v:find(arg) ~= nil then
			table.insert(rtn2, v)
		end
	end
	
	return rtn2
end

function getFile(url)
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

function getProjectData(name)
    local pURL = getFile(BASE_URL..name.."/CCMANIFEST")
    
    if not pURL then
        return nil
    end
    
    local files = {}
    
    for v in pURL:gmatch("[^\r\n]+") do
        table.insert(files, v)
    end
    
    return files
end

function buildData()
    write("Connecting...")
    
    local pList = getFile(BASE_URL.."CCINDEX")
    
    print("Done.\n\nBuilding Database...")
    
    for name in pList:gmatch("[^\r\n]+") do
        print("Found "..name)
		projects[name] = getProjectData(name)
    end
	print("Done.")
end

function printUsage()
	print("Usages:")
	print("tpm update")
	print("tpm install <name>")
	print("tpm remove <name>")
end

args = { ... }

shell.setCompletionFunction("rom/programs/http/tpm.lua", complete)

if args < 2 or args > 3 then
	printUsage()
end

if args[1] == "update" then
	buildData()
elseif args[1] == "install" then
	if projects[args[2]] ~= nil then
		print("Downloading...")
		for k, v in ipairs(projects[args[2]]) do
			print(v)
			f = fs.open(v, "wb")
			f.write(getFile(BASE_URL..args[2]]..name.."/"..v))
			f.close()
		end
		print("Done.")
	else
		printError("Can't find program. (try to run \"tpm update\")")
	end
elseif args[1] == "remove" then
	if projects[args[2]] ~= nil then
		print("Removing...")
		for k, v in ipairs(projects[args[2]]) do
			print(v)
			fs.delete(v)
		end
		print("Done.")
	else
		printError("Can't find program. (try to run \"tpm update\")")
	end
end
local BASE_URL = "https://raw.githubusercontent.com/Deleranax/ComputerCraft-Projects/master/"
local projects = {type = "Group", root = true, content = {}}
local location = {}
local selection = 1
local backSelection = 1

shell.setPath(shell.path()..":/programs/:/programs/http/")

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

function getProjectData(name, url)
    local pURL = getFile(BASE_URL..url.."/CCMANIFEST")
    
    if not pURL then
        return nil
    end
    
    local files = {}
    
    for v in pURL:gmatch("[^\r\n]+") do
        table.insert(files, v)
    end
    
    return {type = "Data", url = BASE_URL..url.."/", files = files}
end

function formatWithGroups(name, url)
	if not name:find("/") then
		getWithLocation().content[name] = getProjectData(name, url)
	else
		if getWithLocation().content[name:sub(1, name:find("/"))] == nil then
			getWithLocation().content[name:sub(1, name:find("/"))] = {type = "Group", content = {}}
		end
		go(name:sub(1, name:find("/")))
		formatWithGroups(name:sub(name:find("/") + 1), url)
		back()
	end
end

function getWithLocation()
	local rtn = projects
	for i, v in ipairs(location) do
		rtn = rtn.content[v]
	end
	
	return rtn
end

function go(loc)
	loc:gsub("/", "")
	
	if getWithLocation().content[loc].content ~= nil then
		table.insert(location, loc)
	end
	
	selection = 1
end

function back()
	table.remove(location, table.maxn(location))
end

function buildData()
    write("Connecting...")
    
    local pList = getFile(BASE_URL.."CCINDEX")
    
    print("Done.\n\nBuilding Database...")
    
    for name in pList:gmatch("[^\r\n]+") do
        print("Found "..name)
        formatWithGroups(name, name)
    end
	print("Done.")
end

function centerWrite(text, y)
	local w, h = term.getSize()
	
	term.setCursorPos((w/2 - text:len()/2) + 1, y)
	term.write(text)
end

function drawMenu()
	term.clear()
	
	centerWrite("Temver Installation Software", 3)
	centerWrite("© 2021 Temver, All Rights Reserved", 18)
	
	local cLoc = getWithLocation().content
	
	local render = false
	
	if selection < 1 then
		selection = 1
	end
	
	local i = 1
	for k, v in pairs(cLoc) do
		if (v.type == "Group") then
			if selection == i then
				centerWrite("[ "..k.." ]",4 + i)
				render = true
			else
				centerWrite(k,4 + i)
			end
			i = i + 1
		end
	end
	
	for k, v in pairs(cLoc) do
		if (v.type == "Data") then
			if selection == i then
				centerWrite("[ "..k.." ]",4 + i)
				render = true
			else
				centerWrite(k,4 + i)
			end
			i = i + 1
		end
	end
	
	backSelection = i

	if getWithLocation().root then
		if selection == i then
			centerWrite("[ Cancel ]", 16)
			render = true
		else
			centerWrite("Cancel", 16)
		end
	else
		if selection == i then
			centerWrite("[ Back ]", 16)
			render = true
		else
			centerWrite("Back", 16)
		end
	end
	
	 if not render then
		 selection = selection - 1
		 drawMenu()
	 end
	
end

buildData()
sleep(1)

function main()
	while true do
		drawMenu()
		local event, key = os.pullEvent( "key" )
		
		if key == keys.enter then
			
			if selection == backSelection then
				if getWithLocation().root then
					term.clear()
					term.setCursorPos(1,1)
					return
				end
				back()
			end
			
			i = 1
			for k, v in pairs(getWithLocation().content) do
				if i == selection then
					if getWithLocation().content[k].type == "Data" then
						term.clear()
						term.setCursorPos(1, 1)
						print("Downloading...")
						for l, b in ipairs(getWithLocation().content[k].files) do
							print(b)
							f = fs.open(b, "wb")
							f.write(getFile(getWithLocation().content[k].url..b))
							f.close()
						end
						print("Done.")
						return
					end
					go(k)
					break
				else
					i = i + 1
				end
			end
		elseif key == keys.up then
			selection = selection - 1
		elseif key == keys.down then
			selection = selection + 1
		end
	end
end

main()
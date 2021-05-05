local tpm = require("tpm-api")

function completion(shell, index, arg, args)
	local rtn = {}

	if index == 1 then
		rtn = {"update", "upgrade", "list ", "show ", "install ", "reinstall ", "remove "}
	elseif index == 2 then
		if args[2] == "install" then
			rtn = tpm.getPackageList()
		elseif args[2] == "remove" then
			rtn = tpm.getInstalledList()
		elseif args[2] == "list" then
			rtn = {"installed", "available"}
		elseif args[2] == "show" then
			rtn = tpm.getPackageList()
		end
	end

	if arg == "" then
		return rtn
	end
	
	local frtn = {}
	for i, v in ipairs(rtn) do
		if arg == v:sub(1, arg:len()) then
			local text = v:gsub(arg, "", 1)
			table.insert(frtn, text)
		end
	end

	return frtn
end

function showUsage()
	print("Usage: ")
	print("tpm update")
	print("tpm upgrade")
	print("tpm list <installed/available>")
	print("tpm show <program>")
	print("tpm install <program>")
	print("tpm reinstall <program>")
	print("tpm remove <program>")
end

shell.setCompletionFunction("tpm.lua", completion)

args = { ... }

if table.getn(args) == 1 then
	if args[1] == "help" then
		showUsage()
	elseif args[1] == "update" then
		tpm.updateDatabase()
		local outdated = false
		for k, v in pairs(tpm.getInstalledPackages()) do
			if v.version ~= get(k)["version"] then
				print(v.." needs update (v"..v.version.." -> v"..get(k)["version"]..")")
				outdated = true
			end
			if outdated then
				print("To update packets, run 'tpm upgrade'")
			end
		end
	elseif args[1] == "upgrade" then
		local update = 0
		for k, v in pairs(tpm.getInstalledPackages()) do
			if v.version ~= get(k)["version"] then
				update = update + 1
				print("Updating "..k.."...")
				tpm.remove(k)
				tpm.install(k)
			end
		end
		if update == 0 then
			print("All packages are up to date")
			return
		end
		print(update.." upgraded, 0 newly installed")
	else
		printError("Invalid command. Run 'tpm help' to show usage.")
		return
	end
elseif table.getn(args) == 2 then
	if args[1] == "install" then
		tpm.install(args[2])
	elseif args[1] == "reinstall" then
		if tpm.remove(args[2]) then
			tpm.install(args[2])
		end
	elseif args[1] == "remove" then
		tpm.remove(args[2])
	elseif args[1] == "show" then
		local pack = tpm.getPackage(args[2])
		if not pack then
			return
		end
		print("Package: "..pack.name)
		print("Version: "..pack.version)
		print("Maintainer: "..pack.maintainer)
		print("TPM-Source: "..pack.url)
	elseif args[1] == "list" then
		if args[2] == "installed" then
			tpm.reloadDatabase()
			print("\nInstalled packages:")
			print(table.concat(tpm.getInstalledList(), ", "))
		elseif args[2] == "available" then
			tpm.reloadDatabase()
			print("\nAvailable packages:")
			print(table.concat(tpm.getPackageList(), ", "))
		else
			printError("Invalid command. Run 'tpm help' to show usage.")
		end
	else
		printError("Invalid command. Run 'tpm help' to show usage.")
		return
	end
elseif table.getn(args) == 0 then
	showUsage()
else
	printError("Invalid command. Run 'tpm help' to show usage.")
end
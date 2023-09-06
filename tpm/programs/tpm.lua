local tpm = require("/apis/tpm-api")

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

args = { ... }

if table.getn(args) == 1 then
	if args[1] == "help" then
		showUsage()
	elseif args[1] == "update" then
		tpm.updateDatabase()
		local outdated = false
		for k, v in pairs(tpm.getInstalledPackages()) do
			if (get(k) == nil) then
				print(k.." is no longer available, or the package was renamed.")
			elseif v.version ~= get(k)["version"] then
				print(k.." needs update (v"..v.version.." -> v"..get(k)["version"]..")")
				outdated = true
			end
		end
		if outdated then
			print("To update packets, run 'tpm upgrade'.")
		end
	elseif args[1] == "upgrade" then
		local update = 0
		for k, v in pairs(tpm.getInstalledPackages()) do
			if v.version ~= get(k)["version"] then
				update = update + 1
				print("\nUpdating "..k.."...")
				tpm.remove(k)
				tpm.install(k)
			end
		end
		if update == 0 then
			print("All packages are up to date.")
			return
		end
		print(update.." upgraded, 0 newly installed.")
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
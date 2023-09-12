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

function clean()
	local dependencies = {}

	local count = 0

	for k, v in pairs(tpm.getInstalledPackages()) do
		if v.dependencies then
			for i, v2 in ipairs(v.dependencies) do
				dependencies[v2] = true
			end
		else
			v.dependencies = {}
		end
	end

	for k, v in pairs(tpm.getInstalledPackages()) do
		if v.installedAsDependency and not dependencies[k] then
			print(k.." will be removed.")
			if tpm.remove(k, false) then
				count = count + 1
			end
		end
	end

	if count ~= 0 then
		count = count + clean()
	end

	return count
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
		local installed = 0
		for k, v in pairs(tpm.getInstalledPackages()) do
			if (get(k) == nil) then
				print(k.." is no longer available, skipping.")
			elseif v.version ~= get(k)["version"] then
				update = update + 1
				print("\nUpdating "..k.."...")
				tpm.remove(k, true)
				installed = installed + tpm.install(k, false) - 1
			end
		end
		if update == 0 then
			print("All packages are up to date.")
			return
		end
		print(update.." upgraded, "..installed.." newly installed.")
	elseif args[1] == "clean" then
		local count = clean()
		if clean() == 0 then
			print("No useless packages detected.")
		else
			print(count.." removed.")
		end
	else
		printError("Invalid command. Run 'tpm help' to show usage.")
		return
	end
elseif table.getn(args) == 2 then
	if args[1] == "install" then
		installed = tpm.install(args[2], false)
		print("0 upgraded, "..installed.." newly installed.")
	elseif args[1] == "reinstall" then
		if tpm.remove(args[2], true) then
			installed = tpm.install(args[2], false) - 1
		end
		print("0 upgraded, "..installed.." newly installed.")
	elseif args[1] == "remove" then
		tpm.remove(args[2], false)
		print("Use 'tpm clean' to clean any useless dependency.")
	elseif args[1] == "show" then
		local pack = tpm.getPackage(args[2])
		if not pack then
			return
		end
		print("Package: "..pack.name)
		print("Version: "..pack.version)
		print("Maintainer: "..pack.maintainer)
		print("TPM-Source: "..pack.url)

		if pack.dependencies then
			if table.getn(pack.dependencies) ~= 0 then
				print("Dependencies:")
				print(table.concat(pack.dependencies, ", "))
			end
		else
			pack.dependencies = {}
		end

		if pack.installedAsDependency then
			print("The package is flagged as dependency.")
		end

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
local tpm = require("/apis/tpm-api")
shell.setPath(shell.path()..":/programs/:/programs/http/")

tpm.reloadDatabase()

function completion(shell, index, arg, args)
	local rtn = {}

	if index == 1 then
		rtn = {"help", "update", "upgrade", "list ", "show ", "install ", "reinstall ", "remove ", "clean "}
	elseif index == 2 then
		if args[2] == "install" then
			rtn = tpm.getPackageList()
		elseif args[2] == "remove" or args[2] == "reinstall" then
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

shell.setCompletionFunction("programs/tpm.lua", completion)
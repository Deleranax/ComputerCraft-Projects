if not fs.exists("/startup") then
	fs.mkdir("startup")
end

for i, v in ipairs(fs.list("startup")) do
	local ok, err = pcall(function() shell.run("program") end)

	if not ok then
		printError("Error when executing startup task #"..i)
		printError(err)
	end
end
M = {}

M.nuget_search = function(reference, exec, extraArgs)
	local cli = vim.list_extend({ exec }, extraArgs)
	table.insert(cli, reference)
	local output = vim.system(cli):wait()

	if output.code ~= 0 or not output.stdout then
		error("Failed to find package. See nuget response:\n" .. output.stderr)
	end

	return output.stdout
end

M.nuget_search_async = function(reference, exec, extraArgs, callback)
	--cli list becomes something like { 'dotnet', 'package', 'search', ... }
	local cli = vim.list_extend({ exec }, extraArgs)
	table.insert(cli, reference)

	vim.system(cli, {}, callback)
end

return M

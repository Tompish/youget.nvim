M = {}

---Use dotnetcli nuget to search synchronously
---@param reference string: name of the reference, eg Newtonsoft.Json
---@param exec string: path to executable or simply dotnet
---@param extra_args string: extra arguments
---@return table: stdout of the exec
M.nuget_search = function(reference, exec, extra_args)
	local cli = vim.list_extend({ exec }, extra_args)
	table.insert(cli, reference)
	local output = vim.system(cli):wait()

	if output.code ~= 0 or not output.stdout then
		error("Failed to find package. See nuget response:\n" .. output.stderr)
	end

	return output.stdout
end

---Use dotnetcli nuget to search asynchronously
---@param reference string: name of the reference, eg Newtonsoft.Json
---@param exec string: path to executable or simply dotnet
---@param extra_args string: extra arguments
---@param callback string: callback once the cli finishes
M.nuget_search_async = function(reference, exec, extra_args, callback)
	--cli list becomes something like { 'dotnet', 'package', 'search', ... }
	local cli = vim.list_extend({ exec }, extra_args)
	table.insert(cli, reference)

	vim.system(cli, {}, callback)
end

return M

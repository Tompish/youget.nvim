M = {}

local nuget_util = require("youget.nuget")
local parser = require("youget.response_parsers")
local integrations = require("youget.telescope_integration")
local utils = require("youget.utils")



M._options = {
	cli = {'package', 'search', '--format', 'json' },
	dotnet_path = 'dotnet',
}

M.setup = function(opts)
	if opts.include_prerelease == true then
		table.insert(M._options.cli, '--prerelease')
	end
	M._options.dotnet_path = opts.dotnet_path or 'dotnet'
end

---when standing on a valid package reference in a csproj, this function
---automatically update it to latest version
M.update = function()

	local parsed_line = utils.read_current_line()
	local package_data = utils.Package_data:parse(parsed_line.text)

	local cmd = vim.list_extend({}, M._options.cli)
	vim.list_extend(cmd, {'--verbosity', 'minimal'})

	local callback = function(output)
		if output.code ~= 0 or not output.stdout then
			error("Failed to find package. See nuget response:\n" .. output.stderr)
		end
		local decoded_response = vim.json.decode(output.stdout)
		local _, pkg = parser.first_available_pkg(decoded_response)

		package_data:update_version(pkg.latestVersion)

		vim.schedule(
			function()
			vim.fn.setline(parsed_line.line_nr, package_data:to_line())
		end)
	end

	nuget_util.nuget_search_async(package_data:get_reference(), M._options.dotnet_path, cmd,  callback)

end

---when standing on a valid package reference in a csproj, this function
---displays all versions which can be chosen from
M.choose = function()
	local parsed_line = utils.read_current_line()
	local package_data = utils.Package_data:parse(parsed_line.text)

	local cmd = vim.list_extend({}, M._options.cli)
	vim.list_extend(cmd, { '--exact-match', '--verbosity', 'detailed'})

	local nugetResponse = nuget_util.nuget_search(package_data:get_reference(), M._options.dotnet_path, cmd)
	local decoded_response = vim.json.decode(nugetResponse)

	local pkgs = parser.parse_exact_match(decoded_response)

	local preview = integrations.gen_preview_basic(function(entry)

	local description = vim.split(entry.value.description, '\n')
	return vim.list_extend({
	'ProjectUrl: ' .. entry.value.project_url
	,''
	, '-------------------Description-------------------'
	}, description)
	end)
	local entry_mkr = function(package)
		return {
			value = package,
			display = package.id .. ' ' .. package.version,
			ordinal = package.version
		}
	end

	local callback = function(selected_line)
		package_data:update_version(selected_line.value.version)
		vim.fn.setline(parsed_line.line_nr, package_data:to_line())
	end

	integrations.open_with_results({}, pkgs, entry_mkr, preview, callback)
end

---Add a package to the csproj file. Can be called from anywhere within a C# project
M.add = function(opts)
	opts = opts or {}
	opts.dotnet_path = M._options.dotnet_path
	opts.cli = vim.list_extend({}, M._options.cli)
	vim.list_extend(opts.cli, { '--verbosity', 'detailed' })

	local bufname = vim.fn.bufname()
	local s = string.find(bufname, '.csproj')

	local action = function() end

	if s then
		action = utils.add_by_buf
	else
		action = utils.gen_add_by_cli(opts)
	end

	local list_package = function(package)
		return {
			value = package,
			display = package.source .. ' ' .. package.id,
			ordinal = package.id
		}
	end

local preprocess_data = function(data)
	local result = vim.json.decode(data)
	local pkgs = parser.parse_detailed(result)
	return pkgs
end


local preview = integrations.gen_preview_basic(function(entry)
	local description = vim.split(entry.value.description, '\n')
	return vim.list_extend({ 'Owners: ' .. entry.value.owners
	,''
	, 'Downloads: ' .. entry.value.downloads
	,''
	, 'ProjectUrl: ' .. entry.value.project_url
	,''
	, '-------------------Description-------------------'
}, description)
end)

integrations.open_live(opts, list_package, preprocess_data, preview, action)

end

return M

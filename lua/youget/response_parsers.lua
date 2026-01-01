local response_parsers = {}

response_parsers.parse_minimal = function(nuget_json)
		local o = {}
		local index = 1
		for _, source in ipairs(nuget_json.searchResult) do
			for _, pkg in ipairs(source.packages) do
				o[index] = {
					id = pkg.id,
					version = pkg.latestVersion,
					source = source.sourceName,
				}
				index = index+1
			end
		end
		return o
	end

response_parsers.first_available_pkg = function(nuget_json)
	for _, source in pairs(nuget_json.searchResult) do
		if #source.packages > 0 then
			return source.sourceName, source.packages[1]
		end
	end

	error("Could not find any packages")
end

response_parsers.parse_detailed = function(nuget_json)
		local o = {}
		local index = 1
		for _, source in ipairs(nuget_json.searchResult) do
			for _, pkg in ipairs(source.packages) do
				o[index] = {
					id = pkg.id,
					version = pkg.latestVersion,
					source = source.sourceName,
					downloads = pkg.totalDownloads or '-',
					owners = pkg.owners or '-',
					project_url = pkg.projectUrl or '-',
					description = pkg.description or 'No description found'
				}
				index = index+1
			end
		end

		return o
	end

response_parsers.parse_exact_match = function(nuget_json)
		local o = {}
		local index = 1
		for _, source in ipairs(nuget_json.searchResult) do
			for _, pkg in ipairs(source.packages) do
				o[index] = {
					id = pkg.id,
					version = pkg.version,
					source = source.sourceName,
					downloads = pkg.totalDownloads or '-',
					owners = pkg.owners or '-',
					project_url = pkg.projectUrl or '-',
					description = pkg.description or 'No description found'
				}
				index = index+1
			end
		end

		return o
	end
return response_parsers

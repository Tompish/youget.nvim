local Utils= {}

---@class Package_data
---A class that structures the reference package string in a csproject into a manageable format
Utils.Package_data = {}

---Parses a package line in a csproj file and returns it as an object
---@param text string
---@return Package_data
function Utils.Package_data:parse(text)
	local o = {}

	o.text = text
	o.elements = vim.split(text, '"')
	o.ref_index = 0
	o.version_index = 0

	for i, v in ipairs(o.elements) do
		if string.match(v, 'Include=') then
			o.ref_index = i+1
		elseif string.match(v, 'Version=') then
			o.version_index = i+1
		end
	end

	if o.version_index == 0 or o.ref_index == 0 then
		error("Could not parse the current line. Is it a valid package reference?")
	end

	return setmetatable(o, { __index = self })
end

---Updates the version internally of the referenced project
---@param version string
---@return Package_data
function Utils.Package_data:update_version(version)
	self.elements[self.version_index] = version
	return self
end

---Gets the current version of the referenced project
---@param
---@return string
function Utils.Package_data:get_version()
	return self.elements[self.version_index]
end

---Gets the current package name of the referenced project
---@param
---@return string
function Utils.Package_data:get_reference()
	return self.elements[self.ref_index]
end

---Rebuilds the Package_data into a string that can be directly inserted into the csproj
---@param
---@return string
function Utils.Package_data:to_line()
	return table.concat(self.elements, '"')
end

---With a given reference and version, constructs a string that can be directly inserted into the csproj
---@param reference string: Package name
---@param version string: Package version
---@return string
function Utils.Package_data.construct_new_line(reference, version)
return '<PackageReference Include="' .. reference ..'" Version="' .. version .. '" />'
end

---OBSOLETE, finds the csproj-file
---@return line string
Utils.find_csproj = function()
	local home_dir = vim.uv.os_homedir()

	local res = vim.fs.find(function(name, _)
		local s, _ = string.find(name, '.csproj')
		return s ~= nil
	end,
	{
		upward = true,
		type = 'file',
		limit = 1,
		stop = home_dir
	})

	if #res == 0 then
		error("Cannot find any csproj file")
	end
	return res[1]
end

---read the line at the cursor and save the text and line number
---@return table: {line_nr, text}
Utils.read_current_line = function()
	local curr_line = {}
	curr_line = {
		line_nr = vim.fn.line('.'),
		text = vim.fn.getline("."),
	}

	return curr_line
end

---used as a callback function by telescope, once a user has chosen the result
---This function uses buffers to add a package reference. It should only be used if 
---the csproject-file is an active buffer
---@param entry table: entry is passed by telescope functions
Utils.add_by_buf = function(entry)
		entry = entry.value
		local content = vim.api.nvim_buf_get_lines(0, 1, -1, false)
		local insert_row = 0
		local rows = {}

		for i, line in ipairs(content) do
			local s_i = string.find(line, '<PackageRefe')
			if s_i then
				insert_row = i-1
				local tabstop = string.sub(line, 1, s_i-1)
				table.insert(rows, tabstop .. Utils.Package_data.construct_new_line(entry.id, entry.version))
				break
			end
		end
		if insert_row == 0 then
			for i = #content, 0, -1 do
				if string.find(content[i], '</Projec') then
					insert_row = i-1
					table.insert(rows, '  <ItemGroup>')
					table.insert(rows, '    ' .. Utils.Package_data.construct_new_line(entry.id, entry.version))
					table.insert(rows, '  </ItemGroup>')
					table.insert(rows, '')
					break
				end
			end
		end
			vim.api.nvim_buf_set_lines(0, insert_row, insert_row, nil, rows)
		end

---used as a callback function by telescope, once a user has chosen the result
---This function uses dotnet cli to add a package reference. It should only be used if 
---the csproject-file is an hidden or non existing buffer
---@param opts table: if a dotnet_path is given in setup
---@return function
Utils.gen_add_by_cli = function(opts)
	return function(entry)
			entry = entry.value
			vim.system(vim.list_extend({ opts.dotnet_path }, { 'package', 'add', entry.id,'-v', entry.version})
			, {}
			, function(output)
				if output.code ~= 0 then

					local err_msg = output.stderr
					if err_msg == "" or not err_msg then
						err_msg = output.stdout
					end
					error('Error adding nuget. See dotnet cli error message:\n' .. (err_msg or ""))
				end
			end)
		end
	end

return Utils

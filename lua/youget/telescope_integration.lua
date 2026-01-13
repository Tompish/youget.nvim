local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local async_job = require "telescope._"
local LinesPipe = require("telescope._").LinesPipe
local make_entry = require "telescope.make_entry"
local log = require "telescope.log"

---This is a remake of telescopes async job finder.
---JSON cannot be processed line by line, so this is a modified
---telescope job that additionally accepts opts.preprocess_res
---@param opts table: standard telescope opts + preprocess_res
---@return table table
local custom_async_job_finder = function(opts)
	log.trace("Creating custom async_job:", opts)
	local entry_maker = opts.entry_maker or make_entry.gen_from_string(opts)
	local preprocess_res = opts.preprocess_res or function(res) return res end

	local fn_command = function(prompt)
		local command_list = opts.command_generator(prompt)
		if command_list == nil then
			return nil
		end

		local command = table.remove(command_list, 1)

		local res = {
			command = command,
			args = command_list,
		}

		return res
	end

	local job

	local callable = function(_, prompt, process_result, process_complete)
		if job then
			job:close(true)
		end

		local job_opts = fn_command(prompt)
		if not job_opts then
			process_complete()
			return
		end

		local writer = nil
		-- if job_opts.writer and Job.is_job(job_opts.writer) then
		--   writer = job_opts.writer
		if opts.writer then
			error "async_job_finder.writer is not yet implemented"
			writer = async_job.writer(opts.writer)
		end

		local stdout = LinesPipe()

		job = async_job.spawn {
			command = job_opts.command,
			args = job_opts.args,
			cwd = job_opts.cwd or opts.cwd,
			env = job_opts.env or opts.env,
			writer = writer,

			stdout = stdout,
		}

		local data = ''
		for line in stdout:iter(true) do
			data = data .. line
		end

		local processed_data = preprocess_res(data)

		for i,line in ipairs(processed_data) do
			local entry = entry_maker(line)
			if entry then
				entry.index = i
			end
			if process_result(entry) then
				return
			end
		end

		process_complete()
	end

	return setmetatable({
		close = function()
			if job then
				job:close(true)
			end
		end,
	}, {
		__call = callable,
	})
end

---Wrapper around custom job. Following telescopes way of coding for 
---easy use
local new_custom_job = function(command_generator, entry_maker, _, cwd, preprocess_res)
	return custom_async_job_finder {
		command_generator = command_generator,
		entry_maker = entry_maker,
		cwd = cwd,
		preprocess_res = preprocess_res
	}
end

M = {}

---Open a telescope popup with a result set that is already loaded
---@param opts table: standard telescope opts
---@param selectables table: list containing the results
---@param entry_mkr function: fun(selectables) -> { value, display, ordinal }
---@param preview function: fun(self, state, entry) Defines preview
---@param callback function: fun(selectedEntry) Called once a user has chosen an option
M.open_with_results = function(opts, selectables, entry_mkr, preview, callback)
	pickers.new(opts, {
		prompt_title = "Versions",
		finder = finders.new_table {
			results = selectables,
			entry_maker = entry_mkr
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(
				function()
					actions.close(prompt_bufnr)
					callback(action_state.get_selected_entry())
				end)
				return true
			end,
		previewer = previewers.new_buffer_previewer({
			define_preview = preview,
			title = 'Detailed View'
		})
		}):find()
	end

---Open a telescope popup with a result set that is loaded asynchronosly with live updates
---from user inputs
---@param opts table: standard telescope opts
---@param entry_mkr function: fun(selectables) -> { value, display, ordinal }
---@param preproccess_res function: function that processes the result from nuget, before being passed on
---to telescopes ordinary execution flow
---@param preview function: fun(self, state, entry) Defines preview
---@param action function: fun(selectedEntry) Called once a user has chosen an option
	M.open_live = function(opts, entry_mkr, preproccess_res, preview, action)
		assert(opts.cli, "Trying to live search nugets without giving a dotnet command!")

		local cwd = opts.cwd or vim.uv.cwd()

		local nuget_finder = new_custom_job(function(prompt)
			if not prompt or prompt == "" then
				return nil
			end
			local cmd = { opts.dotnet_path }
			vim.list_extend(cmd, opts.cli)

			table.insert(cmd, prompt)

			return cmd
		end,
		entry_mkr,
		{},
		cwd,
		preproccess_res
	)

	pickers
	.new(opts, {
		prompt_title = "Results",
		finder = nuget_finder,
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(
				function()
					actions.close(prompt_bufnr)
					action(action_state.get_selected_entry())
				end)
			return true
		end,
		previewer = previewers.new_buffer_previewer({
			define_preview = preview,
			title = 'Detailed View'
		})
	})
	:find()
end

---Generates a previewer that displays whatever table fn returns
---@param fn function: fn(entry) -> string[] writes each element of returned table on seperate row
---to the preview buffer. The function should accept whatever was defined as an "entry"
---@return function
M.gen_preview_basic = function(fn)
	return function(self, entry, _)
		vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, fn(entry))
	end
end

return M

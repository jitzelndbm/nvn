--- These are actions that edit the file structure of the notes folder.
-- @module structure
local structure = {}

-- imports
local navigation = require'nvn.actions.navigation'
local utils = require'nvn.utils'

--- Remove the current note a go back to the previous
--- @param pages Array(string)
structure.remove_current_note = function (pages)
	local result = (function ()
		while true do
			local result = string.upper(vim.fn.input("Are you sure you want delete the current file? [y/n] "))
			return (result == "Y")
		end
	end)()

	if not result then
		return
	end

	local file_to_delete = vim.api.nvim_buf_get_name(0)
	vim.api.nvim_buf_delete(0, {force = true})
	navigation.previous_page(pages)
	os.remove(file_to_delete)
end

local function replace_link(line_number, new_label, new_url, old_label, old_url)
	local line = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, true)[1]

	if old_label == "Terug" then
		line = line:gsub(
			"%[Terug%]%(" .. old_url .. "%)",
			"[Terug](" .. new_url .. ")"
		)
	else
		line = line:gsub(
			"%[" .. old_label .. "%]%(" .. old_url .. "%)",
			"[" .. new_label .. "](" .. new_url .. ")"
		)
	end

	vim.api.nvim_buf_set_lines(0, line_number - 1, line_number, true, { line })
end

--- Rename a note and point all the links to the good url
---@param options table
structure.rename_current_note = function (options)
	-- Get the current note name
	local current_file_path = vim.api.nvim_buf_get_name(0)
	local current_file_name = vim.fs.basename(current_file_path)
	local root_folder = vim.fs.dirname(options.root)

	local new_url_text = vim.fn.input(string.format("New file name (%s) (omit the md extension): ", current_file_name))
	local new_link_label = vim.fn.input(string.format("New link name: "))

	local confirm = (function ()
		while true do
			local result = string.upper(vim.fn.input("Are you sure you want to rename this file? [y/n] "))
			return (result == "Y")
		end
	end)()

	-- confirm check and try to rename the file
	local success = os.rename(current_file_path, root_folder.."/"..new_url_text..".md")
	if not confirm and success then
		return
	end

	local note_files = vim.fs.find(function(name)
		return name:match('%.md$') or name:match('%.rem$')
		end, {limit = math.huge, type = 'file'})

	local index = 1
	for _, path in ipairs(note_files) do
		local link_added = false

		-- create a temporary buffer 
		vim.api.nvim_buf_call(0, function()
			-- enter the buffer scope by editing, the bufnr becomes 0
			vim.cmd.edit(path)

			local thj = 1
			for _, link in ipairs(utils.get_links()) do
				local start_row, _, link_label, url_text = unpack(link)
				if url_text..".md" == current_file_name or url_text == current_file_name then
					replace_link(start_row, new_link_label, new_url_text, link_label, url_text)
					link_added = true
					thj = thj + 1
				end
			end

			-- FIXME: unload the buffers
			--vim.api.nvim_buf_delete(0, {})
		end)

		if link_added then
			index = index + 1
		end
	end

	-- remove the old file
	os.remove(current_file_path)

	-- reattach to the buffer
	vim.cmd.edit(new_url_text..".md")
end

return structure

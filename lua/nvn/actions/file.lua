--- These are actions that edit a file's content
-- @module file
local file = {}

-- imports
local utils = require'nvn.utils'

-- Constants
local SECONDS_IN_DAY = 86400

--- Insert a date under the cursor
--- @param options table
file.insert_date = function (options)
	local date = tostring(os.date(options.date.format))

	if options.date.lowercase then
		date = date:lower()
	end

	utils.insert_text_at_pos(date)
end

--- Insert a future date under the cursor
---@param options table
file.insert_future_date = function (options)
	local f = vim.fn.input("Days ahead: ")

	if f == nil or f == '' then
		return 0
	end

	local date = tostring(os.date(options.date.format, os.time() + tonumber(f) * SECONDS_IN_DAY))

	if options.date.lowercase then
		date = date:lower()
	end

	utils.insert_text_at_pos(date)
end

file.increase_header_level = function ()
	local line_content = vim.api.nvim_get_current_line()
	if line_content:find("^######") then
		return nil
	end

	local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))

	if line_content:find("^#") then
		vim.cmd.norm("0i#")
	else
		vim.cmd.norm("0i# ")
	end

	vim.api.nvim_win_set_cursor(0,{my_row,my_column})
end

file.decrease_header_level = function ()
	local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))
	local line_content = vim.api.nvim_get_current_line()
	if line_content:find("^# ") then
		vim.cmd.norm("0xx")
	elseif line_content:find("^#") then
		vim.cmd.norm("0x")
	end
	vim.api.nvim_win_set_cursor(0,{my_row,my_column})
end

return file

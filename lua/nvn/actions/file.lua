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
end

file.decrease_header_level = function ()
end

return file

local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("nvn.util")

local SECONDS_IN_DAY = 86400

local M = {}

M.follow_link = function(pages)
	local node = ts_utils.get_node_at_cursor();

	---@cast node -nil
	local node_type = node:type();

	local url = nil
	if node_type == 'link_destination' or node_type == 'link_text' or node_type == 'link_description' then
		---@cast node -nil
		url = utils.process_link(utils.get_url_from_node(node:parent()))
	elseif node_type == 'inline_link' then
		url = utils.process_link(utils.get_url_from_node(node))
	else
		vim.cmd'norm! j'
	end

	if url ~= nil then
		pages[#pages+1] = url
	end

	return pages
end

M.next_link = function ()
	local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))

	local iterator = utils.get_links()
	for _,coords in pairs(iterator) do
		if (my_row == coords[1] and my_column < coords[2]) or my_row < coords[1] then
			vim.api.nvim_win_set_cursor(0, {coords[1],coords[2]})
			break
		elseif next(iterator,_) == nil then
			vim.api.nvim_win_set_cursor(0, {iterator[1][1],iterator[1][2]})
			break
		end
	end
end

M.previous_link = function ()
	local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))

	-- inverse the table of link coordinates 
	local temp = utils.get_links()
	local iterator = {}
	for i=#temp, 1, -1 do
		iterator[#iterator+1] = temp[i]
	end

	for _,coords in pairs(iterator) do
		if (my_row == coords[1] and my_column > coords[2]) or my_row > coords[1] then
			vim.api.nvim_win_set_cursor(0, {coords[1],coords[2]})
			break
		elseif next(iterator,_) == nil then
			vim.api.nvim_win_set_cursor(0, {iterator[1][1],iterator[1][2]})
			break
		end
	end
end

M.previous_page = function(pages)
	if #pages ~= 0 then
		vim.cmd.edit(pages[#pages-1])
		table.remove(pages)
	else
		vim.cmd.edit("index.md")
	end

	return pages
end

M.insert_date = function (options)
	local date = tostring(os.date(options.date.format))

	if options.date.lowercase then
		date = date:lower()
	end

	utils.insert_text_at_pos(date)
end

M.insert_future_date = function (options)
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

M.reload_folding = function ()
	vim.wo.foldmethod = 'syntax'
	vim.cmd[[let g:markdown_folding = 1]]
	vim.bo.filetype = 'markdown'
	vim.bo.ft='markdown'
end

M.go_home = function (pages, options)
	vim.cmd.edit(options.root)
	pages[#pages+1] = options.root
	return pages
end

return M

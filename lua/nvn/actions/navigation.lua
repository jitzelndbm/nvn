--- All the navigation actions are in this file
-- @module navigation
local navigation = {}

-- imports
local utils = require'nvn.utils'
local ts_utils = require'nvim-treesitter.ts_utils'

--- Function to follow the link that is under the cursor
--- @param pages Array(string)
--- @param options table
--- @return Array(string)
navigation.follow_link = function(pages, options)
	local node = ts_utils.get_node_at_cursor();

	---@cast node -nil
	local node_type = node:type();

	local url = nil
	if node_type == 'link_destination' or node_type == 'link_text' or node_type == 'link_description' then
		---@cast node -nil
		url = utils.process_link(utils.get_url_from_node(node:parent()), options)
	elseif node_type == 'inline_link' then
		url = utils.process_link(utils.get_url_from_node(node), options)
	else
		vim.cmd'norm! j'
	end

	if url ~= nil then
		pages[#pages+1] = url
	end

	return pages
end

--- Uses treesitter to find the next link in the current file
navigation.next_link = function ()
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

--- Use treesitter to find the previous link in the file and move the cursor to that link
navigation.previous_link = function ()
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

--- Go back to the previously visisted page, remove it from the pages register and return it.
---@param pages Array(string)
---@return Array(string)
navigation.previous_page = function(pages)
	if #pages ~= 0 then
		vim.cmd.edit(pages[#pages-1])
		table.remove(pages)
	else
		vim.cmd.edit("index.md")
	end

	return pages
end

---comment
---@param pages Array(string)
---@param options table
---@return Array(string)
navigation.go_home = function (pages, options)
	vim.cmd.edit(options.root)
	pages[#pages+1] = options.root
	return pages
end

return navigation

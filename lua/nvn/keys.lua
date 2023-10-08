local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

local function get_url_from_node(node)
	local node_text = vim.treesitter.get_node_text(node, 0)
	local node_dest = vim.split(node_text, '(', {plain=true})
	local url = node_dest[2]:sub(1,-2) -- rm last char
	return url
end
local function process_link(url)
	if url:find(".md$") then
		vim.cmd.edit(url)
		return url
	elseif url:find("%.%a+$") then
		os.execute('xdg-open ' .. vim.fn.shellescape(url) .. "&")
		return nil
	else
		url = url .. ".md"

		vim.cmd.edit(url)
		return url
	end
end
M.follow_link = function(pages)
	local node = ts_utils.get_node_at_cursor();
	local node_type = node:type();
	local url = nil
	if node_type == 'link_destination' or node_type == 'link_text' or node_type == 'link_description' then
		url = process_link(get_url_from_node(node:parent()))
	elseif node_type == 'inline_link' then
		url = process_link(get_url_from_node(node))
	else
		vim.cmd'norm! j'
	end

	if url ~= nil then
		pages[#pages+1] = url
	end

	return pages
end

local function get_links()
	-- TODO(refactor): extract to initialization 
	local language_tree = vim.treesitter.get_parser(0, "markdown_inline")
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()

	-- parse the query
	local parse_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link) @id]])

	local file_rows = tonumber(vim.fn.system({ 'wc', '-l', vim.fn.expand('%') })) or 0

	local iter = parse_query:iter_captures(root, 0, 0, file_rows)

	-- put all the links into a table
	local a = {}
	local i = 1
	for _, capture, _ in iter do
		local capture_row,capture_column,_ = capture:start()
		a[i] = {capture_row+1,capture_column}
		i = i + 1
	end

	return a
end
M.next_link = function ()
	local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))

	local iterator = get_links()
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
	local temp = get_links()
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

local function insert_text_at_pos(text,newline)
	if newline then
		vim.cmd[[norm o]]
	end
	local pos = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	local nline = line:sub(0, pos) .. string.format('%s',text:gsub('[\n\r]', '') or 'none: command not found or somehting') .. line:sub(pos + 1)
	vim.api.nvim_set_current_line(nline)
end
local function get_command_output(command)
	local handle = io.popen(command)
	local output = handle:read('*a')
	handle:close()
	return output
end
M.insert_date = function ()
	local date = get_command_output("date +'%V: (%a) %d-%b'")
	insert_text_at_pos(date)
end
M.insert_future_date = function ()
	local f = vim.fn.input("Days ahead: ")

	if f == nil or f == '' then
		return 0
	end

	local command = string.format("date --date='%d days' +'%%V: (%%a) %%d-%%b'", f)
	print(command)
	local date = get_command_output(command)
	insert_text_at_pos(date)
end
M.new_appo = function ()
	local days = vim.fn.input("Days ahead: ")
	if days == nil or days == '' then
		return 0
	end

	local date = get_command_output(string.format("date --date='%d days' +'%%V: (%%a) %%d-%%b'", days))

	local minutes = vim.fn.input("Minutes: ")
	if minutes == nil or minutes == '' then
		return 0
	elseif math.floor(minutes/100)==0 then
		if math.floor(minutes/10)==0 then
			minutes=minutes..'  '
		else
			minutes=minutes..' '
		end
	end

	local tag = vim.fn.input("Tag: ")
	if tag == nil or tag == '' then
		return 0
	end

	local description = vim.fn.input("Description: ")
	if description == nil or description == '' then
		return 0
	end

	local appointment = string.format("- [ ] `%s` | %s | `%s`: %s", minutes, date, tag, description)
	insert_text_at_pos(appointment,true)
end

return M

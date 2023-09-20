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
		print(".md gaming")
		vim.cmd.edit(url)
	elseif url:find("%.%a+$") then
		print("xdg gaming")
		vim.fn.system('xdg-open ' .. url)
	else
		print("no extension gaming")
		vim.cmd.edit(url .. ".md")
	end
end

M.follow_link = function()
	local node = ts_utils.get_node_at_cursor();
	local node_type = node:type();
	if node_type == 'link_destination' or node_type == 'link_text' or node_type == 'link_description' then
		process_link(get_url_from_node(node:parent()))
	elseif node_type == 'inline_link' then
		process_link(get_url_from_node(node))
	else
		vim.cmd'norm! j'
	end
end

M.next_link = function ()
	-- TODO(refactor): extract to initialization 
	local language_tree = vim.treesitter.get_parser(0, "markdown_inline")
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()

	-- parse the query
	local parse_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link) @id]])

	local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))
	local file_rows = tonumber(vim.fn.system({ 'wc', '-l', vim.fn.expand('%') })) or 0

	local iterator = parse_query:iter_captures(root, 0, 0, file_rows)
	for _, capture, _ in iterator do
		print(vim.inspect(capture))
		local capture_row,capture_column,_ = capture:start()
		if (my_row == capture_row and my_column < capture_column) or my_row < capture_row then
			vim.api.nvim_win_set_cursor(0, {capture_row+1,capture_column})
			break
		end
	end
end

M.previous_page = function ()

end

return M

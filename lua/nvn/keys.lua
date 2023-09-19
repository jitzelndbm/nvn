local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

local function get_url_from_node(node)
	local node_text = vim.treesitter.get_node_text(node, 0)
	local node_dest = vim.split(node_text, '(', {plain=true})
	local url = node_dest[2]:sub(1,-2) -- rm last char
	return url
end

local function process_link(url)
	-- types of links: file, xdg 
	if not url:find('^https://') and not url:find("^mailto:") then
		vim.cmd.edit(url)
	else
		vim.fn.system('xdg-open ' .. url)
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
	local language_tree = vim.treesitter.get_parser(0, "markdown_inline")
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()
	local parse_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link) @id]])
	for _, capture, _ in parse_query:iter_captures(root, 0, 0, 1000) do
		print(vim.treesitter.get_node_text(capture, 0))
	end
end

M.previous_page = function ()

end

return M

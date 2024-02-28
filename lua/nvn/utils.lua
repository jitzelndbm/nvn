local utils = {}

utils.get_url_from_node = function(node)
	local node_text = vim.treesitter.get_node_text(node, 0)
	local node_dest = vim.split(node_text, '(', {plain=true})
	local url = node_dest[2]:sub(1,-2) -- rm last char
	return url
end

utils.process_link = function(url, options)
	if url:find(".md$") or url:find(".rem$") then
		vim.cmd.edit(url)
		return url
	elseif url:find("%.%w+$") then
		os.execute('xdg-open ' .. vim.fn.shellescape(url) .. "&")
		return nil
	else -- no file extension -> will expect markdown

		url = url .. ".md"

		if options.automatic_creation then
			local file_exists = io.open(url, "r")
			if file_exists then
				file_exists:close()
			else
				local file = io.open(url, "w")

				local parent_name = vim.api.nvim_buf_get_name(0)

				---@cast file -nil
				file:write(string.format("[Terug](%s)\n\n# ", parent_name:match("^.+/(.+)%..+$")))

				---@cast file -nil
				file:close()

				vim.cmd.edit(url)
				vim.api.nvim_command("normal! G$")
				vim.api.nvim_command("startinsert!")
				return url
			end
		end

		vim.cmd.edit(url)
		return url
	end
end

utils.get_links = function()

	local language_tree = vim.treesitter.get_parser(0, "markdown_inline")
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()

	-- parse the query
	local parse_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link) @id]])
	local file_rows = vim.api.nvim_buf_line_count(0) or 0
	local iter = parse_query:iter_captures(root, 0, 0, file_rows)

	-- put all the links into a table
	local a = {}
	local i = 1
	for _, capture, _ in iter do
		local capture_row,capture_column,_ = capture:start()
		a[i] = {
			capture_row+1, -- start row
			capture_column, -- start column
			vim.treesitter.get_node_text(capture:child(1), 0), -- link text 
			vim.treesitter.get_node_text(capture:child(4), 0) -- url text
		}
		i = i + 1
	end

	return a
end

utils.insert_text_at_pos = function(text,newline)
	if newline then
		vim.cmd[[norm o]]
	end
	local pos = vim.api.nvim_win_get_cursor(0)[2]
	local line = vim.api.nvim_get_current_line()
	local nline = line:sub(0, pos) .. string.format('%s',text:gsub('[\n\r]', '') or 'none: command not found or somehting') .. line:sub(pos + 1)
	vim.api.nvim_set_current_line(nline)
end

utils.get_command_output = function(command)
	local handle = io.popen(command)

	---@cast handle -nil
	local output = handle:read('*a')

	---@cast handle -nil
	handle:close()
	return output
end

return utils

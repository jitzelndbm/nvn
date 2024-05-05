Link = {}

function Link:new(node, file)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	local node_type = node:type()
	if node_type == 'inline_link' then
		obj.shortcut_link = false
		obj.title = vim.treesitter.get_node_text(node:child(1), 0)
		obj.url = vim.treesitter.get_node_text(node:child(4), 0)
	elseif node_type == 'shortcut_link' then
		obj.shortcut_link = true
		obj.title = nil
		obj.url = vim.treesitter.get_node_text(node:child(1), 0)
	else
		vim.notify("link: error while parsing", vim.log.levels.ERROR)
		return nil
	end

	local row, column = node:start()
	obj.row = row + 1
	obj.column = column
	obj.file = file

	return obj
end

function Link:handle(client)
	if getmetatable(client) ~= Client then
		vim.notify("link: invalid client", vim.log.levels.ERROR)
		return nil
	end

	if not self.url:find(".md$") then
		os.execute('xdg-open ' .. vim.fn.shellescape(self.url) .. "&")
		return
	end

	-- FIXME: when neovim is updated to v0.10 update this section 
	-- to use vim.fs.joinpath instead of vim.cmd.simplify
	client:set_location(vim.fn.simplify(vim.fs.dirname(self.file).."/"..self.url))
end

return Link

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
		vim.notify('link: error while parsing', vim.log.levels.ERROR)
		return nil
	end

	local row, column = node:start()
	obj.row = row + 1
	obj.column = column
	obj.file = file

	return obj
end

function Link:handle(client)
	-- TODO: Add support for footnotes

	if getmetatable(client) ~= Client then
		vim.notify('link: invalid client', vim.log.levels.ERROR)
		return nil
	end

	if self.url:find '^assets://' then
		vim.ui.open(vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(client.config.root), 'assets', self.url:sub(10))))
		return
	end

	if not self.url:find '.md$' then
		vim.ui.open(self.url)
		-- NOTE: This is the old version which is compatible with older versions. (< v0.10)
		--os.execute('xdg-open ' .. vim.fn.shellescape(self.url) .. '&')
		return
	end

	-- NOTE: This is the old version, compatible with older versions
	--local path = vim.fn.simplify(vim.fs.dirname(self.file) .. '/' .. self.url)
	local path = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(self.file), self.url))

	if #(vim.fs.find(function(name, found_path) return found_path .. '/' .. name == path end, { limit = 1 })) == 0 then
		client:create_note(path, self.file, self.title)
	else
		client:set_location(path)
	end
end

return Link

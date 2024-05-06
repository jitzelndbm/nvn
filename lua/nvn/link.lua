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
		-- FIXME: Replace with vim.ui.open when v0.10 is out
		--vim.ui.open(vim.fn.shellescape(self.url))
		os.execute('xdg-open ' .. vim.fn.shellescape(self.url) .. "&")
		return
	end

	-- FIXME: when neovim is updated to v0.10 update this section 
	-- to use vim.fs.joinpath instead of vim.cmd.simplify
	local path = vim.fn.simplify(vim.fs.dirname(self.file).."/"..self.url)

	if #(vim.fs.find(function (name, found_path)
		return found_path.."/"..name == path
	end, { limit = 1 })) == 0 then
		client:create_note(path, self.file, self.title)
	else
		client:set_location(path)
	end
end

return Link

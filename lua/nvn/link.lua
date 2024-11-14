local default_handlers = require("nvn.default_handlers")

---This class represents a link in a markdown Note
---@class Link
---@field title string
---@field url string
---@field shortcut boolean true means it's a [url], false means [title](url)
---@field row integer
---@field col integer
local Link = {}
Link.__index = Link

---Create a link
---@param node TSNode
---@return Link
function Link.new(node)
	local self = setmetatable({}, Link)

	local type = node:type()

	if not type == 'shortcut_link' or not type == 'inline_link' then
		error("Could not construct a link form node type: " .. type)
	end

	self.shortcut = node:type() == 'shortcut_link'
	if self.shortcut then
		local url_node = node:child(1) or error("The link url could not be found")
		self.url = vim.treesitter.get_node_text(url_node, 0)
	else
		local title_node = node:child(1) or error("The link title could not be found")
		self.title = vim.treesitter.get_node_text(title_node, 0)

		local url_node = node:child(4) or error("The link url could not be found")
		self.url = vim.treesitter.get_node_text(url_node, 0)
	end

	local row, col = node:start()
	self.row = row + 1
	self.col = col

	return self
end

---@param client Client
function Link:follow(client)
	local merged = {}

	for pattern, func in pairs(client.config.handlers) do
		merged[pattern] = func
	end

	for pattern, func in pairs(default_handlers.mapping) do
		if merged[pattern] == nil then
			merged[pattern] = func
		end
	end

	---@type boolean
	local found_handler = false
	for pattern, handler in pairs(merged) do
		if type(pattern) == "string" and self.url:find(pattern) then
			vim.notify(("Using handler %s"):format(pattern))
			handler(client, self)
			found_handler = true
			break
		end
	end

	vim.notify("found_handler: " .. tostring(found_handler))
	if not found_handler then merged[0](client, self) end
end

return Link

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

	if not type == "shortcut_link" or not type == "inline_link" then
		error("Could not construct a link form node type: " .. type)
	end

	self.shortcut = node:type() == "shortcut_link"
	if self.shortcut then
		local url_node = node:child(1)
			or error("The link url could not be found")
		self.url = vim.treesitter.get_node_text(url_node, 0)
	else
		local title_node = node:child(1)
			or error("The link title could not be found")
		self.title = vim.treesitter.get_node_text(title_node, 0)

		local url_node = node:child(4)
			or error("The link url could not be found")
		self.url = vim.treesitter.get_node_text(url_node, 0)
	end

	local row, col = node:start()
	self.row = row + 1
	self.col = col

	return self
end

---@param client Client
function Link:follow(client)
	---@type { pattern: string, handler: function }[]
	local merged = {}

	---@type boolean[]
	local patterns = {}

	-- Add all patterns from the user config
	for _, entry in ipairs(client.config.handlers) do
		table.insert(merged, entry)
		patterns[entry.pattern] = true
	end

	-- Optionally add default handlers
	for _, entry in ipairs(default_handlers.mapping) do
		if not patterns[entry.pattern] then
			table.insert(merged, entry)
			patterns[entry.pattern] = true
		end
	end

	---@type { pattern: string, handler: function }
	local fallback

	for _, entry in pairs(merged) do
		if type(entry.pattern) == "string" and self.url:find(entry.pattern) then
			entry.handler(client, self)
			return
		else
			fallback = entry
		end
	end

	fallback.handler(client, self)
end

return Link

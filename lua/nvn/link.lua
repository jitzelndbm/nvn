---@module 'nvn.default_handlers'
local default_handlers = require("nvn.default_handlers")

---@class Result
local Result = require("nvn.result")
---@class Option
local Option = require("nvn.option")

---This class represents a link in a markdown Note
---@class Link
---@field title string
---@field url string
---@field shortcut boolean true means it's a [url], false means [title](url)
---@field row integer
---@field col integer
local Link = {}
Link.__index = Link

---Returns a link object, constructed from a treesitter node
---
---@param node TSNode
---@return Result Link
function Link.new(node)
	local self = setmetatable({}, Link)

	local type = node:type()

	if not type == "shortcut_link" or not type == "inline_link" then
		return Result.Err("Could not construct a link form node type: " .. type)
	end
	self.shortcut = node:type() == "shortcut_link"

	local url_res = Option.Some(node:child(self.shortcut and 1 or 4))
		:inspect(
			function(url_node)
				self.url = vim.treesitter.get_node_text(url_node, 0)
			end
		)
		:ok_or("Link url could be found")
	if url_res:is_err() then return url_res end

	if self.shortcut then
		local title_res = Option.Some(node:child(1))
			:inspect(
				function(title_node)
					self.title = vim.treesitter.get_node_text(title_node, 0)
				end
			)
			:ok_or("Link title could not be found")
		if title_res:is_err() then return url_res end
	end

	local row, col = node:start()
	self.row = row + 1
	self.col = col

	return Result.Ok(self)
end

---Follow a link object, using a dictionary of handler functions
---
---@param client Client
---@return Result
function Link:follow(client)
	---@type HandlerEntry[]
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

	---@type HandlerEntry
	local fallback

	-- Check every entry to see if it matched, and assign the fallback
	for _, entry in pairs(merged) do
		if type(entry.pattern) == "string" and self.url:find(entry.pattern) then
			return Result.pcall(entry.handler, client, self)
		else
			fallback = entry
		end
	end

	return Result.pcall(fallback.handler, client, self)
end

return Link

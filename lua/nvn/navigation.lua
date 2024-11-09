local link = require("nvn.link")

---@class Navigation
---@field note Note
local Navigation = {}

---@param note Note
---@return Navigation
function Navigation.new(note)
	local self = setmetatable({}, Navigation)
	self.note = note
	return self
end

---@return Link
function Navigation:next_link()
	--self.note:buf_call(function ()
	--	local language_tree = vim.treesitter.get_parser(0, 'markdown_inline')
	--end)
	return link.new()
end

---@return Link?
function Navigation:current_link()
	return link.new()
end

---@return Link
function Navigation:previous_link()
	return link.new()
end

return Navigation

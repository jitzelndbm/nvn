---@module 'default_handlers'

local default_handlers = {}

---@param client Client
---@param link Link
default_handlers.markdown = function(client, link)
	---@class Path
	local Path = require("nvn.path")

	---@class Note
	local Note = require("nvn.note")

	local n = Note.new(Path.new_from_note(client.current, link.url))
	client.history:push(client.current)
	client:set_location(n)
end

---@param client Client
---@param link Link
default_handlers.folder = function(client, link)
	local joined = vim.fs.joinpath(link.url, client.config.index)
	if vim.fn.filereadable(joined) == 1 then
		---@class Path
		local Path = require("nvn.path")
		---@class Note
		local Note = require("nvn.note")

		local n = Note.new(Path.new_from_note(client.current, joined))
		client.history:push(client.current)
		client:set_location(n)
	end
end

---@param link Link
default_handlers.default = function(_, link) vim.ui.open(link.url) end

default_handlers.mapping = {
	{ pattern = ".md$", handler = default_handlers.markdown },
	{ pattern = "/$", handler = default_handlers.folder },

	-- NOTE: This has to be last, since it matched everything. It acts as a fallback handler.
	{ pattern = ".*", handler = default_handlers.default }
}

return default_handlers

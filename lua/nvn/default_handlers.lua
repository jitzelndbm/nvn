---Some handlers that are enabled by default, to make the plugin usable, 
---use this source code as examples to create your own link handlers.
---@module 'default_handlers'

local default_handlers = {}

---@param client Client
---@param link Link
default_handlers.markdown = function(client, link)
	---@class Path
	local Path = require("nvn.path")
	---@class Note
	local Note = require("nvn.note")
	---@class Template
	local Template = require("nvn.template")

	local p = Path.new_from_note(client.current, link.url)
	local n = Note.new(p)

	if not p:exists() then
		-- Make the user choose a template for the new file
		local t = Template.from_picker(client.config.root, client.config.template_folder)
		if not t then return end

		-- NOTE: If there is an error in the template, this function will 
		-- fail which is a good thing. Then the note is not created, and 
		-- the function can be ran again.
		local s = t:render({link = link})

		client:add(n)
		n:write(true, s)
	end

	client.history:push(client.current)
	client:set_location(n)
end

---@param client Client
---@param link Link
default_handlers.folder = function(client, link)
	---@class Path
	local Path = require("nvn.path")
	---@class Note
	local Note = require("nvn.note")
	---@class Template
	local Template = require("nvn.template")

	local joined = vim.fs.joinpath(link.url, client.config.index)
	local p = Path.new_from_note(client.current, joined)
	local n = Note.new(p)

	if not p:exists() then
		-- Make the user choose a template for the new file
		local t = Template.from_picker(client.config.root, client.config.template_folder)
		if not t then return end

		-- NOTE: If there is an error in the template, this function will 
		-- fail which is a good thing. Then the note is not created, and 
		-- the function can be ran again.
		local s = t:render({link = link})

		client:add(n)
		n:write(true, s)
	end

	client.history:push(client.current)
	client:set_location(n)
end

---@param link Link
default_handlers.default = function(_, link) vim.ui.open(link.url) end

default_handlers.mapping = {
	{ pattern = ".md$", handler = default_handlers.markdown },
	{ pattern = "/$",   handler = default_handlers.folder },
	{ pattern = "^.$", handler = default_handlers.folder },
	{ pattern = "^..$", handler = default_handlers.folder },

	-- NOTE: This has to be last. Since it matches everything, it acts as a fallback handler.
	{ pattern = ".*",   handler = default_handlers.default }
}

return default_handlers

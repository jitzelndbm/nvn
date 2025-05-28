---Some handlers that are enabled by default, to make the plugin usable,
---use this source code as examples to create your own link handlers.
---@module 'default_handlers'
local default_handlers = {}

-- Type aliases for handlers
---@alias Handler fun(client: Client, link: Link)
---@alias HandlerEntry {pattern: string, handler: Handler}

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
		---@type Template
		local t = Template.from_picker(
			client.config.root,
			client.config.template_folder
		)
			:unwrap()
		if not t then return end

		-- Unwrapping results immediately so the template does not get written if it produces an error
		---@type string
		local s = t:render({ link = link }):unwrap()
		client:add(n):unwrap()
		n:write(true, s)
	end

	client.history:push(client.current)
	client:set_location(n)
	if client.config.auto_evaluation then n:evaluate():unwrap() end
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

	local p = Path.new_from_note(
		client.current,
		vim.fs.joinpath(link.url, client.config.index)
	)
	local n = Note.new(p)

	if not p:exists() then
		-- Make the user choose a template for the new file
		---@type Template
		local t = Template.from_picker(
			client.config.root,
			client.config.template_folder
		)
			:unwrap()
		if not t then return end

		-- Unwrapping results immediately so the template does not get written if it produces an error
		---@type string
		local s = t:render({ link = link }):unwrap()

		client:add(n)
		n:write(true, s)
	end

	client.history:push(client.current)
	client:set_location(n)
	if client.config.auto_evaluation then n:evaluate() end
end

---@param client Client
---@param link Link
default_handlers.default = function(client, link)
	local oldcwd = vim.fn.getcwd()
	vim.cmd.cd(vim.fs.dirname(client.current.path.full_path))
	vim.ui.open(link.url)
	vim.cmd.cd(oldcwd)
end

---@type HandlerEntry[]
default_handlers.mapping = {
	{ pattern = ".md$", handler = default_handlers.markdown },
	{ pattern = "/$", handler = default_handlers.folder },
	{ pattern = "^.$", handler = default_handlers.folder },
	{ pattern = "^..$", handler = default_handlers.folder },

	-- NOTE: This has to be last. Since it matches everything, it acts as a fallback handler.
	{ pattern = ".*", handler = default_handlers.default },
}

return default_handlers

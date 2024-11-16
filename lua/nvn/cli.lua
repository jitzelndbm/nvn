---@class Navigation
local Navigation = require("nvn.navigation")

local err = require("nvn.error")

--- # Cli class
--- @class (exact) Cli
---
--- ## Fields
--- @field client Client
--- @field __index Cli
---
--- ## Methods
--- @field new function
--- @field register function
---
--- ### Conventions
--- These methods correspond to literal commands from the plugin
local Cli = {}
Cli.__index = Cli

function Cli.new(client)
	local self = setmetatable({}, Cli)
	self.client = client
	return self
end

--- Move the cursor to the next link in the current buffer, if there is no link nothing happens
function Cli:next_link()
	local status, link_or_err = xpcall(
		Navigation.next_link,
		err.handler,
		self.client.current.navigation
	)

	if status then
		vim.api.nvim_win_set_cursor(0, { link_or_err.row, link_or_err.col })
	else
		error("Next Link command failed" .. link_or_err)
	end
end

--- Move the cursor to the previous link in the buffer, if there is no link nothing happens
function Cli:previous_link()
	local status, link_or_err = xpcall(
		Navigation.previous_link,
		err.handler,
		self.client.current.navigation
	)

	if status then
		vim.api.nvim_win_set_cursor(0, { link_or_err.row, link_or_err.col })
	else
		error("Previous link command failed" .. link_or_err)
	end
end

--- Follows the link under the cursor if it is a link, otherwise this function puts <CR> into vim
function Cli:follow_link()
	local status, link = xpcall(
		self.client.current.navigation.current_link,
		err.handler,
		self.client.current.navigation,
		self
	)

	if status then
		local msg
		status, msg = xpcall(link.follow, err.handler, link, self.client)
		if not status then error("Following link failed" .. msg) end
	else
		--error("Link could not be found under cursor" .. link)
		-- Handle the case that a link could not be found
		vim.cmd('execute "normal! \\<CR>"')
	end
end

---Go to the previously visited note
--function Cli:goto_previous()
--end

--function Cli:delete_note()
--end

--function Cli:evaluate()
--end

--function Cli:open_graph()
--end

function Cli:register_commands()
	local function xpn(k, m, a)
		vim.api.nvim_create_user_command(k, function()
			local status, error = xpcall(m, err.handler, a)
			if not status then err.print(error) end
		end, {})
	end

	-- Register all commands
	xpn("NvnPreviousLink", self.previous_link, self)
	xpn("NvnNextLink", self.next_link, self)
	xpn("NvnFollowLink", self.follow_link, self)
end

return Cli

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
	local status, link = pcall(self.client.current.navigation.current_link, self)
	if status and link ~= nil then
		link:follow(self.client)
	else
		vim.cmd('execute "normal! \\<CR>"')
	end
end

--function Cli:goto_previous()
--end

--function Cli:delete_note()
--end

--function Cli:evaluate()
--end

--function Cli:open_graph()
--end

function Cli:register_commands()
	local function xpn(k,m)
		vim.api.nvim_create_user_command(k,function ()
			local status, error = xpcall(m, err.handler, self)
			if not status then err.print(error) end
		end, {})
	end

	local n = vim.api.nvim_create_user_command

	-- Register all commands
	n("NvnPreviousLink", function()
		local status, error = xpcall(self.previous_link, err.handler, self)
		if not status then err.print(error) end
	end, {})

	n("NvnNextLink", function()
		local status, error = xpcall(self.next_link, err.handler, self)
		if not status then err.print(error) end
	end, {})

	n("NvnFollowLink", function()
		local status, error = xpcall(self.follow_link, err.handler, self)
		if not status then err.print(error) end
	end, {})
end

return Cli

-- nvn: NeoVim Notes
--	- Create notes with Neovim
--	- Use markdown syntax to link to other files

local keys = require("nvn.keys")
local M = {}
Pages = {}

local function add_keybinds()
	vim.keymap.set('n', '<CR>', function() Pages=keys.follow_link(Pages) end)
	vim.keymap.set('n', '<Backspace>', function() Pages=keys.previous_page(Pages) end)
	vim.keymap.set('n', '<Tab>', function() keys.next_link() end)
	vim.keymap.set('n', '<S-Tab>', function() keys.previous_link() end)
end

local function add_commands()
	vim.api.nvim_create_user_command('NvnFollowLink', function() Pages=keys.follow_link(Pages) end, {})
	vim.api.nvim_create_user_command('NvnPreviousPage', function() Pages=keys.previous_page(Pages) end, {})
	vim.api.nvim_create_user_command('NvnNextLink', function() keys.next_link() end, {})
	vim.api.nvim_create_user_command('NvnPreviousLink', function() keys.previous_link() end, {})
end

M.setup = function (options)
	local options = {
		dirs = { '~/dx/notes-test', 'gaming' }
	}

	-- settings
	vim.wo.conceallevel = 2

	add_keybinds()
	add_commands()
end

return M

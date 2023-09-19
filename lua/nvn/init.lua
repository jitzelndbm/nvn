-- nvn: NeoVim Notes
--	- Create notes with Neovim
--	- Use markdown syntax to link to other files

local keys = require("nvn.keys")
local M = {}

local function add_keybinds()
	vim.keymap.set('n', '<CR>', function() keys.follow_link() end)
	vim.keymap.set('n', '<Backspace>', function() keys.previous_page() end)
	vim.keymap.set('n', '<Tab>', function() keys.next_link() end)
	vim.keymap.set('n', '<S-Tab>', function() keys.previous_link() end)
end

local function add_commands()
	vim.api.nvim_create_user_command('NvnFollowLink', function() keys.follow_link() end, {})
	vim.api.nvim_create_user_command('NvnPreviousPage', function() keys.previous_page() end, {})
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

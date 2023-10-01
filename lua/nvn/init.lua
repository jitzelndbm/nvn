-- nvn: NeoVim Notes
--	- Create notes with Neovim
--	- Use markdown syntax to link to other files

local keys = require("nvn.keys")
local autocmd = require("nvn.autocmd")

local nvn = {}
Pages = {}

local function add_keybinds()
	vim.keymap.set('n', '<CR>', function() Pages=keys.follow_link(Pages) end)
	vim.keymap.set('n', '<Backspace>', function() Pages=keys.previous_page(Pages) end)
	vim.keymap.set('n', '<Tab>', function() keys.next_link() end)
	vim.keymap.set('n', '<S-Tab>', function() keys.previous_link() end)
	vim.keymap.set('n', '<leader>ff', function() print(require"telescope.builtin".find_files()) end)
	vim.keymap.set('n', '<leader>id', function () keys.insert_date() end)

	-- formatting
	vim.keymap.set('n', '=', function ()
		local line_content = vim.api.nvim_get_current_line()
		if line_content:find("^######") then
			return nil
		end

		local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))

		if line_content:find("^#") then
			vim.cmd.norm("0i#")
		else
			vim.cmd.norm("0i# ")
		end

		vim.api.nvim_win_set_cursor(0,{my_row,my_column})
	end)

	vim.keymap.set('n', '-', function ()
		local my_row,my_column = unpack(vim.api.nvim_win_get_cursor(0))
		local line_content = vim.api.nvim_get_current_line()
		if line_content:find("^# ") then
			vim.cmd.norm("0xx")
		elseif line_content:find("^#") then
			vim.cmd.norm("0x")
		end
		vim.api.nvim_win_set_cursor(0,{my_row,my_column})
	end)
end

local function add_commands()
	vim.api.nvim_create_user_command('NvnFollowLink', function() Pages=keys.follow_link(Pages) end, {})
	vim.api.nvim_create_user_command('NvnPreviousPage', function() Pages=keys.previous_page(Pages) end, {})
	vim.api.nvim_create_user_command('NvnNextLink', function() keys.next_link() end, {})
	vim.api.nvim_create_user_command('NvnPreviousLink', function() keys.previous_link() end, {})
	vim.api.nvim_create_user_command('NvnInsertDate', function () keys.insert_date() end, {})

	vim.api.nvim_create_user_command('NvnClose', function() autocmd.close() end, {})
	vim.cmd[[cnoreabbrev <expr> q "NvnClose"]]
	vim.cmd[[cnoreabbrev <expr> wq "NvnClose"]]
	vim.cmd[[cnoreabbrev <expr> qa "NvnClose"]]
end

nvn.setup = function()
	-- vim window settings
	vim.wo.conceallevel = 2
	vim.wo.linebreak = true
	vim.wo.number = false
	vim.wo.relativenumber = false

	vim.bo.filetype = 'markdown'
	vim.bo.ft='markdown'
	vim.wo.foldmethod = 'syntax'

	add_keybinds()
	add_commands()
end

return nvn

-- nvn: NeoVim Notes
--	- Create notes with Neovim
--	- Use markdown syntax to link to other files

local actions = require("nvn.actions.init")
local behaviour = require("nvn.behaviour")

local nvn = {}

Pages = {}

local function nkey(key, func)
	vim.keymap.set('n', key, func)
end

local function register_keys(options)
	nkey(options.keymap.follow_link, function() Pages=actions.navigation.follow_link(Pages, options) end)
	nkey(options.keymap.previous_page, function() Pages=actions.navigation.previous_page(Pages) end)
	nkey(options.keymap.next_link, function() actions.navigation.next_link() end)
	nkey(options.keymap.previous_link, function() actions.navigation.previous_link() end)
	nkey(options.keymap.insert_date, function () actions.file.insert_date(options) end)
	nkey(options.keymap.insert_future_date, function () actions.file.insert_future_date(options) end)
	nkey(options.keymap.go_home, function () Pages=actions.navigation.go_home(Pages, options) end)
	nkey(options.keymap.remove_current_note, function () actions.structure.remove_current_note(Pages) end)

	if options.appearance.folding then
		nkey(options.keymap.reload_folding, function () actions.other.reload_folding() end)
	end

	vim.keymap.set('n', '<leader>=', function ()
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

	vim.keymap.set('n', '<leader>-', function ()
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

local function register_commands(options)
	vim.api.nvim_create_user_command('NvnFollowLink', function() Pages=actions.navigation.follow_link(Pages, options) end, {})
	vim.api.nvim_create_user_command('NvnPreviousPage', function() Pages=actions.navigation.previous_page(Pages) end, {})
	vim.api.nvim_create_user_command('NvnNextLink', function() actions.navigation.next_link() end, {})
	vim.api.nvim_create_user_command('NvnPreviousLink', function() actions.navigation.previous_link() end, {})
	vim.api.nvim_create_user_command('NvnInsertDate', function () actions.file.insert_date(options) end, {})
	vim.api.nvim_create_user_command('NvnInsertFutureDate', function () actions.file.insert_future_date(options) end, {})
	vim.api.nvim_create_user_command('NvnGoHome', function () Pages=actions.navigation.go_home(Pages, options) end, {})
	vim.api.nvim_create_user_command('NvnClose', function() behaviour.close() end, {})
	vim.api.nvim_create_user_command('NvnRemoveCurrentNote', function () actions.close.remove_current_note(Pages) end, {})

	if options.appearance.folding then
		vim.api.nvim_create_user_command('NvnReloadFolding', function () actions.other.reload_folding() end, {})
	end

	-- register aliases
	if options.strict_closing then
		vim.cmd[[cnoreabbrev <expr> q "NvnClose"]]
		vim.cmd[[cnoreabbrev <expr> wq "NvnClose"]]
		vim.cmd[[cnoreabbrev <expr> qa "NvnClose"]]
	end
end

local function change_appearance(options)
	-- check if the input file matches the root file
	-- if not return, since it is not in the wiki
	if vim.api.nvim_buf_get_name(0) ~= options.root then
		return
	end

	if options.appearance.hide_numbers then
		vim.wo.linebreak = true
		vim.wo.number = false
		vim.wo.relativenumber = false
	end

	if options.appearance.folding then
		vim.wo.foldmethod = 'syntax'
		vim.wo.conceallevel = 2
		vim.cmd[[let g:markdown_folding = 1]]
	end

	vim.bo.filetype = 'markdown'
	vim.bo.ft='markdown'
end

local default_options = {
	root = string.format("%s/.notes/index.md", os.getenv("HOME")),
	strict_closing = false,
	automatic_creation = false,
	keymap = {
		follow_link = "<CR>",
		previous_page = "<Backspace>",
		next_link = "<Tab>",
		previous_link = "<S-Tab>",
		insert_date = "<leader>id",
		insert_future_date = "<leader>if",
		reload_folding = "<leader>rf",
		go_home = "<leader>gh",
		remove_current_note = "<leader>rcn"
	},
	appearance = {
		hide_numbers = false,
		folding = true
	},
	date = {
		format = "%d %b %Y",
		lowercase = true
	}
}

nvn.setup = function(user_options)

	-- merge the user options with the defaults
	-- so that nvn can be configured from lazy
	local options
	if user_options then
		options = vim.tbl_deep_extend("force", default_options, user_options)
	else
		options = default_options
	end


	change_appearance(options)
	register_keys(options)
	register_commands(options)
end

return nvn

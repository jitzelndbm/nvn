--- Neovim Notes (NvN), a note taking application for Neovim
-- @author Jitze Lindeboom
-- @license GPL v3
-- @module nvn
local nvn = {}

-- global variables
Pages = {}

-- imports
local register = require'nvn.register'

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
		remove_current_note = "<leader>dcn",
		rename_current_note = "<leader>rcn",
		increase_header_level = "<leader>=",
		decrease_header_level = "<leader>-"
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

	-- cancel setup if the root isn't opened
	if vim.api.nvim_buf_get_name(0) ~= options.root then
		return
	end

	-- run the main plugin logic
	register.appearance(options)
	register.keys(options)
	register.commands(options)
end

return nvn

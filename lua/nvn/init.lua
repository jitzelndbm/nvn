local nvn = {}

require 'nvn.link'
require 'nvn.client'
require 'nvn.template'

local default_opts = {
	root = "dx/notes/index.md",

	behaviour = {
		-- :wqa should be used to safely close notes, enforce it.
		strict_closing = false,

		-- Automatic saving when navigating through links
		-- WARNING: This setting can lead to data loss, if not enabled
		auto_save = true,

		-- When a link is pressed and the file does not exist, create it
		automatic_creation = false,
	},

	appearance = {
		-- Hide numbers from the editor
		hide_numbers = false,

		-- Enable markdown header folding
		folding = true,
	},

	templates = {
		-- Wheter to enable templates or not  
		enabled = true,

		-- Directory where templates are stored
		dir = "templates"
	},

	dates = {
		-- Whether to enable date formatting
		enabled = true,
	}
}

local function register(client)

	vim.api.nvim_create_user_command(
		'NvnNextLink',
		function ()
			local nl = client:get_next_link(false)
			vim.api.nvim_win_set_cursor(0, {nl.row, nl.column})
		end,
		{ desc = "Place the cursor at the beginning of the next link in the file" }
	)

	vim.api.nvim_create_user_command(
		'NvnPreviousLink',
		function ()
			local pl = client:get_next_link(true)
			vim.api.nvim_win_set_cursor(0, {pl.row, pl.column})
		end,
		{ desc = "Place the cursor at the beginning of the previous link in the file" }
	)

	vim.api.nvim_create_user_command(
		'NvnFollowLink',
		function ()
			local link

			local node = require'nvim-treesitter.ts_utils'.get_node_at_cursor()
			local file_name = vim.api.nvim_buf_get_name(0)
			local node_type = node:type()

			if node_type == 'shortcut_link' or node_type == 'inline_link' then
				link = Link:new(node, file_name)
			elseif node_type == 'link_text' or node_type == 'link_description' then
				link = Link:new(node:parent(), file_name)
			end

			if not link then
				vim.cmd"execute \"normal! \\<CR>\""
				return
			end

			link:handle(client)
		end,
		{ desc = "Follow the link that is under the cursor" }
	)

	vim.api.nvim_create_user_command(
		'NvnGotoPrevious',
		function ()
			client.history:pop()
			client:set_location(client.history:last(), true)
		end,
		{ desc = "Go to the previous page in the history" }
	)
end

nvn.setup = function (opts)
	local parsed_opts = vim.tbl_deep_extend("force", default_opts, opts or {})
	local c = Client:new(parsed_opts)
	register(c)
end

return nvn

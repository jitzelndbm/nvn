-- nvn: NeoVim Notes
--	- Create notes with Neovim
--	- Use markdown syntax to link to other files

local keys = require("nvn.keys")
local M = {}

local function add_keybinds()
	-- Follow link
	vim.keymap.set('n', '<CR>', function() keys.follow_link() end)


end

local function index_file(path)
	-- if file is markdown && in notes dir, index the links
end

M.setup = function (options)
	local options = {
		dirs = { '~/dx/notes-test', 'gaming' }
	}


	-- Detect if dir is in files 
	--
	

	--add_keybinds()
	-- If not, close setup
	return "gaming"
end

-- lazy, only enable on markdown files. See if


return M

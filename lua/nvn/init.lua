---@class Client
local Client = require("nvn.client")

---@class Cli
local Cli = require("nvn.cli")

---The main module of the neovim notes plugin
---@module 'init'

local root = "/home/jitze/pr/nvn/test_notes/"
local default_config = {
	root = root,
	index = "README.md",
	save_when_navigating = false,
	handlers = {
		---Asset opener, links that start with assets://
		---@param link Link
		["^assets://"] = function (_, link)
			local p = vim.fs.normalize(vim.fs.joinpath(root, 'assets', link.url:sub(10)))

			if vim.fn.filereadable(p) == 0 then
				vim.notify("File does not exist")
				return
			end

			vim.ui.open(p)
		end,
	}
}

local nvn = {}

function nvn.setup()
	local c = Cli.new(Client.new(default_config))

	-- Change the working directory
	vim.fn.chdir(default_config.root)

	-- Register all user commands
	c:register_commands()
end

return nvn

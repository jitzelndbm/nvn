---@class Client
local Client = require("nvn.client")
local cli = require("nvn.cli")

---The main module of the neovim notes plugin
---@module 'init'

local root = "/home/jitze/pr/nvn/test_notes/"
local default_config = {
	root = root,
	index = "README.md",
	save_when_navigating = true,
	handlers = {
		---Asset opener, links that start with assets://
		---@param link Link
		["^assets://"] = function (_, link)
			vim.ui.open(vim.fs.normalize(vim.fs.joinpath(root, 'assets', link.url:sub(11))))
		end,
	}
}

local nvn = {}

function nvn.setup()
	local c = cli.new(Client.new(default_config))

	vim.fn.chdir(default_config.root)

	-- Register all user commands
	c:register_commands()
end

return nvn

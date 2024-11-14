---@class Client
local Client = require("nvn.client")
local cli = require("nvn.cli")

---The main module of the neovim notes plugin
---@module 'init'

local root = "/home/jitze/pr/nvn/test_notes/"
local default_config = {
	root = root,
	index = "README.md",
--	link_matchers = {
--		includes = {
--			---Asset opener, links that start with assets://
--			---@param link Link
--			["^assets://"] = function (_, link)
--				vim.ui.open(vim.fs.normalize(vim.fs.joinpath(root, 'assets', link.url:sub(10))))
--			end,
--
--			---@param client Client
--			---@param link Link
--			[".md$"] = function (client, link)
--				client:set_location()
--			end,
--		},
--		excludes = {
--
--		},
--
--
--		---Default case
--		---@param link Link
--		function (_, link)
--			vim.ui.open(link.url)
--		end
--	},
}

local nvn = {}

function nvn.setup()
	local c = cli.new(Client.new(default_config))

	vim.fn.chdir(default_config.root)

	-- Register all user commands
	c:register_commands()

	c.client.current:write("test", "aap", "[https://en.wikipedia.org]", "[another one](https://google.com)", "test", "[another one](https://google.com)", "test")
	vim.cmd.edit(c.client.current.path.full_path)
end

return nvn

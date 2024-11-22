---@class Client
local Client = require("nvn.client")

---@class Cli
local Cli = require("nvn.cli")

local default_config = {
	root = "~/Documents/Notes",
	index = "README.md",

	template_folder = "templates",

	-- Evaluate a buffer on entry via a link (if you use the default handlers)
	auto_evaluation = false,

	-- Auto save when navigating through links
	auto_save = true,

	-- Link handlers
	handlers = {},

	-- TODO: Remove this
	--handlers = {
	--	{
	--		pattern = "^assets://",

	--		---Asset opener, links that start with assets://
	--		---@param link Link
	--		handler = function(_, link)
	--			local p = vim.fs.normalize(
	--				vim.fs.joinpath(root, "assets", link.url:sub(10))
	--			)

	--			if vim.fn.filereadable(p) == 0 then
	--				vim.notify("File does not exist")
	--				return
	--			end

	--			vim.ui.open(p)
	--		end,
	--	},
	--},
}

local nvn = {}

function nvn.setup(config)

	local merged_config =
		vim.tbl_deep_extend("force", default_config, (config or {}))
	local c = Cli.new(Client.new(merged_config))

	-- Change the working directory
	vim.fn.chdir(merged_config.root)

	-- Register all user commands
	c:register_commands()

end

return nvn

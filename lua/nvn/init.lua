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
}

local nvn = {}

function nvn.setup(config)
	local merged_config =
		vim.tbl_deep_extend("force", default_config, (config or {}))
	local c = Cli.new(Client.new(merged_config):unwrap())

	-- Change the working directory
	vim.fn.chdir(merged_config.root)

	-- Register all user commands
	c:register_commands()
end

return nvn

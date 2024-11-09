local client = require("nvn.client")

---The main module of the neovim notes plugin
---@module 'init'

local default_config = {
	root = "/home/jitze/pr/nvn/test_notes/",
	index = "README.md"
}

local nvn = {}

function nvn.setup()
	local c = client.new(default_config)
	c.current:write("test", "aap")
	vim.cmd.edit(c.current.path.full_path)
end

return nvn

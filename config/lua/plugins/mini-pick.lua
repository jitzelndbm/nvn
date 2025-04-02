return {
	"echasnovski/mini.nvim",
	config = function()
		require("mini.pick").setup({})
		require("mini.notify").setup({})
		vim.notify = MiniNotify.make_notify()
	end
}

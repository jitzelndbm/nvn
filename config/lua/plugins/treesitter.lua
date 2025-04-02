return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = {
		highlight = { enable = true },
		ensure_installed = {
			"html",
			"lua",
			"luadoc",
			"luap",
			"markdown",
			"markdown_inline",
		},
	},
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)
	end,
}

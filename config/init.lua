local root = vim.fs.root(0, ".git")

vim.opt.runtimepath:append(root .. "/config")

-- Setup nvn dependencies
require("manager")

-- Setup the actual plugin
vim.opt.runtimepath:append(root)
require("nvn").setup({
	root = root .. "/test_notes",
	index = "README.md",
	auto_evaluation = false,
	auto_save = true,
	template_folder = root .. "/test_notes/templates",
	handlers = {},
})

vim.keymap.set("n", "<CR>", "<cmd>NvnFollowLink<cr>")
vim.keymap.set("n", "<Tab>", "<cmd>NvnNextLink<cr>")
vim.keymap.set("n", "<S-Tab>", "<cmd>NvnPreviousLink<cr>")
vim.keymap.set("n", "<Backspace>", "<cmd>NvnGotoPrevious<cr>")
vim.keymap.set("n", "<leader>D", "<cmd>NvnDeleteNote<cr>")
vim.keymap.set("n", "<leader>C", "<cmd>NvnCreateNote<cr>")
vim.keymap.set("n", "<leader>E", "<cmd>NvnEval<cr>")
vim.keymap.set("n", "<leader>O", "<cmd>NvnOpenGraph<cr>")

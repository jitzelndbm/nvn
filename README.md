# nvn

Neovim plugin for organising notes in Markdown

## Install
### Lazy
```lua
{
	url = "https://linsoft.nl/jitze/nvn.git",
	ft = 'markdown',
	config = function ()
		require("nvn").setup{}
	end
}
```

## Default options
```lua
{
	root = string.format("%s/.notes/index.md", os.getenv("HOME")),
	strict_closing = false,
	automatic_creation = false,
	keymap = {
		follow_link = "<CR>",
		previous_page = "<Backspace>",
		next_link = "<Tab>",
		previous_link = "<S-Tab>",
		insert_date = "<leader>id",
		insert_future_date = "<leader>if",
		reload_folding = "<leader>rf",
		go_home = "<leader>gh",
		remove_current_note = "<leader>rcn"
	},
	appearance = {
		hide_numbers = false,
		folding = true
	},
	date = {
		format = "%d %b %Y",
		lowercase = true
	}
}
```

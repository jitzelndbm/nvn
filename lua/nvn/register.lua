--- This module is part of the initialization
-- @module register
local register = {}

-- imports
local actions = require("nvn.actions.init")
local behaviour = require("nvn.behaviour")

-- Shortcuts
local function nkey(key, func) vim.keymap.set('n', key, func) end
local function uc(cmd, action) vim.api.nvim_create_user_command(cmd, action, {}) end

register.keys = function (options)
	nkey(options.keymap.follow_link, function() Pages=actions.navigation.follow_link(Pages, options) end)
	nkey(options.keymap.previous_page, function() Pages=actions.navigation.previous_page(Pages) end)
	nkey(options.keymap.next_link, function() actions.navigation.next_link() end)
	nkey(options.keymap.previous_link, function() actions.navigation.previous_link() end)
	nkey(options.keymap.insert_date, function () actions.file.insert_date(options) end)
	nkey(options.keymap.insert_future_date, function () actions.file.insert_future_date(options) end)
	nkey(options.keymap.go_home, function () Pages=actions.navigation.go_home(Pages, options) end)
	nkey(options.keymap.remove_current_note, function () actions.structure.remove_current_note(Pages) end)
	nkey(options.keymap.rename_current_note, function () actions.structure.rename_current_note(options) end)
	nkey(options.keymap.increase_header_level, function () actions.file.increase_header_level() end)
	nkey(options.keymap.decrease_header_level, function () actions.file.decrease_header_level() end)

	if options.appearance.folding then
		nkey(options.keymap.reload_folding, function () actions.other.reload_folding() end)
	end
end


register.commands = function (options)
	uc('NvnFollowLink', function() Pages=actions.navigation.follow_link(Pages, options) end)
	uc('NvnPreviousPage', function() Pages=actions.navigation.previous_page(Pages) end)
	uc('NvnNextLink', function() actions.navigation.next_link() end)
	uc('NvnPreviousLink', function() actions.navigation.previous_link() end)
	uc('NvnInsertDate', function () actions.file.insert_date(options) end)
	uc('NvnInsertFutureDate', function () actions.file.insert_future_date(options) end)
	uc('NvnGoHome', function () Pages=actions.navigation.go_home(Pages, options) end)
	uc('NvnClose', function() behaviour.close() end)
	uc('NvnRemoveCurrentNote', function () actions.close.remove_current_note(Pages) end)
	uc('NvnRenameCurrentNote', function () actions.structure.rename_current_note(options) end)

	if options.appearance.folding then
		uc('NvnReloadFolding', function () actions.other.reload_folding() end)
	end

	-- register aliases
	if options.strict_closing then
		vim.cmd[[cnoreabbrev <expr> q "NvnClose"]]
		vim.cmd[[cnoreabbrev <expr> wq "NvnClose"]]
		vim.cmd[[cnoreabbrev <expr> qa "NvnClose"]]
	end
end

register.appearance = function (options)
	-- check if the input file matches the root file
	-- if not return, since it is not in the wiki
	if vim.api.nvim_buf_get_name(0) ~= options.root then
		return
	end

	if options.appearance.hide_numbers then
		vim.wo.linebreak = true
		vim.wo.number = false
		vim.wo.relativenumber = false
	end

	if options.appearance.folding then
		vim.wo.foldmethod = 'syntax'
		vim.wo.conceallevel = 2
		vim.cmd[[let g:markdown_folding = 1]]
	end

	vim.bo.filetype = 'markdown'
	vim.bo.ft='markdown'
end

return register

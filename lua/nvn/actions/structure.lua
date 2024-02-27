--- These are actions that edit the file structure of the notes folder.
-- @module structure
local structure = {}

-- imports
local navigation = require'nvn.actions.navigation'

--- Remove the current note a go back to the previous
--- @param pages Array(string)
structure.remove_current_note = function (pages)
	local result = (function ()
		while true do
			local result = string.upper(vim.fn.input("Are you sure you want delete the current file? [y/n] "))
		return (result == "Y")
		end
	end)()

	if not result then
		return
	end

	local file_to_delete = vim.api.nvim_buf_get_name(0)
	vim.api.nvim_buf_delete(0, {force = true})
	navigation.previous_page(pages)
	os.remove(file_to_delete)

	--while true do
	--	local result = string.upper(vim.fn.input("Are you sure you want delete the current file? [y/n] "))
	--	if result == "Y" then
	--		local file_to_delete = vim.api.nvim_buf_get_name(0)
	--		vim.api.nvim_buf_delete(0, {force = true})
	--		navigation.previous_page(pages)
	--		os.remove(file_to_delete)
	--		return
	--	elseif result == "N" then
	--		return
	--	end
	--end
end

return structure

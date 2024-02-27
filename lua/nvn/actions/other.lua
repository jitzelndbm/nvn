--- These are actions that edit a file's content
-- @module other
local other = {}

--- Reload the folding syntax, if the folding glitches or isn't done properly this can be used to reload it
other.reload_folding = function ()
	vim.wo.foldmethod = 'syntax'
	vim.cmd[[let g:markdown_folding = 1]]
	vim.bo.filetype = 'markdown'
	vim.bo.ft='markdown'
end

return other

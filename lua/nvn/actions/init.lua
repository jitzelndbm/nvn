local file = require'nvn.actions.file'
local navigation = require'nvn.actions.navigation'
local other = require'nvn.actions.other'
local structure = require'nvn.actions.structure'

return {
	file = file,
	navigation = navigation,
	other = other,
	structure = structure
}

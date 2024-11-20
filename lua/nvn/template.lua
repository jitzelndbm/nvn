local engine = require("nvn.engine")
local err = require("nvn.error")

---@class Path
local Path = require("nvn.path")

---@class Template
---@field path Path
local Template = {}
Template.__index = Template

---@param path Path
---@return table
function Template.new(path)
	local self = setmetatable({}, Template)
	self.path = path
	return self
end

---This helper function acts as a constructor with a nice UI. Useful for making handlers
---@param root string
---@param templates_folder string
---@return Template
function Template.from_picker(root, templates_folder)
	local status, p_or_err =
		xpcall(Path.new_from_rel_to_root, err.handler, root, templates_folder)
	if not status then
		error(
			"An error occured while constructing the templates folder path"
				.. p_or_err
		)
	end
	if not p_or_err:exists() then
		error("The templates folder does not exist")
	end

	-- Collect an iterator over the templates folder
	---@type string[]
	local template_files = {}
	for t in vim.fs.dir(p_or_err.full_path) do
		table.insert(template_files, t)
	end

	require("mini.pick").setup({})

	---@type string?
	local file = MiniPick.start({
		source = { items = template_files },
		window = { prompt_prefix = "Choose a template > " },
	})

	if not file then error("Template picker cancelled") end

	local final_path = Path.new_from_full(
		root,
		vim.fs.normalize(vim.fs.joinpath(p_or_err.full_path, file))
	)
	local self = setmetatable({}, Template)
	self.path = final_path
	return self
end

---This function renders a template from a file into a string
---@param self Template
---@param variables table
---@return string
function Template:render(variables)
	local file = io.open(self.path.full_path, "r")
	if not file then
		error("Could not open the template file: " .. self.path.full_path)
	end

	---@type string
	local content = file:read("*a")
	file:close()

	local template = engine.compile(content, false)
	return engine.render(template, variables)
end

return Template

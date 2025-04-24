---@module 'nvn.engine'
local engine = require("nvn.engine")

---@class Path
local Path = require("nvn.path")

---@class Result
local Result = require("nvn.result")

---@class Template
---@field path Path
local Template = {}
Template.__index = Template

---Create a template from a path
---
---@param path Path
---@return table
function Template.new(path)
	local self = setmetatable({}, Template)
	self.path = path
	return self
end

---This helper function acts as a constructor with a nice UI. Useful for making handlers
---
---@param root string
---@param templates_folder string
---@return Result Template
function Template.from_picker(root, templates_folder)
	local path = Path.new_unsafe(templates_folder)
	if not path:exists() then
		return Result.Err("The templates folder does not exist")
	end

	-- Collect an iterator over the templates folder
	---@type string[]
	local template_files = {}
	for t in vim.fs.dir(path.full_path) do
		table.insert(template_files, t)
	end

	local file_res = Result.pcall_err(
		MiniPick.start,
		'Make sure you ran `require("mini.pick").setup({})`',
		{
			source = { items = template_files },
			window = { prompt_prefix = "Choose a template > " },
		}
	)
	if file_res:is_err() then return file_res end
	local file = file_res:unwrap()
	if not file then return Result.Err("No template was selected") end

	local final_path_res = Path.new_from_full(
		root,
		vim.fs.normalize(vim.fs.joinpath(path.full_path, file))
	)
	if final_path_res:is_err() then return final_path_res end

	---@type Path
	local final_path = final_path_res:unwrap()

	local self = setmetatable({}, Template)
	self.path = final_path
	return Result.Ok(self)
end

---This function renders a template from a file into a string
---
---@param self Template
---@param variables table
---@return Result string
function Template:render(variables)
	local file_res = Result.pcall_err(
		io.open,
		"Could not open the template file: " .. self.path.full_path,
		self.path.full_path,
		"r"
	)
	if file_res:is_err() then return file_res end
	local file = file_res:unwrap() --[[@as file*]]

	---@type string
	local content = file:read("*a")
	file:close()

	local template_res = engine.compile(content, false)
	if template_res:is_err() then return template_res end

	return Result.Ok(
		engine.render(template_res:unwrap() --[[@as string]], variables)
	)
end

return Template

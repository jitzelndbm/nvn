local engine = require("nvn.engine")

---@class Template
---@field path Path
local Template = {}
Template.__index = {}

---@param path Path
---@return table
function Template.new(path)
	local self = setmetatable({}, Template)
	self.path = path
	return self
end

---This function renders a template from a file into a string
---@param variables table
---@return string
function Template:render(variables)
	local file = io.open(self.path.full_path, "r")
	if not file then error("Could not open the template file: " .. self.path.full_path) end

	---@type string
	local content = file:read("*a")
	file:close()

	local template = engine.compile(content, false)
	return engine.render(template, variables)
end

return Template

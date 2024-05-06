local engine = require 'nvn.template_engine'

Template = {}

function Template:new(root, templates_dir)
	if not templates_dir then
		vim.notify("No template directory was supplied", vim.log.levels.ERROR)
		return nil
	end

	local instance = setmetatable({}, self)
	self.__index = self

	local template_files = {}
	for template in vim.fs.dir(templates_dir) do
		table.insert(template_files, template)
	end

	vim.ui.select(template_files, {
		prompt = '',
	}, function(choice)
		self.file = choice
	end)

	if not self.file then
		return
	end

	-- Read the content of the file
	self.path = vim.fs.dirname(root).."/"..templates_dir.."/"..self.file
	self.content = vim.fn.join(vim.fn.readfile(self.path), "\n")

	return instance
end

function Template:render(variable_map)
	local compiled_function_template = engine.compile(self.content, false)
	return engine.render(compiled_function_template, variable_map)

end

return Template

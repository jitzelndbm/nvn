---@class Navigation
local Navigation = require("nvn.navigation")

---Represents a note file, this class has the responsibility over the contents of a note. This class does not (or barely) interact with the file tree
---@class Note
---@field path Path
---@field navigation Navigation
local Note = {}
Note.__index = Note

---Constructor for the note class
---@param path Path
---@return Note
function Note.new(path)
	local self = setmetatable({}, Note)
	self.path = path
	self.navigation = Navigation.new(self)
	return self
end

---Call function on a buffer
---@param self Note
---@param f function the function that will be executed on the buffer
---@return any
function Note:buf_call(f)
	f = f or error("No callback function was provided")
	local status, err_or_value = pcall(vim.api.nvim_buf_call, 0, f)
	if not status then error(err_or_value) end
	return err_or_value
end

---This function will overwrite the content of a note, replacing it with a template
---@param template Template
---@param force? boolean
function Note:write_template(template, force)
	force = force or false
end

---Overwrites the entire note with new content
---@param ... string
function Note:write(...)
	local file = io.open(self.path.full_path, "w") or error("File could not be opened: " .. self.path.full_path)

	-- Create an array from the args, then join them with new lines and write to the file
	file:write(vim.fn.join({ ... }, "\n"))

	file:close()
end

function Note:evaluate()
end

function Note:get_links()
end

return Note

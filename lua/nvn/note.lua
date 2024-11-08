---Represents a note file
---@class Note
---@field title string
---@field path Path

local Path = require("nvn.path")
local Template = require("nvn.template")

local Note = {}
Note.__index = Note

function Note.new(path, title)
	local self = setmetatable({}, Note)
	self.path = path
	self.title = title
	return Note
end

---This function makes sure that the path under the note is created/overwritten
---@param force boolean
---@param template Template
function Note:write(force, template)
end

---Moves a note to a new location
---@param force boolean Overwrites the note under the new path
---@param new_path any 
function Note:move(force, new_path)
end

function Note:remove()
end

function Note:evaluate()
end

function Note:get_links()
end

function Note:buf_call(call)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(bufnr, self.path.get_file_name())
	vim.api.nvim_buf_call(bufnr, )
end

---@class Note
local Note = require("nvn.note")

---@class Path
local Path = require("nvn.path")

---This class hold responsibility over the management of notes.
---@class Client
---@field config table This table holds a configuration scheme
---@field current Note
local Client = {}
Client.__index = Client

---This is the constructor method for the client class
---@param config table
---@return Client
function Client.new(config)
	local self = setmetatable({}, Client)
	self.config = config
	local status, path_or_err = pcall(
		Path.new_from_full,
		config.root,
		config.root .. "/" .. config.index
	)
	if status and path_or_err ~= nil then
		self.current = Note.new(path_or_err)
	else
		error(path_or_err)
	end

	return self
end

---Move the nvn buffer to a new location
---@param note Note
function Client:set_location(note)
	self.current:buf_call(function()
		if self.config.auto_save then
			vim.cmd.write()
			vim.api.nvim_buf_delete(0, {})
		else
			vim.api.nvim_buf_delete(0, { force = true })
		end
	end)

	vim.cmd.edit(note.path.full_path)
end

---This function adds a new note to the store / does all the file system stuff
---@param note Note
function Client:add(note)
	note = note or self.current
end

-- NOTE: maybe needed
-----This function writes content of a note to the fill system (saving).
-----@param note? Note
--function Client:write(note)
--	note = note or self.current
--end

---
---@param n? Note
function Client:move(n, new_path)
	n = n or self.current
end

---This function removes a note from the file system, forcefully
---@param n? Note
function Client:remove(n)
	n = n or self.current
end

return Client

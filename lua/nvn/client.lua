---@class Note
local Note = require("nvn.note")

---@class Path
local Path = require("nvn.path")

---@class History
local History = require("nvn.history")

---This class hold responsibility over the management of notes.
---@class Client
---@field config table This table holds the configuration scheme
---@field current Note
---@field history History
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
	self.history = History.new(self.current)
	return self
end

---Move the nvn buffer to a new location
---@param note Note
function Client:set_location(note)
	self.current = note

	-- Delete all other buffers
	self.current:buf_call(function()
		if self.config.auto_save then
			vim.cmd.write()
			vim.api.nvim_buf_delete(0, {})
		else
			vim.api.nvim_buf_delete(0, { force = true })
		end
	end)

	-- Edit the new note
	vim.cmd.edit(note.path.full_path)
end

---This function makes sure that a note on the file system, it only creates files/directories.
---@param note Note
function Client:add(note)
	note = note or self.current

	local path = note.path.full_path

	-- Adjust the file path if needed
	if note.path.full_path:sub(-1) == "/" then
		path = vim.fs.normalize(vim.fs.join(path, self.config.index))
	end

	vim.fn.mkdir(vim.fs.dirname(path), "-p")

	-- Open the file in write mode without deleting its contents
	local file, errmsg = io.open(note.path.full_path, "a+")

	if not file then
		return error("Error while trying to write " .. note.path.full_path .. ": " .. errmsg)
	end

	file:close()
end

-- NOTE: maybe needed
-----This function writes content of a note to the fill system (saving).
-----@param note? Note
--function Client:write(note)
--	note = note or self.current
--end

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

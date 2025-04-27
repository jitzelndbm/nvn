---@class Result
local Result = require("nvn.result")

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

---Returns a new client given a configuration
---
---@param config table configuration that should follow a predefined scheme in init.lua
---@return Result client
function Client.new(config)
	local self = setmetatable({}, Client)
	self.config = config

	-- Get the dirname of the current full path
	self.config.root = vim.fs.dirname(vim.fn.expand("%:p"))

	local path =
		Path.new_from_full(config.root, config.root .. "/" .. config.index)
	if path:is_err() then return path end

	self.current = Note.new(path:unwrap())
	self.history = History.new(self.current)

	return Result.Ok(self)
end

---Move the nvn buffer to a new location
---
---@param note Note the new buffer
---@param force boolean? forcefully remove current buffer, override auto save
function Client:set_location(note, force)
	self.current = note

	-- Delete all other buffers
	if self.config.auto_save and not force then
		vim.cmd.write()
		vim.api.nvim_buf_delete(0, {})
	else
		vim.api.nvim_buf_delete(0, { force = true })
	end

	-- Edit the new note
	vim.cmd.edit(note.path.full_path)
end

---This function makes ensures that a note is on the file system, it only creates files/directories.
---
---@param note Note Can be an index note or a normal note
---@return Result Nil
function Client:add(note)
	note = note or self.current

	local path = note.path.full_path

	-- Append the index file to the note
	if note.path.full_path:sub(-1) == "/" then
		path = vim.fs.normalize(vim.fs.join(path, self.config.index))
	end

	-- Ensure parent folder exist
	vim.fn.mkdir(vim.fs.dirname(path), "-p")

	-- Open the file in append mode to create it
	local file, errmsg = io.open(note.path.full_path, "a+")
	if not file then
		return Result.Err(
			"Error while trying to write "
				.. note.path.full_path
				.. ": "
				.. errmsg
		)
	end

	file:close()

	return Result.Ok(nil)
end

-- NOTE maybe needed
-----This function writes content of a note to the fill system (saving).
-----@param note? Note
--function Client:write(note)
--	note = note or self.current
--end

--TODO
-- ---@param n? Note
-- function Client:move(n, new_path) n = n or self.current end

---This function removes a note from the file system, forcefully
---
---@param note Note
---@return Result Nil
function Client:remove(note)
	if not note.path:exists() then
		return Result.Err("The note does not exist")
	end

	local res = Result.pcall(os.remove, note.path.full_path)
	if res:is_err() then return res end

	return Result.Ok(nil)
end

--TODO
-- function Client:get_all_notes()
-- end

return Client

local note = require("nvn.note")
local path = require("nvn.path")

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
	self.current = note.new(path.new_from_full(config.root, config.root .. "/" .. config.index))
	return self
end

---Move the nvn buffer to a new location
---@param n Note
function Client:set_location(n)
end

---This function adds a new note to the store / does all the file system stuff
---@param n? Note
function Client:add(n)
	n = n or self.current
end

---This function writes content of a note to the fill system (saving).
---@param n? Note
function Client:write(n)
	n = n or self.current
end

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

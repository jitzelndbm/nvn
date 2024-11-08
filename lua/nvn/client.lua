---This class hold responsibility over the management of notes.
---@class Client
---@field config table This table holds a configuration scheme
local Client = {}
Client.__index = Client

-- Imports
local Note = require 'nvn.note'

-- Methods

---This is the constructor method for the client class
---@param config table
---@return Client
function Client.new(config)
	local self = setmetatable({}, Client)
	self.config = config
	return self
end

---This function adds a new note to the store
---@param note Note
function Client:add_note(note) end

return Client

---This basically works like a stack data structure with a default value if it's empty
---@class History
---@field root_note Note
---@field data Note[]
local History = {}
History.__index = History

function History.new(root_note)
	local self = setmetatable({}, History)
	self.root_note = root_note
	self.data = {}
	return self
end

---Get the last note from the history
---@return Note
function History:last()
	if #self.data == 0 then return self.root_note end
	return self.data[#self.data]
end

---Pop the last entry out of the note history
---@return Note
function History:pop()
	if #self.data == 0 then return self.root_note end
	return table.remove(self.data, #self.data)
end

---Push a new note to the history
---@param new Note
function History:push(new)
	table.insert(self.data, new)
end

return History

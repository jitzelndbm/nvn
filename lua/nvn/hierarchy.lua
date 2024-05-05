Hierarchy = {}

--- Create a new BTree hierarchy of the notes
--- This is used for showing backlinks
function Hierarchy:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

History = {}

function History:new(root)
	local instance = setmetatable({}, self)
	self.__index = self
	instance.root = root
	instance.data = {}
	return instance
end

function History:last()
	if #self.data == 0 then return self.root end

	return self.data[#self.data]
end

function History:pop()
	if #self.data == 0 then return self.root end

	return table.remove(self.data, #self.data)
end

function History:push(new_location)
	if type(new_location) ~= 'string' then
		vim.notify('history: new_location should be a string!', vim.log.levels.ERROR)
		return nil
	end

	table.insert(self.data, new_location)
	vim.notify('history: pushed ' .. new_location, vim.log.levels.DEBUG)
end

return History

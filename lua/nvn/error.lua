---@module 'error'
local error = {}

function error.handler(err)
	return "\n" .. err
end

function error.print(err)
	local firstNewline = err:find("\n")

	if firstNewline then
	    err = err:sub(firstNewline + 1)
	end

	print("Stack trace:\n")
	print(err)
end

return error

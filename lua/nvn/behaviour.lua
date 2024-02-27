--- Behavioural changes to the editors
-- @module behaviour
local behaviour = {}

behaviour.close = function ()
	while true do
		local result = string.upper(vim.fn.input("Are you sure you want to exit and save? [y/n/b] "))

		if result == "Y" then
			vim.cmd.wqall()
			break
		elseif result == "N" then
			break
		elseif result == "B" then
			vim.cmd.close()
			break
		end
	end
end

return behaviour

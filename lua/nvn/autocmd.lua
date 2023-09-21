M = {}

M.close = function ()
	while true do
		local result = string.upper(vim.fn.input("Are you sure you want to exit and save? [y/n] "))

		if result == "Y" then
			vim.cmd.wqall()
			break
		elseif result == "N" then
			break
		end
	end
end

return M

-- Credit goes to Danila Poyarkov <dannotemail@gmail.com>
-- https://github.com/dannote/lua-template
--
-- DISCLAIMER: This code has been modified

local engine = {}

local err = require("nvn.error")

function engine.escape(data)
	return tostring(data or ""):gsub("[\">/<'&]", {
		["&"] = "&",
		["<"] = "<",
		[">"] = ">",
		['"'] = '"',
		["'"] = "'",
		["/"] = "/",
	})
end
function engine.render(data, args)
	local str = ""
	local function exec(data)
		if type(data) == "function" then
			args = args or {}
			setmetatable(args, { __index = _G })
			setfenv(data, args)
			data(exec)
		else
			str = str .. tostring(data or "")
		end
	end
	exec(data)

	return str
end

function engine.print(data, args, callback)
	callback = callback or print
	local function exec(data)
		if type(data) == "function" then
			args = args or {}
			setmetatable(args, { __index = _G })
			setfenv(data, args)
			data(exec)
		else
			callback(tostring(data or ""))
		end
	end
	exec(data)
end

function engine.parse(data, minify)
	local str = "return function(_)"
		.. "function __(...)"
		.. "_(require('nvn.engine').escape(...))"
		.. "end "
		.. "_[=["
		.. data:gsub("[][]=[][]", ']=]_"%1"_[=[')
			:gsub("<%%=", "]=]_(")
			:gsub("<%%", "]=]__(")
			:gsub("%%>", ")_[=[")
			:gsub("<%?", "]=] ")
			:gsub("%?>", " _[=[")
		.. "]=] "
		.. "end"

	if minify then
		str = str:gsub("^[ %s]*", ""):gsub("[ %s]*$", ""):gsub("%s+", " ")
	end

	return str
end

function engine.compile(...)
	-- NOTE: added new lines to the errors, so they stand out more, end users interact
	-- with these errors much.

	local template_func, err_msg = loadstring(engine.parse(...))
	if not template_func then
		error("Parse error in template: \n\n" .. err_msg)
	end

	---@type boolean
	local success
	---@type string
	local result_or_err
	success, result_or_err = xpcall(template_func, err.handler)
	if not success then
		error("Runtime error in template: \n\n" .. result_or_err)
	end

	return result_or_err
end

return engine

-- Credit goes to Danila Poyarkov <dannotemail@gmail.com>
-- https://github.com/dannote/lua-template
--
-- note: code has been modified

local engine = {}

---@class Result
local Result = require("nvn.result")

---@diagnostic disable:redefined-local

---@param data string
---@return string
function engine.escape(data)
	return (
		tostring(data or ""):gsub("[\">/<'&]", {
			["&"] = "&",
			["<"] = "<",
			[">"] = ">",
			['"'] = '"',
			["'"] = "'",
			["/"] = "/",
		})
	)
end

---@param data string | function
---@param args table?
---@return string
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

---@param data string | function
---@param args table?
---@param callback function?
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

---@param data table
---@param minify boolean
---@return string
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

---@param ... unknown
---@return Result string
function engine.compile(...)
	local template_func, err_msg = loadstring(engine.parse(...))
	if not template_func then
		return Result.Err("Parse error in template: \n\n" .. err_msg)
	end
	return Result.pcall(template_func)
end

return engine

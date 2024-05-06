-- Credit goes to Danila Poyarkov <dannotemail@gmail.com>
-- https://github.com/dannote/lua-template
--
-- DISCLAIMER: This code has been modified

local engine = {}

function engine.escape(data)
	return tostring(data or ''):gsub("[\">/<'&]", {
		["&"] = "&",
		["<"] = "<",
		[">"] = ">",
		['"'] = '"',
		["'"] = "'",
		["/"] = "/"
	})
end

function engine.render(data, args)
	local str = ''
	local function exec(data)
		if type(data) == "function" then
			args = args or {}
			setmetatable(args, { __index = _G })
			setfenv(data, args)
			data(exec)
		else
			str = str .. tostring(data or '')
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
			callback(tostring(data or ''))
		end
	end
	exec(data)
end

function engine.parse(data, minify)
	local str =
	"return function(_)" ..
		"function __(...)" ..
		"_(require('nvn.template_engine').escape(...))" ..
	"end " ..
	"_[=[" ..
	data:
		gsub("[][]=[][]", ']=]_"%1"_[=['):
		gsub("<%%=", "]=]_("):
		gsub("<%%", "]=]__("):
		gsub("%%>", ")_[=["):
		gsub("<%?", "]=] "):
		gsub("%?>", " _[=[") ..
	"]=] " ..
	"end"

	if minify then
		str = str:
			gsub("^[ %s]*", ""):
			gsub("[ %s]*$", ""):
			gsub("%s+", " ")
	end

	return str
end

function engine.compile(...)
	return loadstring(engine.parse(...))()
end

return engine

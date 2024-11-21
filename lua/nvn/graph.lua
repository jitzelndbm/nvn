---@class Path
local Path = require("nvn.path")

---@class Note
local Note = require("nvn.note")

---@class Graph
---@field graph_path string
---@field html_template string
local Graph = {}
Graph.__index = Graph

function Graph.new()
	local self = setmetatable({}, Graph)

	local lib_path = vim.fs.normalize(vim.fs.joinpath(debug.getinfo(1, "S").source:sub(2), "../../../lib/"))

	local html_path = vim.fs.joinpath(lib_path, "./graph.html")
	local html_file = io.open(html_path) or error("Could not find html template file: " .. html_path)

	self.graph_path = vim.fs.joinpath(lib_path, "./graph.min.js")
	self.html_template = html_file:read("*a")

	html_file:close()

	return self
end

function Graph:open(client)
	-- Get all files notes
	---@type string[]
	local files = vim.fs.find(
		function(name, _) return name:match(".md$") end,
		{
			limit = math.huge,
			type = "file",
			path = client.config.root
		}
	)

	for _, file in ipairs(files) do
		local p = Path.new_from_full(client.config.root, file)
		local n = Note.new(p)

		---@type Link[]
		local links =  n:get_links()

		for _, link in ipairs(links) do
			print(link.url)
		end

		-- ... Should somehow determine if the link is external or not ...
		--
		-- note on this however, the links can have custom handlers, but there are two default ones, ".md$" and "/$" meaning that 
	end
end

return Graph

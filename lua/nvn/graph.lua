---@class Graph
---@field graph_path string
---@field html_template string
local Graph = {}
Graph.__index = Graph


function Graph.new(client)
	local self = setmetatable({}, Graph)

	local lib_path = vim.fs.normalize(vim.fs.joinpath(debug.getinfo(1, "S").source:sub(2), "../lib/"))

	local html_file = io.open(vim.fs.joinpath(lib_path, "graph.html")) or error("Could not find html template file")

	html_file:close()

	self.graph_path = vim.fs.joinpath(lib_path, "graph.min.js")
	self.html_template = html_file:read("*a")

	return self
end

function Graph:open()
	-- Get all files
end

return Graph

---@class Path
local Path = require("nvn.path")

---@class Note
local Note = require("nvn.note")

---@class Graph
---@field graph_path string
---@field html_template string
---@field out_path string
---
---@field nodes string[]
---@field edges { from: string, to: string }[]
local Graph = {}
Graph.__index = Graph

function Graph.new()
	local self = setmetatable({}, Graph)

	local lib_path = vim.fs.normalize(vim.fs.joinpath(debug.getinfo(1, "S").source:sub(2), "../../../lib/"))

	local html_path = vim.fs.joinpath(lib_path, "./graph.html")
	local html_file = io.open(html_path) or error("Could not find html template file: " .. html_path)

	self.out_path = vim.fs.normalize(
		vim.fs.joinpath(vim.fn.stdpath("data"), "nvn", "graph.html")
	)

	self.graph_path = vim.fs.joinpath(lib_path, "./graph.min.js")
	self.html_template = html_file:read("*a")

	html_file:close()

	return self
end

---@param self Graph
---@return string
function Graph:serialize()
	local jd = "["
	for _, node in pairs(self.nodes) do
		jd = jd .. '"' .. node .. '",'
	end
	jd = jd .. '],['
	for _, edge in pairs(self.edges) do
		jd = jd .. '["' .. edge.from .. '","' .. edge.to .. '"' .. '],'
	end
	jd = jd .. ']'
	return jd
end

function Graph:open()
	local res = string.format(
		self.html_template,
		self.graph_path,
		self:serialize()
	)

	vim.fn.mkdir(vim.fs.dirname(self.out_path), "-p")
	local out_file, errmsg = io.open(self.out_path, "w")
	if not out_file then error(errmsg) end
	out_file:write(res)
	out_file:close()

	vim.ui.open(self.out_path)
end

function Graph:construct(client)
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

	---@type { [string]: boolean }
	local node_set = {}

	---@type { [string]: {[string]: boolean } }
	local edge_set = {}

	for _, file in ipairs(files) do
		local p = Path.new_from_full(client.config.root, file)
		local n = Note.new(p)

		---@type Link[]
		local links = n:get_links()

		for _, link in ipairs(links) do
			local resolved_dest = link.url

			if link.url:find(".md$") or link.url:find("/$") or link.url:find("^.$") or link.url:find("^..$") then
				resolved_dest = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(p.rel_to_root), link.url))
				-- Append the index if the resolved route is a folder
				local stat = vim.uv.fs_stat(resolved_dest)
				if stat and stat.type == "directory" then
					resolved_dest = vim.fs.normalize(vim.fs.joinpath(resolved_dest, client.config.index))
				end
			end

			node_set[resolved_dest] = true
			if not p.rel_to_root:find("^"..client.config.template_folder) then
				edge_set[p.rel_to_root] = edge_set[p.rel_to_root] or {}
				edge_set[p.rel_to_root][resolved_dest] = true
			end
		end
	end

	self.nodes = {}
	for node, _ in pairs(node_set) do
		table.insert(self.nodes, node)
	end

	self.edges = {}
	for from, tos in pairs(edge_set) do
		for to, _ in pairs(tos) do
			table.insert(self.edges, { from = from, to = to })
		end
	end
end

return Graph

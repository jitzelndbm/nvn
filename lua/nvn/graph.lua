---@class Path
local Path = require("nvn.path")

---@class Note
local Note = require("nvn.note")

---@class Result
local Result = require("nvn.result")

---@class Option
local Option = require("nvn.option")

---@class Graph
---@field graph_path string
---@field html_template string
---@field out_path string
---@field nodes string[]
---@field edges { from: string, to: string }[]
local Graph = {}
Graph.__index = Graph

---Constructor for uninitialized graph
---
---@return Result Graph
function Graph.new()
	local self = setmetatable({}, Graph)

	local lib_path = vim.fs.normalize(
		vim.fs.joinpath(debug.getinfo(1, "S").source:sub(2), "../../../lib/")
	)

	local html_path = vim.fs.joinpath(lib_path, "./graph.html")
	local html_file_res = Result.pcall_err(
		io.open,
		"Graph html file not found: " .. html_path,
		html_path
	)
	if html_file_res:is_err() then return html_file_res end
	local html_file = html_file_res:unwrap() --[[@as file*]]

	local data_path_res = Option.Some(vim.fn.stdpath("data"))
		:ok_or("Local data path not found")
	if data_path_res:is_err() then return data_path_res end
	local data_path = data_path_res:unwrap() --[[@as string]]

	self.out_path =
		vim.fs.normalize(vim.fs.joinpath(data_path, "nvn", "graph.html"))
	self.graph_path = vim.fs.joinpath(lib_path, "./graph.min.js")
	self.html_template = html_file:read("*a")

	html_file:close()

	return Result.Ok(self)
end

---@param self Graph
---@return string
function Graph:serialize()
	local jd = "["
	for _, node in pairs(self.nodes) do
		jd = jd .. '"' .. node .. '",'
	end
	jd = jd .. "],["
	for _, edge in pairs(self.edges) do
		jd = jd .. '["' .. edge.from .. '","' .. edge.to .. '"' .. "],"
	end
	jd = jd .. "]"
	return jd
end

---Open the graph in the browser
---
---@return Result
function Graph:open()
	local res =
		string.format(self.html_template, self.graph_path, self:serialize())

	vim.fn.mkdir(vim.fs.dirname(self.out_path), "-p")

	local out_files_res = Result.pcall(io.open, self.out_path, "w")
	if out_files_res:is_err() then return out_files_res end
	local out_file = out_files_res:unwrap() --[[@as file*]]

	out_file:write(res)
	out_file:close()

	vim.ui.open(self.out_path)

	return Result.Ok(nil)
end

---Constructs a graph from note collection
---
---@param client Client
---@return Result
function Graph:construct(client)
	-- Find all note files, skip template folder
	---@type string[]
	local files = vim.fs.find(
		function(name, path)
			return name:match(".md$")
				and not path:match("^" .. client.config.template_folder)
		end,
		{
			limit = math.huge,
			type = "file",
			path = client.config.root,
		}
	)

	-- Boolean added for easy unique insertion
	---@type { [string]: boolean }
	local node_set = {}

	-- Again boolean is for unique insertion
	---@type { [string]: {[string]: boolean } }
	local edge_set = {}

	for _, file in ipairs(files) do
		-- Create a note for every file
		local path_res = Path.new_from_full(client.config.root, file)
		if path_res:is_err() then return path_res end

		---@type Path
		local path = path_res:unwrap()
		local note = Note.new(path)

		-- Insert source note
		node_set[note.path.rel_to_root] = true

		local links_res = note:get_links()
		if links_res:is_err() then return links_res end

		for _, link in
			ipairs(links_res:unwrap() --[[@as Link[]=]])
		do
			local resolved_dest = link.url

			if
				link.url:find(".md$")
				or link.url:find("/$")
				or link.url:find("^.$")
				or link.url:find("^..$")
			then
				resolved_dest = vim.fs.normalize(
					vim.fs.joinpath(vim.fs.dirname(path.rel_to_root), link.url)
				)
				-- Append the index if the resolved route is a folder
				local stat = vim.uv.fs_stat(resolved_dest)
				if stat and stat.type == "directory" then
					resolved_dest = vim.fs.normalize(
						vim.fs.joinpath(resolved_dest, client.config.index)
					)
				end
			end

			node_set[resolved_dest] = true
			if
				not path.rel_to_root:find("^" .. client.config.template_folder)
			then
				edge_set[path.rel_to_root] = edge_set[path.rel_to_root] or {}
				edge_set[path.rel_to_root][resolved_dest] = true
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

	return Result.Ok(nil)
end

return Graph

---@class Option
local Option = require("nvn.option")
---@class Result
local Result = require("nvn.result")

---@class Link
local Link = require("nvn.link")

local LINK_QUERY = [[
(inline_link) @link
(shortcut_link) @shortcut
]]

---@class Navigation
---@field note Note
local Navigation = {}
Navigation.__index = Navigation

---@param note Note
---@return Navigation
function Navigation.new(note)
	local self = setmetatable({}, Navigation)
	self.note = note
	return self
end

---Search links in the document where the navigation module instance belongs to
---@param self Navigation
---@param enableFallback boolean
---@param direction "forwards"|"backwards"
---@param filter fun(cur_row: integer, cur_col: integer, link_row: integer, link_col): boolean
---@return Result Link
function Navigation:search_link(enableFallback, direction, filter)
	return self.note:buf_call(function()
		-- Process tree sitter query of current note
		local tree =
			vim.treesitter.get_parser(0, "markdown_inline"):parse()[1]:root()
		local query = vim.treesitter.query.parse("markdown_inline", LINK_QUERY)
		local iter = query:iter_captures(tree, 0)

		-- Collect query iterator into an array
		---@type TSNode[]
		local nodes = {}
		local i = 1
		for _, node in iter do
			nodes[i] = node
			i = i + 1
		end

		---@type integer, integer
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		---@type Option link
		local fallback = Option.None()

		-- Setup the loop
		local backwards = direction == "backwards"
		local start_index, end_index, step =
			(backwards and #nodes) or 1,
			(backwards and 1) or #nodes,
			(backwards and -1) or 1

		for j = start_index, end_index, step do
			local link = Link.new(nodes[j])
			if link:is_err() then return link end

			-- Optionally insert fallback link
			if fallback:is_none() then fallback:insert(link) end

			local lrow, lcol = nodes[j]:start()

			-- If premise is met, return the link
			if filter(row - 1, col, lrow, lcol) then return link end

			i = i + 1
		end

		if enableFallback and fallback:is_some() then
			return (
				fallback:unwrap() --[[@as Result]]
			)
		end

		return Result.Err("No link can be found and fallback failed")
	end)
end

---@param self Navigation
---@return Result Link
function Navigation:next_link()
	return self:search_link(
		true,
		"forwards",
		function(row, col, lrow, lcol)
			return (row == lrow and col < lcol) or row < lrow
		end
	)
end

---@param self Navigation
---@return Result Link
function Navigation:previous_link()
	return self:search_link(
		true,
		"backwards",
		function(row, col, lrow, lcol)
			return lrow < row or (lrow == row and lcol < col)
		end
	)
end

---@param self Navigation
---@return Result Link
function Navigation:current_link()
	-- Get the node under the cursor
	local node =
		Option.Some(vim.treesitter.get_node({ lang = "markdown_inline" }))
	if node:is_none() then
		return Result.Err(
			"Treesitter node for markdown_inline lang could not be read"
		)
	end

	-- Create a 'fallthrough switch case' statement that points to functions
	---@type fun(n: TSNode): Result
	local create = function(n) return Link.new(n) end

	---@type fun(n: TSNode): Result
	local create_parent = function(n)
		return Link.new(n:parent() --[[@as TSNode]])
	end

	---@type {string: fun(n: TSNode): Result}
	local types = {
		["inline_link"] = create,
		["shortcut_link"] = create,
		["link_text"] = create_parent,
		["link_destination"] = create_parent,
		["link_title"] = create_parent,
	}

	-- Execute the funcition with the right node type
	local link_creator = Option.Some(types[node:unwrap():type()] or nil)
	if link_creator:is_none() then
		return Result.Err("TSNode under cursor is not of right type")
	end

	return (link_creator:unwrap() --[[@as fun(n: TSNode): Result]])(
		node:unwrap()
	)
end

return Navigation

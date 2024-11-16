---@class Link
local Link = require("nvn.link")

local err = require("nvn.error")

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
---@param fallback boolean
---@param direction "forwards"|"backwards"
---@param filter function
---@return Link | error
function Navigation:search_link(fallback, direction, filter)
	---@type boolean
	local status

	---@type Link | error
	local found_or_err

	status, found_or_err = xpcall(
		self.note.buf_call,
		err.handler,
		self.note,
		function()
			local tree = vim.treesitter.get_parser(0, "markdown_inline"):parse()
			local root = tree[1]:root()
			local result =
				vim.treesitter.query.parse("markdown_inline", LINK_QUERY)
			local iter = result:iter_captures(root, 0)

			local row, col = unpack(vim.api.nvim_win_get_cursor(0))

			---@type TSNode[]
			local nodes = {}

			-- Collect the iterator into an array of nodes
			local i = 1
			for _, node in iter do
				nodes[i] = node
				i = i + 1
			end

			---@type Link?
			local fallback_link

			-- Setup the loop
			local backwards = direction == "backwards"
			local start_index, end_index, step =
				(backwards and #nodes) or 1,
				(backwards and 1) or #nodes,
				(backwards and -1) or 1

			for j = start_index, end_index, step do
				local lrow, lcol = nodes[j]:start()

				-- Try to construct a link from the node
				local success, link_or_err =
					xpcall(Link.new, err.handler, nodes[j])
				if not success then
					error("Construction of a link failed" .. link_or_err)
				end

				-- Edit first and last
				if not fallback_link then fallback_link = link_or_err end

				-- If premise is met, return the link
				if filter(row - 1, col, lrow, lcol) then return link_or_err end

				i = i + 1
			end

			if fallback then
				return fallback_link
			else
				error(
					"No link could be found and fallback was disabled"
					.. found_or_err
				)
			end
		end
	)

	if status then
		return found_or_err
	else
		error("Searching for links failed" .. found_or_err)
	end
end

---@param self Navigation
---@return Link | error
function Navigation:next_link()
	local status, link_or_err = xpcall(
		Navigation.search_link,
		err.handler,
		self,
		true,
		"forwards",
		function(row, col, lrow, lcol)
			return (row == lrow and col < lcol) or row < lrow
		end
	)

	if status then
		return link_or_err
	else
		error("Next link could not be found" .. link_or_err)
	end
end

---@param self Navigation
---@return Link | error
function Navigation:previous_link()
	local status, link_or_err = xpcall(
		Navigation.search_link,
		err.handler,
		self,
		true,
		"backwards",
		function(row, col, lrow, lcol)
			return lrow < row or (lrow == row and lcol < col)
		end
	)

	if status then
		return link_or_err
	else
		error("Previous link could not be found" .. link_or_err)
	end
end

---@param self Navigation
---@return Link
function Navigation:current_link()
	-- Get the node under the cursor
	local node = vim.treesitter.get_node({ lang = "markdown_inline" })
	if node == nil then
		error("Treesitter node for markdown_inline lang could not be read")
	end

	-- Create a 'fallthrough switch case' statement that points to functions
	local create = function(n) return Link.new(n) end
	local create_parent = function(n) return Link.new(n:parent()) end
	local types = {
		["inline_link"] = create,
		["shortcut_link"] = create,
		["link_text"] = create_parent,
		["link_destination"] = create_parent,
		["link_title"] = create_parent,
	}

	-- Execute the funcition with the right node type
	local link_creator = types[node:type()]
		or error("TSNode under cursor is not of right type")
	return link_creator(node)
end

return Navigation

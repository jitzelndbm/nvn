---@class Navigation
local Navigation = require("nvn.navigation")

---@class Path
local Path = require("nvn.path")

local err = require("nvn.error")

local BLOCK_QUERY = [[
(fenced_code_block) @inside
]]

local EXTERNAL_QUERY = [[
(html_block) @block
]]

---Represents a note file, this class has the responsibility over the contents of a note. This class does not (or barely) interact with the file tree
---@class Note
---@field path Path
---@field navigation Navigation
local Note = {}
Note.__index = Note

---Constructor for the note class
---@param path Path
---@return Note
function Note.new(path)
	local self = setmetatable({}, Note)
	self.path = path
	self.navigation = Navigation.new(self)
	return self
end

---Call function on a buffer
---@param self Note
---@param f function the function that will be executed on the buffer
---@return any
function Note:buf_call(f)
	f = f or error("No callback function was provided")
	local status, err_or_value =
		xpcall(vim.api.nvim_buf_call, err.handler, 0, f)
	if not status then error("Error in buffer call" .. err_or_value) end
	return err_or_value
end

-- ---This function will overwrite the content of a note, replacing it with a template
-- ---@param template Template
-- ---@param force? boolean
-- function Note:write_template(template, force) force = force or false end

---Overwrites the entire note with new content
---@param force boolean
---@param ... string
function Note:write(force, ...)
	if not self.path:exists() and not force then
		error(
			"Note exists on file system, thus may contain content. To overwrite enable arg force."
		)
	end

	local file = io.open(self.path.full_path, "w")
		or error("File could not be opened: " .. self.path.full_path)

	-- Create an array from the args, then join them with new lines and write to the file
	file:write(vim.fn.join({ ... }, "\n"))

	file:close()
end

---Replace lines between
---@param begin_line uinteger
---@param end_line uinteger
---@param lines string[]
function Note:set_lines(begin_line, end_line, lines)
	self:buf_call(
		function()
			vim.api.nvim_buf_set_lines(0, begin_line, end_line, false, lines)
		end
	)
end

function Note:evaluate()
	self:buf_call(function()
		-- First go over all code blocks
		local markdown_root =
			vim.treesitter.get_parser(0, "markdown"):parse()[1]:root()
		local query = vim.treesitter.query.parse("markdown", BLOCK_QUERY)
		local iter = query:iter_captures(markdown_root, 0)
		for _, node in iter do
			local lang_node = node:child(1)
			if not lang_node then goto continue end

			local lang = vim.treesitter.get_node_text(lang_node, 0)
			if not (lang == "lua,eval" or lang == "lua, eval") then
				goto continue
			end

			local src_node = node:child(3)
			if not src_node then goto continue end

			local src = vim.treesitter.get_node_text(src_node, 0)
			-- NOTE: this means the inline source block is empty
			if src == "```" then goto continue end
			local end_row, _, _ = src_node:end_()

			local eval_func, parse_error = loadstring(src)
			if not eval_func then
				error("Parse error occured in block at: " .. parse_error)
			end

			local success, res_or_err = xpcall(eval_func, err.handler)
			if not success then
				error(
					"Runtime error during execution of code block" .. res_or_err
				)
			end

			-- If the result of the block is nil, don't replace lines
			if res_or_err then
				self:set_lines(
					end_row + 1,
					end_row + 1,
					vim.fn.split(res_or_err, "\n")
				)
			end

			::continue::
		end

		-- Then go over comment lines, external sources
		local html_root =
			vim.treesitter.get_parser(0, "markdown"):parse()[1]:root()
		query = vim.treesitter.query.parse("markdown", EXTERNAL_QUERY)
		iter = query:iter_captures(html_root, 0)

		---@type Path?
		local path

		---@type uinteger
		local begin_row

		for _, node in iter do
			if path then
				-- Close directive
				local text = vim.treesitter.get_node_text(node, 0)
				if not text == "<!-- NVN_EVAL: end -->" then goto continue end

				local file = io.open(path.full_path, "r")
				if not file then
					error(
						"File from directive could not be found: '"
							.. path.full_path
							.. "'"
					)
				end

				local end_row, _, _ = node:end_()
				local src = file:read("*a")

				local eval_func, parse_error = loadstring(src)
				if not eval_func then
					error("Parse error occured in block at: " .. parse_error)
				end

				local success, res_or_err = xpcall(eval_func, err.handler)
				if not success then
					error(
						"Runtime error during execution of code block"
							.. res_or_err
					)
				end

				-- If the result of the block is nil, don't replace lines
				if res_or_err then
					self:set_lines(
						begin_row + 1,
						end_row - 1,
						vim.fn.split(res_or_err, "\n")
					)
				end

				file:close()
				path = nil
			else
				-- Open directive
				local text = vim.treesitter.get_node_text(node, 0)
				if not text:sub(1, 13) == "<!-- NVN_EVAL" then goto continue end

				if text:sub(15, 17) == "end" then
					error("Unexpected end directive")
				end

				local path_text = text:sub(15, -6)
				path = Path.new_from_note(self, path_text)

				begin_row, _, _ = node:start()
			end

			::continue::
		end

		if path then error("A directive has not been closed") end
	end)
end

function Note:get_links() end

return Note

---@class Navigation
local Navigation = require("nvn.navigation")

---@class Path
local Path = require("nvn.path")

---@class Link
local Link = require("nvn.link")

local err = require("nvn.error")

local BLOCK_QUERY = [[
(fenced_code_block) @inside
]]

local EXTERNAL_QUERY = [[
(html_block) @block
]]

local LINK_QUERY = [[
(inline_link) @link
(shortcut_link) @shortcut
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

	local original_bufnr = vim.api.nvim_get_current_buf()
	local target_bufnr = vim.fn.bufnr(self.path.full_path, false)
	local buffer_exists = target_bufnr ~= -1

	if not buffer_exists then
		vim.cmd.edit(self.path.full_path)
		target_bufnr = vim.api.nvim_get_current_buf()
	end

	local status, err_or_value =
		xpcall(vim.api.nvim_buf_call, err.handler, target_bufnr, f)

	vim.cmd.buffer(original_bufnr)

	if not buffer_exists then
		vim.api.nvim_buf_delete(target_bufnr, {force = true})
	end

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
	local cwd = vim.fn.getcwd()
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

			vim.fn.chdir(vim.fs.dirname(self.path.full_path))
			local success, res_or_err = xpcall(eval_func, err.handler)
			vim.fn.chdir(cwd)
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

				vim.fn.chdir(vim.fs.dirname(self.path.full_path))
				local success, res_or_err = xpcall(eval_func, err.handler)
				vim.fn.chdir(cwd)
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

				local path_text = text:sub(15, -5)
				path = Path.new_from_note(self, path_text)

				begin_row, _, _ = node:start()
			end

			::continue::
		end

		if path then error("A directive has not been closed") end
	end)
end

---@param self Note
---@return Link[]
function Note:get_links()
	---@type Link[]
	local links = {}

	self:buf_call(function()
		local tree = vim.treesitter.get_parser(0, "markdown_inline"):parse()
		local root = tree[1]:root()
		local result =
			vim.treesitter.query.parse("markdown_inline", LINK_QUERY)
		local iter = result:iter_captures(root, 0)

		-- Collect the iterator
		local i = 1
		for _, node in iter do
			local success, link_or_err =
				xpcall(Link.new, err.handler, node)

			if not success then
				error("Construction of a link failed" .. link_or_err)
			end

			links[i] = link_or_err
			i = i + 1
		end
	end)

	return links
end

return Note

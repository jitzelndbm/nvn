---@class Navigation
local Navigation = require("nvn.navigation")

---@class Path
local Path = require("nvn.path")

---@class Link
local Link = require("nvn.link")

---@class Result
local Result = require("nvn.result")

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
---
---@class Note
---@field path Path
---@field navigation Navigation
local Note = {}
Note.__index = Note

---Constructor for the note class
---
---@param path Path
---@return Note
function Note.new(path)
	local self = setmetatable({}, Note)
	self.path = path
	self.navigation = Navigation.new(self)
	return self
end

---Call function on a buffer
---
---@generic T
---@param self Note
---@param f fun(): T the function that will be executed on the buffer
---@return T?
function Note:buf_call(f)
	local original_bufnr = vim.api.nvim_get_current_buf()
	local target_bufnr = vim.fn.bufnr(self.path.full_path, false)
	local buffer_exists = target_bufnr ~= -1

	if not buffer_exists then
		vim.cmd.edit(self.path.full_path)
		target_bufnr = vim.api.nvim_get_current_buf()
	end

	local value = vim.api.nvim_buf_call(target_bufnr, f)
	vim.cmd.buffer(original_bufnr)

	if not buffer_exists then
		vim.api.nvim_buf_delete(target_bufnr, { force = true })
	end

	return value
end

-- ---This function will overwrite the content of a note, replacing it with a template
-- ---@param template Template
-- ---@param force? boolean
-- function Note:write_template(template, force) force = force or false end

---Overwrites the entire note with new content
---
---@param force boolean
---@param ... string
---@return Result Nil
function Note:write(force, ...)
	if not self.path:exists() and not force then
		return Result.Err(
			"Note exists on file system, thus may contain content. To overwrite enable arg force."
		)
	end

	local file_res = Result.pcall(io.open, self.path.full_path, "w")
	if file_res:is_err() then return file_res end

	local file = file_res:unwrap() --[[@as file*]]

	-- Create an array from the args, then join them with new lines and write to the file
	file:write(vim.fn.join({ ... }, "\n"))

	file:close()

	return Result.Ok(nil)
end

---Replace lines between
---
---@param begin_line uinteger
---@param end_line uinteger
---@param lines string[]
function Note:set_lines(begin_line, end_line, lines)
	self:buf_call(function()
		vim.api.nvim_buf_set_lines(0, begin_line, end_line, false, lines)
		return nil
	end)
end

---Evaluate the note (i.e. execute all multiline code blocks and html comments)
---
---@return Result Nil
function Note:evaluate()
	local cwd = vim.fn.getcwd()

	return self:buf_call(function()
		-- First go over all code blocks
		local tree = vim.treesitter.get_parser(0, "markdown"):parse()[1]:root()
		local query = vim.treesitter.query.parse("markdown", BLOCK_QUERY)
		local iter = query:iter_captures(tree, 0)

		for _, node in iter do
			-- Check for right language specification
			local lang_node = node:child(1)
			if not lang_node then goto continue end
			local lang = vim.treesitter.get_node_text(lang_node, 0)
			if not (lang == "lua,eval" or lang == "lua, eval") then
				goto continue
			end

			-- Check if the source is in the right format
			local src_node = node:child(3)
			if not src_node then goto continue end
			local src = vim.treesitter.get_node_text(src_node, 0)
			-- NOTE: this means the inline source block is empty
			if src == "```" then goto continue end

			-- This function should return a string
			local eval_func, parse_error = loadstring(src)
			if not eval_func then return Result.Err(parse_error) end

			-- Execute the parsed function in the working dir of the note
			vim.fn.chdir(vim.fs.dirname(self.path.full_path))
			local res = Result.pcall(eval_func)
			vim.fn.chdir(cwd)

			if res:is_err() then return res end

			-- If the result of the block is nil, don't replace lines
			local end_row, _, _ = src_node:end_()
			if res:unwrap() ~= nil then
				self:set_lines(
					end_row + 1,
					end_row + 1,
					vim.fn.split(res:unwrap(), "\n")
				)
			end

			::continue::
		end

		-- Then go over comment lines, external sources
		query = vim.treesitter.query.parse("markdown", EXTERNAL_QUERY)
		iter = query:iter_captures(tree, 0)

		---@type Path?
		local path

		---@type uinteger
		local begin_row

		for _, node in iter do
			if path then
				if
					not vim.treesitter.get_node_text(node, 0)
					== "<!-- NVN_EVAL: end -->"
				then
					goto continue
				end

				local file = Result.pcall_err(
					io.open,
					"File from directive could not be found: '"
						.. path.full_path
						.. "'",
					path.full_path,
					"r"
				)
				if file:is_err() then return file end

				local src = (file:unwrap() --[[@as file*]]):read("*a") --[[@as string]]

				-- This function should return a string
				local eval_func, parse_error = loadstring(src)
				if not eval_func then return Result.Err(parse_error) end

				vim.fn.chdir(vim.fs.dirname(self.path.full_path))
				local res = Result.pcall(eval_func)
				vim.fn.chdir(cwd)

				if res:is_err() then return res end

				-- If the result of the block is nil, don't replace lines
				local end_row, _, _ = node:end_()
				if res:unwrap() ~= nil then
					self:set_lines(
						begin_row + 1,
						end_row - 1,
						vim.fn.split(res:unwrap(), "\n")
					)
				end

				(file:unwrap()--[[@as file*]]):close()

				path = nil
			else
				-- Open directive
				local text = vim.treesitter.get_node_text(node, 0)
				if not text:sub(1, 13) == "<!-- NVN_EVAL" then goto continue end

				if text:sub(15, 17) == "end" then
					return Result.Err("Unexpected end directive")
				end

				local path_text = text:sub(15, -5)
				path = Path.new_from_note(self, path_text)

				begin_row, _, _ = node:start()
			end

			::continue::
		end

		if path then return Result.Err("A directive has not been closed") end

		return Result.Ok(nil)
	end --[[@as fun(): Result]])
end

---@param self Note
---@return Result Link[]
function Note:get_links()
	return self:buf_call(function()
		---@type Link[]
		local links = {}

		local tree =
			vim.treesitter.get_parser(0, "markdown_inline"):parse()[1]:root()
		local query = vim.treesitter.query.parse("markdown_inline", LINK_QUERY)
		local iter = query:iter_captures(tree, 0)

		local i = 1
		for _, node in iter do
			local res = Link.new(node)
			if res:is_err() then return res end
			links[i] = res:unwrap()
			i = i + 1
		end

		return Result.Ok(links)
	end)
end

return Note

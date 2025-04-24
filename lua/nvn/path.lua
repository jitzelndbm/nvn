---@class Result
local Result = require("nvn.result")

--This class helps with paths
---@class Path
---@field full_path string
---@field rel_to_root string
local Path = {}
Path.__index = Path

---Returns an unchecked path.
---WARNING: this will not initialize rel_to_root since the function assumes the full_path is outside of the notes dir.
---
---@param full_path string
---@return Path
function Path.new_unsafe(full_path)
	local self = setmetatable({}, Path)
	self.full_path = full_path
	return self
end

---Returns a path relative to the provided client root
---
---@param root string
---@param relative_path string
---@return Path
function Path.new_from_rel_to_root(root, relative_path)
	local self = setmetatable({}, Path)

	self.rel_to_root = vim.fs.normalize(relative_path)
	self.full_path = vim.fs.normalize(vim.fs.joinpath(root, self.rel_to_root))

	return self
end

---Returns the relative path from note to other.
---Example: `Note("/a/test/"), "../README.md" -> "/a/README.md"`
---
---@param note Note
---@param other string
---@return Path
function Path.new_from_note(note, other)
	local self = setmetatable({}, Path)
	self.full_path = vim.fs.normalize(
		vim.fs.joinpath(vim.fs.dirname(note.path.full_path), other)
	)
	self.rel_to_root = vim.fs.normalize(
		vim.fs.joinpath(vim.fs.dirname(note.path.rel_to_root), other)
	)
	return self
end

-- FIXME: Maybe it's a better idea to use ... arg, and just zip those
-- parts together instead of assuming that a full path will be provided.

---Create a new path from a full path. Will error if the provided root cannot be
---extracted from the full_path.
---
---@param root string
---@param full_path string
---@return Result path
function Path.new_from_full(root, full_path)
	local self = setmetatable({}, Path)

	full_path = vim.fs.normalize(full_path)
	root = vim.fs.normalize(root)

	-- Remove trailing slashes
	if root:sub(-1) == "/" then root = root:sub(1, -2) end

	if not full_path:sub(1, #root) == root then
		return Result.Err("The root could not be extracted from the full_path")
	end

	self.full_path = full_path
	self.rel_to_root = full_path:sub(#root + 2)

	return Result.Ok(self)
end

---Returns true if a file exists under this path
---
---@param self Path
---@return boolean
function Path:exists() return vim.uv.fs_stat(self.full_path) ~= nil end

--function Path.rel_between(begin, end)
--end
--
--function Path:get_file_name()
--	return vim.fs.basename(self.full_path)
--end
--

return Path

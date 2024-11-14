---This class helps with working with paths
---@class Path
---@field full_path string
---@field rel_to_root string

local Path = {}
Path.__index = Path

--function Path.new_from_rel_to_root(root, relative_path)
--end

---Create a new path from a full_path
---@param root string
---@param full_path string
---@return Path?
function Path.new_from_full(root, full_path)
	local self = setmetatable({}, Path)

	full_path = vim.fs.normalize(full_path)
	root = vim.fs.normalize(root)

	-- Remove trailing slashes
	if root:sub(-1) == "/" then
        root = root:sub(1, -2)
    end

	if not full_path:sub(1, #root) == root then
		error("The root could not be extracted from the full_path")
	end

	self.full_path = full_path
	self.rel_to_root = full_path:sub(#root + 2)

	return self
end

--function Path.rel_between(begin, end)
--end
--
--function Path:get_file_name()
--	return vim.fs.basename(self.full_path)
--end
--

return Path

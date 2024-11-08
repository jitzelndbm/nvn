---@class Path
---@field full_path string

local Path = {}
Path.__index = Path

function Path.new_from_rel_to_root()
end

function Path.new_from_full()
end

function Path:get_file_name()
	return vim.fs.basename(self.full_path)
end

return Path

---This class represents a link in a markdown Note
---@class Link
---
---@field note Note
---
---@field title string
---@field url string
---@field shortcut boolean true means it's a [url], false means [title](url)
---
---@field row integer
---@field col integer
local Link = {}

function Link.new()
	local self = setmetatable({}, Link)
	return self
end

---@param client Client
function Link:follow(client)
end

return Link

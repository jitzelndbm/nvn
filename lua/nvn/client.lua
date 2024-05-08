require 'nvn.history'
require 'nvn.hierarchy'

Client = {}

function Client:new (config)
	local instance = setmetatable({}, self)
	self.__index = self

	instance.config = config or function ()
		vim.notify("client: config not found while creating client", vim.log.levels.ERROR)
		return nil
	end

	instance.history = History:new(config.root)
	instance.hierarchy = Hierarchy:new()

	instance:set_location(config.root)

	return instance
end

local function close_other_buffers(new_location, auto_save)
	for _, buf in pairs(vim.api.nvim_list_bufs()) do
		local buf_name = vim.api.nvim_buf_get_name(buf)

		-- Skip the scratch buffer and telescope
		if buf_name == "" or buf_name == "TelescopePrompt" or buf_name == "Prompt" then
			goto continue
		end

		if buf_name ~= new_location
			and vim.api.nvim_buf_is_loaded(buf) then
			if auto_save then
				vim.cmd.write(buf_name)
				vim.api.nvim_buf_delete(buf, {})
			else
				vim.api.nvim_buf_delete(buf, {
					force = true
				})
			end
		end

		::continue::
	end

end
function Client:set_location (new_location, ignore_history)
	close_other_buffers(new_location, self.config.behaviour.auto_save)

	self.location = new_location
	if not ignore_history then
		History.push(self.history, new_location)
	end
	vim.cmd.edit(new_location)
	vim.notify("client: location updated " .. self.location, vim.log.levels.DEBUG)
end

function Client:get_next_link(backwards)
	local parsed_links = {}
	local links = self:get_links_from_file()

	if not links then
		return
	end

	if backwards then
		for i = #links, 1, -1 do
			table.insert(parsed_links, links[i])
		end
	else
		parsed_links = links
	end

	local row, column = unpack(vim.api.nvim_win_get_cursor(0))
	for _, link in pairs(parsed_links) do
		if not backwards and ((row == link.row and column < link.column) or row < link.row) then
			return link
		elseif backwards and ((row == link.row and column > link.column) or row > link.row) then
			return link
		elseif next(links, _) == nil then
			return parsed_links[1]
		end
	end
end

local function find_links_in_current_buf()
	local language_tree = vim.treesitter.get_parser(0, "markdown_inline")
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()

	-- parse the query
	local parse_query = vim.treesitter.query.parse(
		"markdown_inline",
		[[
			(inline_link) @link
			(shortcut_link) @shortcut
			]]
	)
	local file_rows = vim.api.nvim_buf_line_count(0) or 0
	local iter = parse_query:iter_captures(root, 0, 0, file_rows)

	local file_name = vim.api.nvim_buf_get_name(0)

	local links = {}
	local i = 1
	for _, node in iter do
		links[i] = Link:new(node, file_name)
		i = i + 1
	end

	return links
end
function Client:get_links_from_file(full_path)
	local links
	local file_to_check

	if full_path then
		local found_files = vim.fs.find(
			function (name, path)
				return path.."/"..name ==
					vim.fs.dirname(self.config.root).."/"..full_path
			end,
			{
				type = "file",
				limit = 1,
			}
		)

		if #found_files ~= 1 then
			vim.notify("client: couldn't fetch files, since file does not exist. Or multiple found!", vim.log.levels.ERROR)
			return nil
		end

		file_to_check = found_files[1]
	end

	vim.api.nvim_buf_call(0, function ()
		if full_path then
			vim.cmd.edit(file_to_check)
		end

		links = find_links_in_current_buf()

		if full_path then
			vim.api.nvim_buf_delete(0, {})
		end
	end)

	return links
end

local function find_relative_path(from_path, to_path)
	local relative_path = ""
	local to_basename = vim.fs.basename(to_path)

	local from_parts = vim.fn.split(vim.fs.dirname(from_path), "/")
	local to_parts = vim.fn.split(vim.fs.dirname(to_path), "/")

	while from_parts[1] == to_parts[1] do
		table.remove(from_parts, 1)
		table.remove(to_parts, 1)
	end

	for _ = 1, #from_parts, 1 do
		relative_path = relative_path .. "../"
	end

	for _, part in pairs(to_parts) do
		relative_path = relative_path .. part .. "/"
	end

	return relative_path .. to_basename
end
function Client:create_note(path, previous_path, link_title)
	if not path:sub(1, 1) == "/" then
		path = self.config.root .. path
	end

	vim.fn.mkdir(vim.fs.dirname(path), "p")

	if self.config.templates.enabled then
		link_title = link_title or ""
		local relative_previous_path = ""
		if not previous_path then
			previous_path = ""
		else
			relative_previous_path = find_relative_path(path, previous_path)
		end

		local template = Template:new(self.config.root, self.config.templates.dir)
		if not template then
			vim.notify("An error occured in the template", vim.log.levels.ERROR)
			return
		end

		local title = vim.fs.basename(path)
			:gsub(".md$", "")
			:gsub("-", " ")
		:gsub("(%a)([%w_']*)", function (first, rest)
			return first:upper()..rest:lower()
		end)

		local file_content = template:render({
			path = path,
			title = title,
			previous_path = previous_path,
			link_title = link_title,
			relative_previous_path = relative_previous_path
		})

		-- write template output to the file
		vim.fn.writefile(vim.fn.split(file_content, "\n"), path)

		-- FIXME: Other way to write to files, not sure what is the best
		--vim.api.nvim_buf_call(0, function ()
		--	vim.cmd.edit(path)
		--	vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.split(file_content, "\n"))
		--	vim.cmd.write(path)
		--	vim.api.nvim_buf_delete(0, {})
		--end)
	end

	self:set_location(path)
end

function Client:remove_note(path)
	path = path or vim.api.nvim_buf_get_name(0)

	if path == self.config.root then
		vim.notify("You can't delete the root note", vim.log.levels.INFO)
		return
	end

	vim.ui.input(
		{ prompt = "Are you sure you want to remove ("..path..") this note? [Y/N]: " },
		function (input)
			if string.upper(input) == "Y" then
				self.history:pop()
				self:set_location(self.history:last(), true)
				os.remove(path)
			end
		end
	)
end

function Client:eval(path)
	if path then
		-- FIXME: normalize() doesn't work with ../ and ./ patterns yet
		-- This will be updated in v0.10
		path = vim.fs.dirname(self.config.root) .. "/" .. vim.fs.normalize(path)
	end

	vim.api.nvim_buf_call(0, function ()
		if path and vim.api.nvim_buf_get_name(0) ~= path then
			vim.cmd.edit(path)
		end

		local language_tree = vim.treesitter.get_parser(0, "markdown")
		local syntax_tree = language_tree:parse()
		local root = syntax_tree[1]:root()

		local code_block_query = vim.treesitter.query.parse(
			"markdown", [[(fenced_code_block) @id]]
		)

		local captured_code_blocks = code_block_query:iter_captures(root, 0)

		for _, code_block, _ in captured_code_blocks do
			local info_string = vim.treesitter.get_node_text(code_block:child(1), 0)
			if info_string ~= "lua, eval" and info_string ~= "lua,eval" then
				goto continue
			end

			local src_node = code_block:child(3)
			local _, _, end_row, _ = src_node:range()

			local src_text = vim.treesitter.get_node_text(src_node, 0)
			vim.api.nvim_buf_set_lines(0,
				end_row + 1, end_row + 1, false,
				vim.fn.split(loadstring(src_text)(), "\n"))

			::continue::
		end

		if path and vim.api.nvim_buf_get_name(0) ~= path then
			vim.cmd.write(path)
			vim.api.nvim_buf_delete(0, {})
		end
	end)
end

return Client

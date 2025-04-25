---@class Path
local Path = require("nvn.path")

---@class Note
local Note = require("nvn.note")

---@class Graph
local Graph = require("nvn.graph")

---@class Result
local Result = require("nvn.result")

---@class Option
local Option = require("nvn.option")

---@class Cli
---@field private client Client
---@field private commands table
local Cli = {}
Cli.__index = Cli

---@param client Client
---@return Cli
function Cli.new(client)
	local self = setmetatable({}, Cli)
	self.client = client
	return self
end

---Move the cursor to the next link in the current buffer, if there is no link nothing happens
---
---@return Result
function Cli:next_link()
	return self.client.current.navigation:next_link():map(function(link)
		vim.api.nvim_win_set_cursor(0, {
			(link --[[@as Link]]).row,
			(link --[[@as Link]]).col,
		})
	end)
end

---Move the cursor to the previous link in the buffer, if there is no link nothing happens
---
---@return Result
function Cli:previous_link()
	return self.client.current.navigation:previous_link():map(function(link)
		vim.api.nvim_win_set_cursor(0, {
			(link --[[@as Link]]).row,
			(link --[[@as Link]]).col,
		})
	end)
end

---Follows the link under the cursor if it is a link, otherwise this function presses <CR>
---
---@return Result
function Cli:follow_link()
	local found = self.client.current.navigation
		:current_link()
		:or_else(function()
			vim.cmd('execute "normal! \\<CR>"')
			return Result.Ok(nil) -- Return dummy ok to ignore error handling
		end)
		:and_then(function(link)
			return (link --[[@as Link]]):follow(self.client)
		end)

	return found
end

---A function to create a note relative to the current note
---
---@return Result
function Cli:create_note()
	local input = vim.fn.input("Filename (relative to current open note): ")
	local file_name = input == "" and Option.None() or Option.Some(input)
	if file_name:is_none() then
		return Result.Err("File name cannot be empty")
	end

	local new_note =
		Note.new(Path.new_from_note(self.client.current, file_name:unwrap()))

	local res = self.client:add(new_note)
	if res:is_ok() then self.client:set_location(new_note) end
	return res
end

---Go to the previously visited note
---
---@return Result
function Cli:goto_previous()
	local last = self.client.history:last()
	self.client.history:pop()
	self.client:set_location(last)
	return Result.Ok()
end

--function Cli:delete_note()
--end

---Evaluatate the current note
---
---@return Result
function Cli:evaluate() return self.client.current:evaluate() end

---Construct and open a graph representation of the notes in the browser
---
---@return Result
function Cli:open_graph()
	local gr = Graph.new()
	if gr:is_err() then return gr end
	local g = gr:unwrap() --[[@as Graph]]

	local cr = g:construct(self.client)
	if cr:is_err() then return cr end
	local opr = g:open()
	if opr:is_err() then return opr end

	return Result.Ok()
end

---Registers all commands as nvim user commands
function Cli:register_commands()
	---@type [string, fun(self: Cli): Result][]
	local cmds = {
		{ "NvnPreviousLink", self.previous_link },
		{ "NvnNextLink", self.next_link },
		{ "NvnFollowLink", self.follow_link },
		{ "NvnEval", self.evaluate },
		{ "NvnCreateNote", self.create_note },
		{ "NvnGotoPrevious", self.goto_previous },
		{ "NvnOpenGraph", self.open_graph },
	}

	for _, cmd in ipairs(cmds) do
		vim.api.nvim_create_user_command(cmd[1], function()
			-- Unwrap the result, thus reporting the error
			cmd[2](self):unwrap()
		end, {})
	end
end

return Cli

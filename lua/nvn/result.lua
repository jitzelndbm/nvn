---@class Result
---@field private _is_ok boolean
---@field private _value any
local Result = {}
Result.__index = Result

---Constructor for the Ok variant of Result
---
---@nodiscard
---@param value any
---@return Result
Result.Ok = function(value)
	local self = setmetatable({}, Result)
	self._is_ok = true
	self._value = value
	return self
end

---Constructor for the Err variant of Result
---
---@nodiscard
---@param error any
---@return Result
Result.Err = function(error)
	local self = setmetatable({}, Result)
	self._is_ok = false
	self._value = error
	return self
end

-- ---Constructor that outputs an error type if the value is nil
-- ---
-- ---@nodiscard
-- ---@param value any | nil
-- ---@return Result
-- Result.Option = function(value)
-- 	local self = setmetatable({}, Result)
-- 	if value then
-- 		self._is_ok = true
-- 	else
-- 		self._is_ok = false
-- 	end
-- 	self._value = value
-- 	return self
-- end

---Wraps pcall with proper error handling and overload signatures
---
---@nodiscard
---@param fn function
---@param err any
---@param ... unknown
---@return Result
function Result.pcall_err(fn, err, ...)
	local ok, value = pcall(fn, ...)
	if ok then
		return Result.Ok(value)
	else
		return Result.Err(err)
	end
end

---Wraps pcall with proper error handling and overload signatures
---
---@nodiscard
---@param fn function
---@param ... unknown
---@return Result
function Result.pcall(fn, ...)
	local ok, value = pcall(fn, ...)
	if ok then
		return Result.Ok(value)
	else
		return Result.Err(value)
	end
end

---Returns true if the result is Ok.
---
---@return boolean
function Result:is_ok() return self._is_ok end

---Returns true if the result is Ok and the value inside of it matches a predicate.
---
---@param f fun(x: any): boolean
---@return boolean
function Result:is_ok_and(f)
	-- Pass self._value into f, it is guaranteed that this is the Ok variant
	return self:is_ok() and f(self._value)
end

--- Returns true if the result is Err
---
--- @return boolean
function Result:is_err() return not self._is_ok end

---Returns true if the result is Err and the value inside of it matches a predicate.
---
---@param f fun(x: any): boolean
---@return boolean
function Result:is_err_and(f) return self:is_err() and f(self._value) end

---Transforms Result<T,E> into Option<T>
---
---@return Option
function Result:ok()
	---@class Option
	local Option = require("nvn.option")

	if self:is_ok() then
		return Option.Some(self._value)
	else
		return Option.None()
	end
end

---Transforms Result<T,E> into Option<E>
---
---@return Option
function Result:err()
	---@class Option
	local Option = require("nvn.option")

	if self:is_err() then
		return Option.Some(self._value)
	else
		return Option.None()
	end
end

---Maps a Result<T, E> to Result<U, E> by applying a function to a contained Ok value, leaving an Err value untouched.
---
---@nodiscard
---@param op fun(x: any): any
---@return Result
function Result:map(op)
	if self:is_ok() then
		return Result.Ok(op(self._value))
	else
		return self
	end
end

--- Returns the provided default (if Err), or applies a function to the contained value (if Ok).
---
---@param default any
---@param f fun(ok: any): any
---@return any
function Result:map_or(default, f)
	if self:is_ok() then
		return f(self._value)
	else
		return default
	end
end

--- Maps a Result<T, E> to U by applying fallback function default to a contained Err value, or function f to a contained Ok value.
---
---@param default fun(err: any): any
---@param f fun(ok: any): any
---@return any
function Result:map_or_else(default, f)
	if self:is_ok() then
		return f(self._value)
	else
		return default(self._value)
	end
end

--- Maps a Result<T, E> to Result<T, F> by applying a function to a contained Err value, leaving an Ok value untouched.
---
---@nodiscard
---@param op fun(err: any): any
---@return Result
function Result:map_err(op)
	if self:is_ok() then
		return self
	else
		return Result.Err(op(self._value))
	end
end

---Returns the contained Ok value, consuming the self value. Panics if the value is an Err, with a panic message including the passed message, and the content of the Err.
---
---@nodiscard
---@param msg string
---@return any
function Result:expect(msg)
	if self:is_ok() then
		return self._value
	else
		error(msg .. ": " .. self._value)
	end
end

---Returns the contained Ok value, consuming the self value. Panics if the value is an Err, with a panic message provided by the Err’s value.
---
---@return any
function Result:unwrap()
	if self:is_ok() then
		return self._value
	else
		error(self._value)
	end
end

-- ---Returns the contained Ok value or a default
-- ---
-- ---@param default any
-- ---@return any
-- function Result:unwrap_or_default(default)
-- 	if self:is_ok() then
-- 		return self._value
-- 	else
-- 		return default
-- 	end
-- end

-- TODO: expect_err
-- TODO: unwrap_err

---Returns res if the result is Ok, otherwise returns the Err value of self.
---
---@nodiscard
---@param res Result
---@return Result
function Result:and_(res)
	if self:is_ok() then
		return res
	else
		return self
	end
end

---Calls op if the result is Ok, otherwise returns the Err value of self.
---
---@nodiscard
---@param op fun(ok: any): Result
---@return Result
function Result:and_then(op)
	if self:is_ok() then
		return op(self._value)
	else
		return self
	end
end

---Returns res if the result is Err, otherwise returns the Ok value of self.
---
---@nodiscard
---@param res Result
---@return Result
function Result:or_(res)
	if self:is_ok() then
		return self
	else
		return res
	end
end

---Calls op if the result is Err, otherwise returns the Ok value of self.
---
---@nodiscard
---@param op fun(err: any): Result
---@return Result
function Result:or_else(op)
	if self:is_ok() then
		return self
	else
		return op(self._value)
	end
end

---Returns the contained Ok value or a provided default.
---
---@param default any
---@return any
function Result:unwrap_or(default)
	if self:is_ok() then
		return self._value
	else
		return default
	end
end

---Returns the contained Ok value or computes it from a closure.
---
---@param op fun(err: any): any
---@return any
function Result:unwrap_or_else(op)
	if self:is_ok() then
		return self._value
	else
		return op(self._value)
	end
end

return Result

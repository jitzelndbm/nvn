---@class Option
---@field private _value any | nil
local Option = {}
Option.__index = Option

---Returns an instance of the some variant of the option type.
---
---@nodiscard
---@param value any
---@return Option
Option.Some = function(value)
	local self = setmetatable({}, Option)
	self._value = value
	return self
end

---Create a None variant of the Option class.
---
---@nodiscard
---@return Option
Option.None = function()
	local self = setmetatable({}, Option)
	self._value = nil
	return self
end

---If the function returns an error, this method will output the None variant
---
---@nodiscard
---@param fn function
---@param ... unknown
---@return Option
Option.pcall = function(fn, ...)
	local ok, value = pcall(fn, ...)
	if ok then
		return Option.Some(value)
	else
		return Option.None()
	end
end

---Returns None if the option is None, otherwise returns optb.
---
---@param optb any
---@return any
function Option:and_(optb)
	if self:is_some() then
		return optb
	else
		return Option.None()
	end
end

---Returns None if the option is None, otherwise calls f with the wrapped value and returns the result.
---
---@nodiscard
---@param f function
---@return Option
function Option:and_then(f)
	if self:is_some() then
		return Option.Some(f(self._value))
	else
		return Option.None()
	end
end

---Returns the contained Some value, consuming the self value. Errors if the value is not present.
---
---@param msg string
---@return any
function Option:expect(msg)
	if self:is_some() then
		return self._value
	else
		error(msg, 2)
	end
end

---Returns none if the option is none, otherwise call p, if that returns true ten return some variant, else none.
---
---@nodiscard
---@param p any
---@return Option
function Option:filter(p)
	if self:is_some() and p(self._value) then
		return self
	else
		return Option.None()
	end
end

---Converts from Option<Option<T>> to Option<T>.
---
---@nodiscard
---@return Option
function Option:flatten()
	if self:is_some() then
		return self
	else
		return Option.None()
	end
end

---Mutate the value inside of the option
---
---@generic T
---@param value T
---@return T
function Option:insert(value)
	self._value = value
	return value
end

---Calls a function with a reference to the contained value if Some.
---
---@nodiscard
---@param f any
---@return Option
function Option:inspect(f)
	if self:is_some() then f(self._value) end

	return self
end

---Returns true if the option is not a value.
---
---@return boolean
function Option:is_none() return not self:is_some() end

---Returns true  fi the option is not a value or the inside matches the predicate.
---
---@param f fun(x: any): boolean
---@return boolean
function Option:is_none_or(f) return self:is_none() or f(self._value) end

---Returns true if the option is a value.
---
---@return boolean
function Option:is_some() return self._value ~= nil end

---Returns true if the option is a value and the inside matches the predicate.
---
---@param f fun(x: any): boolean
---@return boolean
function Option:is_some_and(f) return self:is_some() and f(self._value) end

---Maps an Option<T> to Option<U> by applying a function to a contained value (if Some) or returns None (if None).
---
---@nodiscard
---@param f fun(x: any): any
---@return Option
function Option:map(f)
	if self:is_some() then
		return Option.Some(f(self._value))
	else
		return Option.None()
	end
end

---Returns the provided default result (if none), or applies a function to the contained value (if any).
---
---@param default any
---@param f fun(x: any): any
---@return any
function Option:map_or(default, f)
	if self:is_some() then
		return f(self._value)
	else
		return default
	end
end

---Transforms the Option<T> into a Result<T, E>, mapping Some(v) to Ok(v) and None to Err(err).
---
---@nodiscard
---@generic E
---@param err E
---@return Result
function Option:ok_or(err)
	---@class Result
	local Result = require("nvn.result")

	if self:is_some() then
		return Result.Ok(self._value)
	else
		return Result.Err(err)
	end
end

---Transforms the Option<T> into a Result<T, E>, mapping Some(v) to Ok(v) and None to Err(err()).
---
---@nodiscard
---@generic E
---@param errf fun(): E
---@return Result
function Option:ok_or_else(errf)
	---@class Result
	local Result = require("nvn.result")

	if self:is_some() then
		return Result.Ok(self._value)
	else
		return Result.Err(errf())
	end
end

---Returns the option if it contains a value, otherwise returns optb.
---
---@nodiscard
---@param optb Option
---@return Option
function Option:or_(optb)
	if self:is_some() then
		return self
	else
		return optb
	end
end

---Returns the option if it contains a value, otherwise calls f and returns the result.
---
---@nodiscard
---@param f fun(): Option
---@return Option
function Option:or_else(f)
	if self:is_some() then
		return self
	else
		-- Could be None as well, but will be automatically converted
		return Option.Some(f())
	end
end

---Replaces the actual value in the option by the value given in parameter, returning the old value if present, leaving a Some in its place without deinitializing either one.
---
---@nodiscard
---@param value any
---@return Option
function Option:replace(value)
	self._value = value
	return self
end

---Returns the contained Some value, consuming the self value.
---
---@return any
function Option:unwrap()
	if self:is_some() then
		return self._value
	else
		error(self._value, 2)
	end
end

---Returns the contained Some value or a provided default.
---
---@param default any
---@return any
function Option:unwrap_or(default)
	if self:is_some() then
		return self._value
	else
		return default
	end
end

---Returns the contained Some value or computes it from a closure.
---
---@param f fun(): any
---@return any
function Option:unwrap_or_else(f)
	if self:is_some() then
		return self._value
	else
		return f()
	end
end

return Option

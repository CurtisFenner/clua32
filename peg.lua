local peg = {}

local add, pow, mul
local index = {}

local function parser(fun)
	return setmetatable({_fun = fun}, {
		__add = add,
		__pow = pow,
		__mul = mul,
		__index = index,
	})
end

function index.parse(p, stream)
	assert(type(stream) == "table")
	if stream:size() == 0 then
		if p._eof then
			return true, stream
		end
		return nil
	elseif p._eof then
		return nil
	end
	return p._fun(stream)
end

-- make a parser optional (returns `false`)
function index.optional(p)
	return parser(function(text)
		local obj, rest = p:parse(text)
		if obj == nil then
			return false, text
		end
		return obj, rest
	end)
end

-- the parser is required (an error is raised upon failure to parse)
function index.required(self, message)
	local q = self + parser(function(text)
		error(message .. "\nnear " .. text:location())
	end)
	q._eof = self._eof
	return q
end

-- map( P[A], A->B ) --> P[B}
function index.map(p, fun)
	return parser(function(stream)
		local a, rest = p:parse(stream)
		if a ~= nil then
			return fun(a), rest
		end
	end)
end

-- ordered choice
-- add(P[A], P[B]) --> P[A|B]
function add(left, right)
	assert(left and right)
	return parser(function(stream)
		local a, rest = left:parse(stream)
		if a ~= nil then
			return a, rest
		else
			return right:parse(stream)
		end
	end)
end

-- sequence
-- mul( P[A], P[B] ) --> P[ {A,B} ]
function mul(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		error("mul(" .. tostring(left) .. ", " .. tostring(right) .. ")", 2)
	end
	return parser(function(stream)
		local a, rest = left:parse(stream)
		if a == nil then
			return nil
		else
			local b, rest = right:parse(rest)
			if b == nil then
				return nil
			end
			return {a, b}, rest
		end
	end)
end

-- at least (greedy)
function pow(p, n)
	assert(type(p) == "table")
	assert(type(n) == "number" and n == math.floor(n))
	-- matches at least n occurrences
	if n >= 0 then
		return parser(function(stream)
			assert(type(stream) == "table")
			local matches = {}
			repeat
				local match, rest = p:parse(stream)
				if match ~= nil then
					table.insert(matches, match)
					stream = rest
				end
			until match == nil
			if #matches >= n then
				return matches, stream
			end
		end)
	end
	error("negative pow not implemented")
end

function peg.literal(str)
	return parser(function(stream)
		if stream[1] == str then
			return str, stream:next(1)
		end
	end)
end

function peg.pattern(f)
	return parser(function(stream)
		local r = f(stream[1])
		if r ~= nil then
			return r, stream:next(1)
		end
	end)
end

peg.eof = parser(function() error("should not be called") end)
peg.eof._eof = true

peg.fail = parser(function() return nil end)

function peg.pointer()
	local p = parser(function()
		error("this pointer parser has not been pointed", 2)
	end)
	p._pointed = false
	p.point = function(self, other)
		assert(not self._pointed, "this pointer has already been pointed")
		self._pointed = true
		self._fun = other._fun
	end
	return p
end

-- TESTS -----------------------------------------------------------------------
local Stream = require("./stream")
-- Test ^
local text = Stream{"a", "a", "a", "a", "b"}
local p = peg.literal("a")^0
local four, rest = p:parse(text)
assert(#four == 4, "four is `" .. table.concat(four, ", ") .. "`")
assert(four[1] == "a" and four[4] == "a")
assert(rest)
assert(rest:size() == 1)
assert(rest[1] == "b")

-- Test optional with ^0
local text = Stream{"a", "a", "a"}:next(1)
local p = peg.literal("b") ^0
local zero, rest = p:parse(text)
assert(type(zero) == "table" and #zero == 0)
assert(rest:size() == 2)

-- Test *
local text = Stream{"a", "b"}
local p = peg.literal("a") * peg.literal("b")
local two, rest = p:parse(text)
assert(type(two) == "table", type(two))
assert(#two == 2, "two is `" .. table.concat(two, ", ") .. "`")
assert(two[1] == "a" and two[2] == "b")

-- Test eof
local text = Stream{"a", "a", "a"}
local p = peg.literal("a") ^ 0 * peg.eof
local three, eof = p:parse(text)
assert(type(three) == "table")
assert(type(three[1]) == "table" and #three[1] == 3)
assert(three[2] == true)
assert(eof:size() == 0)
--------------------------------------------------------------------------------

return peg

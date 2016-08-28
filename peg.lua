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
		return p._eof
	end
	return p._fun(stream)
end

-- map( P[A], A->B ) --> P[B}
function index.map(p, fun)
	return parser(function(stream)
		local a, rest = p:parse(stream)
		if a then
			return fun(a), rest
		end
	end)
end

-- ordered choice
-- add(P[A], P[B]) --> P[A|B]
function add(left, right)
	return parser(function(stream)
		local a, rest = left:parse(stream)
		if a then
			return a, rest
		else
			return right:parse(stream)
		end
	end)
end

-- sequence
-- mul( P[A], P[B] ) --> P[ {A,B} ]
function mul(left, right)
	return parser(function(stream)
		local a, rest = left:parse(stream)
		if not a then
			return nil
		else
			local b, rest = right:parse(rest)
			if b then
				return {a, b}, rest
			end
		end
	end)
end

-- at least (greedy)
function pow(p, n)
	assert(type(p) == "table")
	assert(type(n) == "number")
	-- matches at least n occurrences
	if n >= 0 then
		return parser(function(stream)
			assert(type(stream) == "table")
			local matches = {}
			repeat
				local match, rest = p:parse(stream)
				if match then
					table.insert(matches, match)
					stream = rest
				end
			until not match
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
		if r then
			return r, stream:next(1)
		end
	end)
end

function peg.eof()
	local p = parser(function() return false end)
	p._eof = true
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
-- Test *
local text = Stream{"a", "b"}
local p = peg.literal("a") * peg.literal("b")
local two, rest = p:parse(text)
assert(type(two) == "table")
assert(#two == 2, "two is `" .. table.concat(two, ", ") .. "`")
assert(two[1] == "a" and two[2] == "b")

--------------------------------------------------------------------------------

return peg

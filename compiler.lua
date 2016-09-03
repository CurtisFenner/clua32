local peg = require("./peg")
local Stream = require("./stream")
local grammar = require("./cgrammar")

local operators = {
	"{", "}", ";",
	",", "(", ")", "[", "]", ".", "->",
	"--", "++", "+=", "-=", "/=", "%=", "*=", "!=", "&=", "^=", "!=",
	"+", "-", "/", "%", "*", "!", "&", "^", "!",
	"<<=", ">>=",
	"&&", "||", "<<", ">>", "~",
	"=", "==", "<=", ">=", "<", ">",
	"?", ":",
}
table.sort(operators, function(a, b) return #a > #b end)

-- Splits a string into many tokens
function splitTokens(contents)
	local function parseWord(s)
		if #s == 1 then
			return peg.literal(s)
		end
		local c = s:explode()
		local t = peg.literal(c[1])
		for i = 2, #c do
			t = t * peg.literal(c[i])
		end
		return t:map(function(x) return table.concat(x) end)
	end

	-- digit glob letter, letter glob letter, digit glob digit
	local letter = peg.pattern(function(x) return x:match("[a-zA-Z_]") end)
	local digit = peg.pattern(function(x) return x:match("[0-9]") end)
	local name = ((letter + digit) ^ 1):map(function(t) return table.concat(t) end)
	local operator = parseWord(operators[1])
	for i = 2, #operators do
		operator = operator + parseWord(operators[i])
	end
	local tokens = {}
	for word in contents:gmatch("%S+") do
		local s = Stream(word:explode())
		local whole = (operator + name)^1
		local seq, rest = whole:parse(s)
		if not seq then
			error("invalid token near `" .. word .. "`")
		end
		if rest:size() ~= 0 then
			error("invalid token near `" .. rest[1] .. "`")
		end
		for _, t in ipairs(seq) do
			table.insert(tokens, t)
		end
	end
	return tokens
end

function compile(contents)
	local tokens = splitTokens(contents)
	local program, rest = grammar.program:parse(Stream(tokens))
	print(program, rest)
	print(">>>", program.definitions)
end

return compile

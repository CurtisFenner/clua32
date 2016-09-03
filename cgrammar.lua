local peg = require("./peg")

local _1 = function(t) return t[1] end
local _2 = function(t) return t[2] end

function composite(def)
	assert(#def >= 2)
	assert(type(def[1]) == "table")
	assert(type(def[1][1]) == "string")
	assert(type(def[1][2]) == "table")
	local x = def[1][2]
	for i = 2, #def do
		assert(#def[i] == 2)
		local t = def[i][2]
		x = x * t
	end
	return x:map(function(p)
		local o = {}
		for i = #def, 2, -1 do
			local key = def[i][1]
			o[key] = p[2]
			p = p[1]
		end
		o[def[1][1]] = p
		for key, value in pairs(def) do
			if type(key) == "string" then
				o[key] = value
			end
		end
		return o
	end)
end

--------------------------------------------------------------------------------

local name = peg.pattern(function(n) return n:sub(1, 1):match("[a-zA-Z_]") end)

local integer = peg.pattern(function(n) return n:match("%d+") == n end)

local ctype = peg.literal("int") + peg.literal("char") + (peg.literal("struct") * name)

local typedName = (ctype * name):map(function(x) return {type = x[1], name = x[2]} end)

local numberLiteral = integer

-- Expressions
local binaryOperators = {
	",", ".", "->",
	"--", "++", "+=", "-=", "/=", "%=", "*=", "!=", "&=", "^=", "!=",
	"+", "-", "/", "%", "*", "&", "^",
	"<<=", ">>=",
	"&&", "||", "<<", ">>",
	"=", "==", "<=", ">=", "<", ">",
}
local unaryOperators = {
	"~", "!", "-", "&", "*",
}
local ternaryOperators = {
	{"?", ":"},
}

local infixOperator = peg.fail
for _, op in pairs(binaryOperators) do
	infixOperator = infixOperator + peg.literal(op)
end
for _, op in pairs(ternaryOperators) do
	infixOperator = infixOperator + peg.literal(op)
end

local prefixOperator = peg.fail
for _, op in pairs(unaryOperators) do
	prefixOperator = prefixOperator + peg.literal(op)
end

local expression = peg.pointer()

local parenedExpression = composite{
	{"", peg.literal"("},
	{"body", expression:required("")},
	{"", peg.literal")"},
}:map(function(obj) return obj.body end)

local expressionAtom = parenedExpression + name + numberLiteral

local subscript = composite{
	type = "subscript",
	{"", peg.literal "["},
	{"index", expression:required "expected expression after `[`"},
	{"", peg.literal "]" :required "expected `]` after subscript"},
}

local functionCall = composite{
	type = "function",
	{"", peg.literal "("},
	-- XXX: comma is an operator.
	{"arguments", expression:optional()},
	{"", peg.literal ")" :required "expected `)` to finish function arguments"},
}

local postFixes = subscript + functionCall

local expressionBlob = composite{
	{"prefix", prefixOperator^0},
	{"expression", expressionAtom},
	{"postfix", postFixes^0},
}

expression:point(composite{
	{"first", expressionBlob},
	{"rest", (infixOperator * expressionBlob:required "expected expression after operator")^0},
})

-- Statements
local statement = peg.pointer()

local returnStatement = composite{
	type = "return",
	{"", peg.literal "return"},
	{"expression", expression:optional()},
	{"", peg.literal ";" :required "expected `;` to finish return statement"},
}

local block = composite{
	type = "block",
	{"", peg.literal"{"},
	{"body", statement^0},
	{"", peg.literal"}":required "expected a `}` to close block"},
}

local ifStatement = composite{
	type = "if",
	{"", peg.literal "if"},
	{"", peg.literal "(" :required "expected `(` after `if`"},
	{"condition", expression:required "expected condition after `(` in if-statement"},
	{"", peg.literal ")" :required "expected `)` after condition in if-statement"},
	{"body", block},
}

statement:point(block + returnStatement + ifStatement)

-- Definitions
local parameters = composite{
	{"first", typedName},
	{"rest", (peg.literal"," * typedName):map(_2)^0},
}:map(function(obj)
	local out = {unpack(obj.rest)}
	table.insert(out, 1, obj.first)
	return out
end)

local functionDefinition = composite{
	type = "function",
	{"returns", ctype},
	{"name", name},
	{"", peg.literal"("},
	{"parameters", parameters:optional()},
	{"", peg.literal")":required "expected `)` after function parameters"},
	{"body", block:required "expected function body after `)`"},
}

local definition = functionDefinition

local program = composite{
	type = "program",
	{"definitions", definition ^ 0},
	{"", peg.eof:required("expected definition or end of file")},
}

--------------------------------------------------------------------------------

local c = composite{
	type = "abc",
	{"a", peg.literal "a"},
	{"b", peg.literal "b"},
	{"c", peg.literal "c"},
}

local p = composite{
	type = "p",
	{"cs", c^0},
	{"end", peg.eof:required("foo")},
}

local text = Stream{"a", "b", "c", "a", "b", "c"}

local before, rest = p:parse(text)
assert(type(before) == "table")

--------------------------------------------------------------------------------

return {
	program = program,
}

local trigraphs = {
	["??="] = "#",
	["??("] = "[",
	["??/"] = "\\",
	["??)"] = "]",
	["??'"] = "^",
	["??<"] = "{",
	["??!"] = "|",
	["??>"] = "}",
	["??-"] = "~",
}

function stripComments(src)
	src = src .. "\n"
	local stopComment = nil
	local out = ""
	-- XXX: this does not handle quotes correctly.
	while #src > 0 do
		local text1, comment1, rest1 = src:match("^(.-)//(.-)\n(.*)$")
		local text2, comment2, rest2 = src:match("^(.-)/*(.-)*/(.*)$")
		if text1 and text2 then
			if #text1 < #text2 then
				out = out .. text1 .. " "
				src = rest1
			else
				out = out .. text2 .. " "
				src = rest2
			end
		elseif text1 then
			out = out .. text1 .. " "
			src = rest1
		elseif text2 then
			out = out .. text2 .. " "
			src = rest2
		else
			out = out .. src
			return out
		end
	end
	return out
end

function preprocess(source)
	for trigraph, character in pairs(trigraphs) do
		source = source:gsub(trigraph:gsub(".", "%%%0"), character)
	end
	return stripComments(source)
end

local fileName = arg[1]
if not fileName then
	return print("usage:\n\tlua cpp.lua <file.c>")
end
local file = io.open(fileName)
if not file then
	return print("no such file `" .. fileName .. "`")
end

local data = file:read("*all")
print(preprocess(data))

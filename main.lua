require("./extend")

local compiler = require("./compiler")

-- Front End -------------------------------------------------------------------
local fileName = arg[1]
if not fileName then
	return print("usage:\n\tlua main.lua <file.c>")
end
local file = io.open(fileName)
if not file then
	return print("no such file `" .. fileName .. "`")
end

local data = file:read("*all")
print(compiler(data))
--------------------------------------------------------------------------------

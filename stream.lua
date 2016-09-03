function Stream(list, off)
	off = off or 0
	return setmetatable({
		next = function(self, advance)
			assert(type(advance) == "number")
			return Stream(list, off + advance)
		end,
		size = function(self)
			return #list - off
		end,
		location = function(self)
			if self:size() == 0 then
				return "<eof>"
			end
			local out = {}
			for i = 1, self:size() do
				table.insert(out, self[i])
			end
			local str = table.concat(out, " ")
			if #str > 20 then
				str = str:sub(1, 20) .. "..."
			end
			return "`" .. str .. "`" .. " on line ???"
		end,
	}, {
		__index = function(self, key)
			return list[key + off]
		end,
		__tostring = function(self)
			local list = {}
			for i = 1, self:size() do
				list[i] = self[i]
			end
			return "Stream{\"" .. table.concat(list, '", "') .. '"}'
		end,
	})
end

-- TESTS -----------------------------------------------------------------------
local a = Stream({"a", "b", "c"})
assert(a:size() == 3)
assert(a[1] == "a" and a[2] == "b" and a[3] == "c" and a[4] == nil)

local b = a:next(1)
assert(b:size() == 2)
assert(b[1] == "b" and b[2] == "c" and b[3] == nil)

--------------------------------------------------------------------------------

return Stream

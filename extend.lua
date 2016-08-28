function table.find(tab, pattern)
	for key, value in pairs(tab) do
		if pattern == value then
			return key
		end
	end
end

function table.mapped(tab, f)
	local out = {}
	for key, value in pairs(tab) do
		out[key] = f(value)
	end
	return out
end

function string.explode(str)
	local out = {}
	for i = 1, #str do
		out[i] = str:sub(i, i)
	end
	return out
end

local Encoder = require("./Encoder")
local Decoder = require("./Decoder")



-- make sample data

local strings = {}
for i = 97, 97 + 25 do
	table.insert(strings, string.char(i))
end

local tab = {}
for i = 1, 1000 do
	local sub = {}
	for j = 1, 10 do
		local index = strings[(i + j)%26 + 1]
		local value = i + j + 1
		sub[index] = value
	end
	table.insert(tab, sub)
end



-- encode/decode sample data

local t0 = os.clock()

local encoder = Encoder.new()
encoder:encode(tab)
local dataString = encoder:dumpToString64()

local t1 = os.clock()

local decoder = Decoder.fromString64(dataString)
local dup = decoder:decode()

local t2 = os.clock()


print(t1 - t0)
print(t2 - t1)

print(tab[1], dup[1])
print(tab[2], dup[2])
print(tab[3], dup[3])
local EncoderFuncs = require("./EncoderFuncs")

local Decoder = {}
Decoder.__index = Decoder

--local print = function() end

function Decoder.new(buff)
	local self = setmetatable({}, Decoder)

	self._buff = buff
	self._head = 0
	
	self._tableDecoded = {}

	assert(self:readFib() == 1, "version incompatible") -- version

	return self
end

-- 201.9 lbs this morning

-- 2 grande americanos (15x2 calories)
-- chipotle double chicken with sourcream (900 calories)

function Decoder:decode()
	if self._decoded then
		return self._value
	end

	self._decoded = true
	--self._version = self:readFib()
	print("reading type tree")
	self._typeTree = self:_decodeTypeTree()
	print("reading value tree")
	self._valueTree = self:_decodeValueTree()
	print("reading value")
	self._value = self:_decodeValue()

	return self._value
end





function Decoder:_decodeTypeTree()
	local node = {}
	local isLeaf = self:read(1) == 1
	if isLeaf then
		print("reading type string")
		local len = self:readFib()
		print("len", len)
		node.value = self:readString(len)
		print("value", node.value)
	else
		node.node0 = self:_decodeTypeTree()
		node.node1 = self:_decodeTypeTree()
	end
	return node
end

function Decoder:_decodeValueTree(code)
	code = code or ""
	local node = {}
	local isLeaf = self:read(1) == 1
	if isLeaf then
		local type = self:readCode(self._typeTree).value
		node.type = type
		if type == "_type" then -- this is a special case
			node.value = self:readCode(self._typeTree).value
		elseif type == "table" then
			node.value = {} -- just initialize a table for reference purposes
		else
			node.value = EncoderFuncs.decode(self, type)
		end
		print("value tree", code, type, node.value)
	else
		node.node0 = self:_decodeValueTree(code .. "0")
		node.node1 = self:_decodeValueTree(code .. "1")
	end
	return node
end

function Decoder:_decodeValue()
	local node = self:readCode(self._valueTree)
	if node.type == "_type" then -- decode a literal
		print("reading literal", node.value)
		if node.value == "table" then
			return self:_decodeTable({})
		else
			return EncoderFuncs.decode(self, node.value)
		end
	elseif node.type == "table" then -- decode a table
		print("reading table", node.value)
		return self:_decodeTable(node.value)
	else -- just return the reference
		print("reading reference", node.value)
		return node.value
	end
end

function Decoder:_decodeTable(tab)
	if self._tableDecoded[tab] then
		return tab
	end

	self._tableDecoded[tab] = true

	print("reading listCount")
	local listCount = self:readFib() - 1
	print("reading hashCount")
	local hashCount = self:readFib() - 1
	print("read values", listCount, hashCount)

	for i = 1, listCount do
		print("reading list value", i)
		local value = self:_decodeValue()
		tab[i] = value
	end

	for i = 1, hashCount do
		print("reading index value pair", i)
		local index = self:_decodeValue()
		local value = self:_decodeValue()
		tab[index] = value
	end

	return tab
end






function Decoder:read(bits)
	local code = buffer.readbits(self._buff, self._head, bits)
	self._head += bits

	local str = ""
	local n = code
	for i = 1, bits do
		str ..= n%2
		n //= 2
	end
	print(str)

	return code
end

-- built-in decode functionality

local fibSeq = {}
local a0, a1 = 1, 1

for i = 1, 32 do
	a0, a1 = a1, a0 + a1
	fibSeq[i] = a0
end

Decoder.maxFib = a1 - 1

function Decoder:readFib()
	local n = 0
	local armed = false
	for i, f in next, fibSeq do
		local d = self:read(1)
		if armed and d == 1 then
			return n
		end
		armed = d == 1
		n += f*d
	end
end

function Decoder:readString(len)
	local strbuff = buffer.create(len)
	for i = 0, len - 1 do
		buffer.writeu8(strbuff, i, self:read(8))
	end

	return buffer.tostring(strbuff)
end

function Decoder:readCode(root)
	local node = root
	while node.node0 do -- while it's a branch
		local branch = self:read(1)
		if branch == 0 then
			node = node.node0
		else
			node = node.node1
		end
	end

	return node
end















--[[
	testData = {
		one = 1;
		two = 2;
		list = {"one", "two", "three"};
	}

	testData.self = testData
]]


return Decoder


-- local testDataString = [[
-- 0 0 0 1 00011 00101110 10000110 01000110 00110110 10100110 1 00011 11111010 00001110 01100110 10010110 01000110 1 00011 11111010 00101110 10011110 00001110 10100110 1 000011 11111010 01000110 11001110 00101110 01001110 10010110 01110110 11100110 

-- 0 0 0 1 01 001 1 1 0011 00101110 11101110 11110110 0 1 000 1 01 000 0 1 01 1 1 1 0011 11110110 01110110 10100110 

-- 010 11 00011 11 000 11 001 000 011 10 1011 11001110 10100110 00110110 01100110 010 10 1011 00110110 10010110 11001110 00101110 011 1011 11 11 001 10 00011 00101110 00010110 01001110 10100110 10100110
-- ]]

-- local buff = buffer.create(1000)

-- local byte0 = string.byte("0")
-- local byte1 = string.byte("1")

-- local head = 0

-- for i = 1, #testDataString do
-- 	local byte = string.byte(testDataString, i)
-- 	if byte == byte0 then
-- 		buffer.writebits(buff, head, 1, 0)
-- 		head += 1
-- 	elseif byte == byte1 then
-- 		buffer.writebits(buff, head, 1, 1)
-- 		head += 1
-- 	end
-- end



-- local decoder = Decoder.new(buff)

-- local value = decoder:decode()


-- print(value.one, value.two, value.self == value, value.list)
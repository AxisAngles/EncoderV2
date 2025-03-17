local EncoderFuncs = require("./EncoderFuncs")
local BitBuffer = require("./BitBuffer")

local Decoder = {}
Decoder.__index = Decoder

--local print = function() end

function Decoder.new(buff)
	local self = setmetatable({}, Decoder)

	self._reader = BitBuffer.Reader.new(buff)
	assert(self._reader:readFib() == 1, "version incompatible") -- version

	self._indexNameToIndexHead = {}
	self._indexNameToValue = {}
	self._dataOrig = nil

	self.index = {}

	self:_decodeIndex()

	return self
end

-- 201.9 lbs this morning

-- 2 grande americanos (15x2 calories)
-- chipotle double chicken with sourcream (900 calories)

function Decoder:_decodeIndex()
	local totalLength = 0
	local indexCount = self._reader:readFib() - 1
	for i = 1, indexCount do
		local l = self._reader:readFib() - 1
		local indexName = self._reader:readString(l)
		local indexLength = self._reader:readFib()

		self._indexNameToIndexHead[indexName] = totalLength
		table.insert(self.index, indexName)

		totalLength += indexLength
	end
	self._dataOrig = self._reader:getHead()
end

function Decoder:decode(name)
	if name ~= nil then
		return self:_decode(name)
	end

	for _, indexName in self.index do
		self:_decode(indexName)
	end

	return table.clone(self._indexNameToValue)
end

function Decoder:_decode(name)
	-- print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("index", name)
	if self._indexNameToValue[name] == nil then
		local indexHead = self._indexNameToIndexHead[name]
		--print(name)
		assert(indexHead, name .. " is not a valid indexName for this data")

		self._reader:setHead(self._dataOrig + indexHead)
		--print(self._reader:getHead())

		self._tableDecoded = {}
		self._typeTree = self:_decodeTypeTree()
		self._valueTree = self:_decodeValueTree()
		self._indexNameToValue[name] = self:_decodeValue()
	end

	return self._indexNameToValue[name]
end





function Decoder:_decodeTypeTree()
	local node = {}
	local isLeaf = self._reader:read(1) == 1
	if isLeaf then
		local len = self._reader:readFib()
		node.value = self._reader:readString(len)
	else
		node.node0 = self:_decodeTypeTree()
		node.node1 = self:_decodeTypeTree()
	end
	return node
end

function Decoder:_decodeValueTree(code)
	code = code or ""
	local node = {}
	local isLeaf = self._reader:read(1) == 1
	if isLeaf then
		local type = self._reader:readCode(self._typeTree).value
		node.type = type
		if type == "_type" then -- this is a special case
			node.value = self._reader:readCode(self._typeTree).value
		elseif type == "table" then
			node.value = {} -- just initialize a table for reference purposes
		else
			node.value = EncoderFuncs.decode(self._reader, type)
		end
	else
		node.node0 = self:_decodeValueTree(code .. "0")
		node.node1 = self:_decodeValueTree(code .. "1")
	end
	return node
end

function Decoder:_decodeValue()
	local node = self._reader:readCode(self._valueTree)
	if node.type == "_type" then -- decode a literal
		if node.value == "table" then
			return self:_decodeTable({})
		else
			return EncoderFuncs.decode(self._reader, node.value)
		end
	elseif node.type == "table" then -- decode a table
		return self:_decodeTable(node.value)
	else -- just return the reference
		return node.value
	end
end

function Decoder:_decodeTable(tab)
	if self._tableDecoded[tab] then
		return tab
	end

	self._tableDecoded[tab] = true

	local listCount = self._reader:readFib() - 1
	local hashCount = self._reader:readFib() - 1

	for i = 1, listCount do
		local value = self:_decodeValue()
		tab[i] = value
	end

	for i = 1, hashCount do
		local index = self:_decodeValue()
		local value = self:_decodeValue()
		tab[index] = value
	end

	return tab
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


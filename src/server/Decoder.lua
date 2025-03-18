local EncoderFuncs = require("./EncoderFuncs")
local BitBuffer = require("./BitBuffer")

local Decoder = {}
Decoder.__index = Decoder

function Decoder.new(buff)
	local self = setmetatable({}, Decoder)

	self._reader = BitBuffer.Reader.new(buff)
	assert(self._reader:readFib() == 1, "version incompatible") -- version

	return self
end

function Decoder:decode(name)
	self._tableDecoded = {}
	self._typeTree = self:_decodeTypeTree()
	self._valueTree = self:_decodeValueTree()
	return self:_decodeValue()
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

return Decoder
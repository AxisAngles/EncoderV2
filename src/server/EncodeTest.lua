local EncoderFuncs = require("./EncoderFuncs")
local BitBuffer = require("./BitBuffer")

local Encoder = {}
Encoder.__index = Encoder

function Encoder.new(buff)
	local self = setmetatable({}, Encoder)
	--self._writer = BitBuffer.Writer.new()

	--print(self._referenceWriter)

	self._mode = "write" -- "count" or "write"
	self._count = 0

	self._buffs = {}
	self._buff = buffer.create(1)
	self._head = 0
	self._len = 8*buffer.len(self._buff)
	
	self._tableEncoded = {}

	self:writeFib(1) -- version

	return self
end




function Encoder:encode(value)
	self:_collectValues(value)
	self:_createValueLeaves()
	self:_createValueTree()

	self:_collectTypes()
	self:_createTypeLeaves()
	self:_createTypeTree()

	self:_encodeTypeTree(self._typeTree.root)
	self:_encodeValueTree(self._valueTree.root)
	self:_encodeValue(value)
end

-- eventually this can deduplicate actually
function Encoder:_collectValues(value)
	-- maybe this should make a counter class instead
	-- eventually write to a different buffer so that we can hash and deduplicate similar CFrames and Color3s
	-- typeToHash
	-- hashToNodeList
	-- node list contains all values of a certain type which hash to the same value

	local writer = BitBuffer.Writer.new()

	local valueToNode = {}
	local function recurse(value)
		if valueToNode[value] then
			valueToNode[value].freq += 1
			return
		end

		local type = EncoderFuncs.subtypeof(self, value)

		local node = {
			type = type;
			value = value;
			freq = 1;
			cost = nil;
		}
		valueToNode[value] = node

		if type == "table" then
			local listCount = 0
			local hashCount = 0

			local nextIndex = 1
			for i, v in value do
				if i == nextIndex then
					nextIndex += 1
					listCount += 1
					recurse(v)
				else
					nextIndex = nil
					hashCount += 1
					recurse(i)
					recurse(v)
				end
			end

			node.listCount = listCount
			node.hashCount = hashCount
		else
			node.orig = writer:getHead()
			EncoderFuncs.encode(writer, type, value)
			node.cost = writer:getHead() - node.orig
		end
	end

	recurse(value)

	self._literalDataBuff = writer:dump()
	self._valueToNode = valueToNode
end

local ln2 = math.log(2)
local function partialEntropy(x)
	if x == 0 then return 0 end
	return x*math.log(x)/ln2
end

-- cost of going from literal to reference (hopefully negative)
local function litToRefCost(typeFreq, freq, cost)
	return
		- partialEntropy(typeFreq - freq) -- adding the new type cost
		- partialEntropy(freq) -- adding the new cost of encoding a reference 
		+ cost -- adding the one time encoding cost
		+ 2 -- extra encoding cost

		+ partialEntropy(typeFreq) -- removing the old type cost
		- freq*cost -- removing the multi-time encoding cost
end

function Encoder:_createValueLeaves()
	local literalToNode = {}
	local valueLeaves = {}
	local nodes = {}

	-- first, build literal types
	for value, node in self._valueToNode do
		local type = node.type
		local freq = node.freq
		assert(type, "leaves must have a type!")

		local literalNode = literalToNode[type]
		if not literalNode then
			literalNode = {
				type = "_type";
				value = type;
				freq = 0;
				cost = nil;
			}

			literalToNode[type] = literalNode
			table.insert(valueLeaves, literalNode)
		end

		literalNode.freq += freq
	end

	-- make a new table for leaves that we can pluck from
	for value, node in self._valueToNode do
		table.insert(nodes, node)
	end

	repeat
		local changed = false
		for i = #nodes, 1, -1 do
			local node = nodes[i]
			local freq = node.freq
			local type = node.type

			local literalNode = literalToNode[type]

			if
				type == "table" and freq > 1 or
				type ~= "table" and litToRefCost(literalNode.freq, freq, node.cost) < 0
			then
				local n = #nodes
				nodes[i] = nodes[n]
				nodes[n] = nil

				table.insert(valueLeaves, node)
				literalNode.freq -= freq

				changed = true
			end
		end
	until not changed

	self._literalToNode = literalToNode
	self._valueLeaves = valueLeaves
end

function Encoder:_collectTypes()
	local typeToNode = {}

	local function countType(type)
		local typeNode = typeToNode[type]
		if not typeNode then
			typeNode = {
				value = type;
				freq = 0;
			}
			typeToNode[type] = typeNode
		end

		typeNode.freq += 1
	end

	local function recurse(node)
		if node.node0 then
			recurse(node.node0)
			recurse(node.node1)
		else
			countType(node.type)
			if node.type == "_type" then
				countType(node.value)
			end
		end
	end

	recurse(self._valueTree.root)

	self._typeToNode = typeToNode
end

-- we are going to create a tree for names of things.
function Encoder:_createTypeLeaves()
	local typeLeaves = {}

	for type, node in self._typeToNode do
		table.insert(typeLeaves, node)
	end

	self._typeLeaves = typeLeaves
end

local function compareNodes(nodeA, nodeB)
	return nodeA.freq > nodeB.freq
end

local function buildTree(leaves)
	local nodes = table.clone(leaves)
	table.sort(nodes, compareNodes)

	local n = #nodes
	for i = n - 1, 1, -1 do
		local node1 = table.remove(nodes)
		local node0 = table.remove(nodes)

		local freq = node0.freq + node1.freq
		local node = {
			freq = freq;
			node0 = node0;
			node1 = node1;
		}

		local pos = i
		for k, nodeK in next, nodes do
			if not compareNodes(nodeK, node) then
				pos = k
				break
			end
		end

		table.insert(nodes, pos, node)
	end

	local root = nodes[1]
	local leafToBits = {}
	local leafToCode = {}

	local function recurse(node, bits, code, c)
		if node.node0 then
			recurse(node.node0, bits + 1, code + 0*c, 2*c)
			recurse(node.node1, bits + 1, code + 1*c, 2*c)
		else
			leafToBits[node] = bits
			leafToCode[node] = code
		end
	end

	recurse(root, 0, 0, 1)

	return {
		root = root;
		leafToBits = leafToBits;
		leafToCode = leafToCode;
	}
end

function Encoder:_createValueTree()
	self._valueTree = buildTree(self._valueLeaves)
end

function Encoder:_createTypeTree()
	self._typeTree = buildTree(self._typeLeaves)
end

-- yeah maybe this is fine
function Encoder:_encodeTypeTree(node)
	if node.node0 then -- it's a branch
		self:write(1, 0)
		--print(0)
		self:_encodeTypeTree(node.node0)
		self:_encodeTypeTree(node.node1)
	else
		self:write(1, 1)
		--print(1)
		--print("encoding", #node.value, node.value)
		self:writeFib(#node.value)
		self:writeString(node.value)
		--encodeNode(self, node)
	end
end

function Encoder:writeBufferBits(buff, orig, bits)
	while bits >= 32 do
		self:write(32, buffer.readbits(buff, orig, 32))
		orig += 32
		bits -= 32
	end

	self:write(bits, buffer.readbits(buff, orig, bits))
end

function Encoder:_encodeValueTree(node, code)
	code = code or ""
	if node.node0 then
		self:write(1, 0)
		self:_encodeValueTree(node.node0, code .. "0")
		self:_encodeValueTree(node.node1, code .. "1")
	else
		self:write(1, 1)
		local type = node.type
		local value = node.value
		--print("encoding", type, value, code)
		local typeNode = self._typeToNode[type]
		local success = self:writeCode(self._typeTree, typeNode)
		if type == "_type" then
			local literalNode = self._typeToNode[value]
			local success = self:writeCode(self._typeTree, literalNode)
		elseif type == "table" then
			-- nothing
		else
			self:writeBufferBits(self._literalDataBuff, node.orig, node.cost)
		end
	end
end

--[[
	if we have a reference
		encode the referenceCode
		if it's a table and we are encountering it for the first time, encode the table
	else, it's a literal
		encode the literalCode
		if it's a table and we are encountering it for the first time, encode the table

]]

function Encoder:_encodeValue(value)
	local valueNode = self._valueToNode[value]
	local written = self:writeCode(self._valueTree, valueNode)
	local type = valueNode.type

	if written then
		if type == "table" then
			self:_encodeTable(valueNode)
		end
	else
		local value = valueNode.value
		local literalNode = self._literalToNode[type]
		self:writeCode(self._valueTree, literalNode)
		if type == "table" then
			self:_encodeTable(valueNode)
		else
			self:writeBufferBits(self._literalDataBuff, valueNode.orig, valueNode.cost)
			--EncoderFuncs.encode(self, type, value)
		end
	end
end

function Encoder:_encodeTable(tabNode)
	if tabNode.encoded then
		return
	end
	
	tabNode.encoded = true

	--print("writing listCount", tabNode.listCount + 1)
	self:writeFib(tabNode.listCount + 1)
	self:writeFib(tabNode.hashCount + 1)

	-- now encode for real
	local nextIndex = 1
	for i, v in tabNode.value do
		if i == nextIndex then
			nextIndex += 1
			self:_encodeValue(v)
		else
			nextIndex = nil
			self:_encodeValue(i)
			self:_encodeValue(v)
		end
	end
end







function Encoder:_readCount()
	local count = self._count
	self._count = 0
	return count
end

function Encoder:_setCountMode()
	self._mode = "count"
end

function Encoder:_setWriteMode()
	self._mode = "write"
end

function Encoder:write(bits, code)
	if self._mode == "count" then
		self._count += bits
		return
	end

	-- local str = ""
	-- local n = code
	-- for i = 1, bits do
	-- 	str ..= n%2
	-- 	n //= 2
	-- end
	-- print(str)

	while self._head + bits > self._len do
		local rem = self._len - self._head
		local pow = 2^rem

		buffer.writebits(self._buff, self._head, rem, code%pow)

		bits  -= rem
		code //= pow

		table.insert(self._buffs, self._buff)

		self._len *= 2
		self._head = 0
		self._buff = buffer.create(self._len/8)
	end

	buffer.writebits(self._buff, self._head, bits, code)
	self._head += bits
end

function Encoder:dump()
	local length = 0
	for i, buff in self._buffs do
		length += buffer.len(buff)
	end

	length += -(-self._head//8)

	local dumpBuff = buffer.create(length)
	local head = 0
	for i, buff in self._buffs do
		buffer.copy(dumpBuff, head, buff)
		head += buffer.len(buff)
	end

	buffer.copy(dumpBuff, head, self._buff, 0, -(-self._head//8))

	return dumpBuff
end

-- built-in decode functionality

local fibSeq = {}
local a0, a1 = 1, 1

for i = 1, 32 do
	a0, a1 = a1, a0 + a1
	fibSeq[i] = a0
end

Encoder.maxFib = a1 - 1

function Encoder:writeFib(n)
	local c
	for i, f in next, fibSeq do
		if f > n then
			c = i - 1
			break
		end
	end

	if not c then
		error(n .. " is too large to be fib encoded")
	end

	local code = 0
	for i = c, 1, -1 do
		local f = fibSeq[i]
		if n >= f then
			code = 2*code + 1
			n -= f
		else
			code = 2*code + 0
		end
	end

	self:write(c, code)
	self:write(1, 1)
end

function Encoder:writeString(value)
	local len = #value
	for i = 1, len do
		self:write(8, string.byte(value, i))
	end
end

function Encoder:writeCode(tree, node)
	local bits = tree.leafToBits[node]
	local code = tree.leafToCode[node]
	if bits then
		self:write(bits, code)
		return true
	else
		return false
	end
end



local test = {1, 2, 3}
test[test] = test

local encoder = Encoder.new()
encoder:encode(test)

local data = encoder:dump()

local Decoder = require("./DecodeTest")

print("buffer length", buffer.len(data))

local decoder = Decoder.new(data)
local value = decoder:decode()


print(unpack(value[value]))




return Encoder
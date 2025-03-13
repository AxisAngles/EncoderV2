local Serializer = {}
Serializer.__index = Serializer

do
	local function compareNodes(nodeA, nodeB)
		if nodeA.freq == nodeB.freq then
			return nodeA.rank < nodeB.rank
		else
			return nodeA.freq > nodeB.freq
		end
	end

	local function buildHuffTree(valueToFrequency, valueToRank)
		-- rank disambiguates when frequencies are equal
		local nodes = {}

		for value, freq in valueToFrequency do
			local rank = valueToRank and valueToRank[value] or 0
			table.insert(nodes, {
				freq = freq;
				rank = rank;
				value = value;
			})
		end

		table.sort(nodes, compareNodes)

		local n = #nodes
		for i = n - 1, 1, -1 do
			local node1 = table.remove(nodes)
			local node0 = table.remove(nodes)

			local freq = node0.freq + node1.freq
			local rank = math.min(node0.rank, node1.rank)
			local node = {
				freq = freq;
				rank = rank;
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

		return nodes[1]
	end

	local function buildHuffCodesRecurse(valueToCode, valueToBits, node, code, bits)
		if node.value ~= nil then
			valueToCode[node.value] = code
			valueToBits[node.value] = bits
		else
			buildHuffCodesRecurse(valueToCode, valueToBits, node.node0, code + 2^bits*0, bits + 1)
			buildHuffCodesRecurse(valueToCode, valueToBits, node.node1, code + 2^bits*1, bits + 1)
		end
	end

	local function buildHuffCodes(huffRoot)
		local valueToCode = {}
		local valueToBits = {}
		buildHuffCodesRecurse(valueToCode, valueToBits, huffRoot, 0, 0)
		return valueToBits, valueToCode
	end

	local function encodeHuff(write, valueToBits, valueToCode, value)
		write(valueToBits[value], valueToCode[value])
	end

	local function decodeHuff(read, huffRoot)
		local node = huffRoot
		while not node.value do -- while it's not a leaf
			local branch = read(1)
			if branch == 0 then
				node = node.node0
			else
				node = node.node1
			end
		end

		return node.value
	end

	local function encodeHuffTree(write, encode, node)
		if node.value == nil then
			write(1, 0)
			encodeHuffTree(write, encode, node.node0)
			encodeHuffTree(write, encode, node.node1)
		else
			write(1, 1)
			encode(write, node.value)
		end
	end

	local function decodeHuffTree(read, decode)
		local node = {}
		local isLeaf = read(1) == 1
		if isLeaf then
			node.value = decode(read)
		else
			node.node0 = decodeHuffTree(read, decode)
			node.node1 = decodeHuffTree(read, decode)
		end
		return node
	end




	local fibSeq = {}
	local a0, a1 = 1, 1
	for i = 1, 32 do
		--print(math.frexp(a1), a1)
		fibSeq[i] = a1
		a0, a1 = a1, a0 + a1
	end
	local maxFib = a1


	local function encodeFib(write, n)
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

		write(c, code)
		write(1, 1)
	end

	local function decodeFib(read)
		local n = 0
		local armed = false
		for i, f in next, fibSeq do
			local d = read(1)
			if armed and d == 1 then
				return n
			end
			armed = d == 1
			n += f*d
		end
	end

	-- feels kind of cheaty
	local doubleBuff = buffer.create(8)
	local function encodeDouble(write, n)
		buffer.writef64(doubleBuff, 0, n)
		write(32, buffer.readu32(doubleBuff, 0))
		write(32, buffer.readu32(doubleBuff, 4))
	end

	local function decodeDouble(read)
		buffer.writeu32(doubleBuff,  0, read(32))
		buffer.writeu32(doubleBuff, 32, read(32))
		return buffer.readf64(doubleBuff, 0)
	end

	local function encodeString(write, str)
		local l = #str
		encodeFib(write, l + 1)
		for i = 1, l do
			local n = string.byte(str, i)
			write(8, n)
		end
	end

	local decodeStringMem = {}
	local function decodeString(read)
		table.clear(decodeStringMem)
		local l = decodeFib(read) - 1
		for i = 1, l do
			decodeStringMem[i] = string.char(read(8))
		end
		return table.concat(decodeStringMem)
	end


	--[[
		step 1: collect frequency table for all values.
		step 2: collect frequency table for all types in the value frequency table.
		step 3: build huffman tree for type frequencies
		step 4: encode type huffman tree
		step 5: build huffman tree for value frequencies
		step 6: encode value huffman free
		step 7: recurse through datastructure, when encountering a new table for the first time, build it

		-- explicit nan check, 
	]]


	function Serializer.newSerializer()
		local self = setmetatable({}, Serializer)

		self._buffer = buffer.create(1)
		self._length = 8
		self._head = 0

		return self
	end

	function Serializer:write(bits, code)
		if self._head + bits > self._length then
			repeat self._length *= 2
			until self._head + bits <= self._length

			local oldBuffer = self._buffer
			self._buffer = buffer.create(self._length/8)
			buffer.copy(self._buffer, 0, oldBuffer)
		end

		buffer.writebits(self._buffer, self._head, bits, code)
		self._head += bits
	end

	function Serializer:read(bits)
		local code = buffer.readbits(self._buffer, self._head, bits)
		self._head += bits
		return code
	end

	local function getNumberType(value) -- different ways to encode a number
		if value == 0 then
			return "_zero"
		elseif value%1 ~= 0 or value <= -maxFib or maxFib <= value or value ~= value then
			return "_double"
		elseif value < 0 then
			return "_nfib"
		elseif value > 0 then
			return "_pfib"
		end
	end

	local function getBooleanType(value)
		return value and "_true" or "_false"
	end

	local function extendedTypeof(value)
		local valueType = typeof(value)
		if valueType == "boolean" then
			return getBooleanType(value)
		elseif valueType == "number" then
			return getNumberType(value)
		else
			return valueType
		end
	end

	function Serializer:encode(value)
		local valueToFrequency = {}
		local tableToArraySize = {}
		local tableToOtherSize = {}
		local function recurse(value)
			local valueType = extendedTypeof(value)
			if valueType == "table" then
				if valueToFrequency[value] then
					valueToFrequency[value] += 1
				else
					valueToFrequency[value] = 1

					local arraySize = 0
					local otherSize = 0

					local nextIndex = 1
					for i, v in value do
						if i == nextIndex then
							nextIndex += 1
							arraySize += 1
							recurse(v)
						else
							nextIndex = nil
							otherSize += 1
							recurse(i)
							recurse(v)
						end
					end

					tableToArraySize[value] = arraySize
					tableToOtherSize[value] = otherSize
				end
			else
				valueToFrequency[value] = (valueToFrequency[value] or 0) + 1
			end
		end

		recurse(value)

		local typeToFrequency = {}
		for value, frequency in valueToFrequency do
			--print(value, frequency)
			local valueType = extendedTypeof(value)
			typeToFrequency[valueType] = (typeToFrequency[valueType] or 0) + 1
		end

		-- for type, frequency in typeToFrequency do
		-- 	print(type, frequency)
		-- end

		local function write(bits, code)
			self:write(bits, code)
		end

		local  typeTreeRoot = buildHuffTree( typeToFrequency)
		local valueTreeRoot = buildHuffTree(valueToFrequency)

		local  typeToBits,  typeToCode = buildHuffCodes( typeTreeRoot)
		local valueToBits, valueToCode = buildHuffCodes(valueTreeRoot)

		encodeHuffTree(write, encodeString, typeTreeRoot)

		print("encoded types", self._head)

		local function encodeDefinition(write, value)
			local valueType = extendedTypeof(value)
			--print(valueType)
			local typeBits = typeToBits[valueType]
			local typeCode = typeToCode[valueType]
			--print(typeBits, typeCode)
			write(typeBits, typeCode)

			if valueType == "nil" then -- uhhh
				error("yeah don't do this")
			elseif valueType == "_false" then
				-- no value to encode
			elseif valueType == "_true" then
				-- no extra data to encode
			elseif valueType == "_zero" then
				-- no extra data to encode
			elseif valueType == "_pfib" then
				encodeFib(write, value)
			elseif valueType == "_nfib" then
				encodeFib(write, -value)
			elseif valueType == "_double" then
				encodeDouble(write, value)
			elseif valueType == "string" then
				encodeString(write, value)
			elseif valueType == "table" then
				-- no extra data to encode
			else
				if not types[valueType] then
					error("no encode for " .. valueType)
				end

				local encodeValue = types[valueType].encode
				encodeValue(write, value)
			end
		end

		encodeHuffTree(write, encodeDefinition, valueTreeRoot)
		print("encoded values", self._head)

		local tableSeen = {}

		local function encodeValue(value)
			local valueBits = valueToBits[value]
			local valueCode = valueToCode[value]
			write(valueBits, valueCode)

			local valueType = extendedTypeof(value)
			if valueType == "table" then
				if tableSeen[value] then
					return
				end
				tableSeen[value] = true

				encodeFib(write, tableToArraySize[value] + 1)
				encodeFib(write, tableToOtherSize[value] + 1)

				local nextIndex = 1
				for i, v in value do
					if i == nextIndex then
						nextIndex += 1
						encodeValue(v)
					else
						nextIndex = nil
						encodeValue(i)
						encodeValue(v)
					end
				end
			end
		end

		encodeValue(value)
		print("encoded structure", self._head)
	end
end


local s = Serializer.newSerializer()

local sampleData = {
	a = true;
	b = false;
	c = {1, 2, 3, 4, 5};
	d = {
		a = {"a", "b", "c", "d", "e"};
		b = {nil, nil, nil, nil, true};
		z = true;
	}
}

-- sampleData.e = sampleData.d
-- sampleData.f = sampleData.d
-- sampleData.g = sampleData.d
-- sampleData.h = sampleData.d

s:encode(sampleData)

print(s._head)
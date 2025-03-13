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
		could just make a list of the frequencies of all things:
			the cost of not referencing something is just the cost of encoding something x times
				freq * encode cost
			the cost of referencing something is the cost of encoding + 2 bits for huffman storage + the huffman reference x times
				~2 bits + encode cost + freq * huff encode cost
				huff encode cost ~ huff type encode cost + reference cost
				reference cost is log2(totalFreq/freq)
				huff type cost is log2(totalRefFreq/refFreq)


		first pass:
			collect all strings and their frequencies
			collect all number types (0, 1+, -1-, double) and their frequencies
				integer array indices do not count towards this
			collect all types and their frequencies
				string indices do not count towards this
				integer array indices do not count towards this

		encode type huffman tree
		encode string huffman tree
		encode number huffman tree

		second pass:
			encode as usual


		booleans:
			[boolean huffman code]
				[false 0 or true 1]

		numbers:
			[number huffman code] [number subtype huffman code]
				if 0, encode nothing
				if +int, encode fib
				if -int, encode fib
				if double, encode double

		strings:
			[string huffman code] [string reference huffman code]

		tables:
			[table huffman code]
				[number of array elements]
					[value] [value] [value]
				[number of string elements]
					[huff string] [value] [huff string] [value]
				[number of other elements]
					[index] [value] [index] [value]
	]]

	-- special types go here
	-- we do some special logic for encoding other stuff
	local types = {
	}

	function Serializer.newSerializer()
		local self = setmetatable({}, Serializer)

		self._buffer = buffer.create(1)
		self._length = 8
		self._head = 0

		return self
	end

	function Serializer.newDeserializer(buff)
		local self = setmetatable({}, Serializer)

		self._buffer = buff
		self._head = 0

		return self
	end

	function Serializer:deserialize(value)
	end

	function Serializer:serialize(value)

	end

	function Serializer:write(bits, code)
		if self._head + bits > self._length then
			repeat
				self._length *= 2
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









	local function getNumberType(value)
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

	local function printTreePicture(node, tabs)
		tabs = tabs or ""
		if node.value == nil then
			print(tabs .. "o")
			printTree(node.node0, tabs .. "\t")
			printTree(node.node1, tabs .. "\t")
		else
			print(tabs .. node.value)
		end
	end

	local function printTree(root)
		local valueToBits, valueToCode = buildHuffCodes(root)

		for value, bits in valueToBits do
			local code = valueToCode[value]
			local s = ""
			for i = 1, bits do
				s ..= code%2
				code //= 2
			end
			for i = 1, 10 - bits do
				s ..= " "
			end
			print(s .. value)
		end

	end

	function Serializer:encode(value)
		local function write(bits, code)
			self:write(bits, code)
		end

		local typeToFrequency, stringToFrequency = self:pass0(value)

		local typeTreeRoot = buildHuffTree(typeToFrequency)
		local stringTreeRoot = buildHuffTree(stringToFrequency)
		local typeToBits, typeToCode = buildHuffCodes(typeTreeRoot)
		local stringToBits, stringToCode = buildHuffCodes(stringTreeRoot)

		--print("encoding types")
		encodeHuffTree(write, encodeString, typeTreeRoot)

		--print("encoding strings")
		encodeHuffTree(write, encodeString, stringTreeRoot)

		--printTree(typeTreeRoot)
		--printTree(stringTreeRoot)

		--print(self._head)

		local tableCount = 0
		local tableToId = {}
		local function recurse(value)
			local valueType = typeof(value)
			--print("writing", self._head, valueType)
			if valueType == "nil" then -- uhhh
				local bits = typeToBits["nil"]
				local code = typeToCode["nil"]
				write(bits, code)
			elseif valueType == "boolean" then
				local booleanType = getBooleanType(value)
				local bits = typeToBits[booleanType]
				local code = typeToCode[booleanType]
				write(bits, code)
			elseif valueType == "number" then
				local numberType = getNumberType(value)
				local bits = typeToBits[numberType]
				local code = typeToCode[numberType]
				write(bits, code)

				if numberType == "_zero" then
				elseif numberType == "_pfib" then
					encodeFib(write,  value)
				elseif numberType == "_nfib" then
					encodeFib(write, -value)
				elseif numberType == "_double" then
					encodeDouble(write, value)
				else
					error("what")
				end
			elseif valueType == "string" then
				local bits = typeToBits["string"]
				local code = typeToCode["string"]
				write(bits, code)

				local bits = stringToBits[value]
				local code = stringToCode[value]
				write(bits, code)
			elseif valueType == "table" then
				if tableToId[value] then
					local bits = typeToBits["_tabref"]
					local code = typeToCode["_tabref"]
					write(bits, code)

					local _, bits = math.frexp(tableCount - 1)
					local tableId = tableToId[value]
					write(bits, tableId)
				else
					local bits = typeToBits["table"]
					local code = typeToCode["table"]
					write(bits, code)

					tableToId[value] = tableCount
					tableCount += 1

					local arrayLength  = 0
					local stringLength = 0
					local otherLength  = 0

					local arrayPart = {}
					local stringPart = {}
					local otherPart = {}

					local nextIndex = 1
					for i, v in value do
						if i == nextIndex then
							nextIndex += 1
							arrayPart[i] = v
							arrayLength += 1
						else
							nextIndex = nil
							if type(i) == "string" then
								stringPart[i] = v
								stringLength += 1
							else
								otherPart[i] = v
								otherLength += 1
							end
						end
					end

					encodeFib(write,  arrayLength + 1)
					encodeFib(write, stringLength + 1)
					encodeFib(write,  otherLength + 1)

					for i, v in arrayPart do
						recurse(v)
					end

					for i, v in stringPart do
						local bits = stringToBits[i]
						local code = stringToCode[i]
						write(bits, code)
						recurse(v)
					end

					for i, v in otherPart do
						recurse(i)
						recurse(v)
					end
				end
			else
				if not types[valueType] then
					error("no encode function for type " .. valueType)
				end
			end
		end

		recurse(value)

		print("bits to encode", self._head)
	end


	function Serializer:decode()
		local function read(bits)
			return self:read(bits)
		end

		--print("decoding types")
		local typeTreeRoot = decodeHuffTree(read, decodeString)
		--print("decoding strings")
		local stringTreeRoot = decodeHuffTree(read, decodeString)

		printTree(typeTreeRoot)
		printTree(stringTreeRoot)

		--print(self._head)

		local tableCount = 0
		local idToTable = {}

		local function recurse()
			local h = self._head
			local valueType = decodeHuff(read, typeTreeRoot)
			--print("reading", h, valueType)
			if valueType == "nil" then -- uhhh
				return nil
			elseif valueType == "_false" then
				return false
			elseif valueType == "_true" then
				return true
			elseif valueType == "_zero" then
				return 0
			elseif valueType == "_pfib" then
				return decodeFib(read)
			elseif valueType == "_nfib" then
				return -decodeFib(read)
			elseif valueType == "_double" then
				return decodeDouble(read)
			elseif valueType == "string" then
				return decodeHuff(read, stringTreeRoot)
			elseif valueType == "_tabref" then
				local _, bits = math.frexp(tableCount - 1)
				local tableId = read(bits)
				return idToTable[tableId]
			elseif valueType == "table" then
				local tab = {}
				idToTable[tableCount] = tab
				tableCount += 1

				local arrayLength  = decodeFib(read) - 1
				local stringLength = decodeFib(read) - 1
				local otherLength  = decodeFib(read) - 1

				--print(arrayLength, stringLength, otherLength)

				for i = 1, arrayLength do
					local value = recurse()
					tab[i] = value
				end

				for i = 1, stringLength do
					local index = decodeHuff(read, stringTreeRoot)
					local value = recurse()
					tab[index] = value
				end

				for i = 1, otherLength do
					local index = recurse()
					local value = recurse()
					tab[index] = value
				end

				return tab
			else
				--
			end
		end

		return recurse()
	end






	function Serializer:pass0(value)
		local typeToFrequency = {}
		local stringToFrequency = {}

		local tableVisited = {}

		local function recurse(value)
			local valueType = typeof(value)
			if valueType == "nil" then -- uhhh
				typeToFrequency[valueType] = (typeToFrequency[valueType] or 0) + 1
			elseif valueType == "boolean" then
				local booleanType = getBooleanType(value)
				typeToFrequency[booleanType] = (typeToFrequency[booleanType] or 0) + 1
			elseif valueType == "number" then
				local numberType = getNumberType(value)
				typeToFrequency[numberType] = (typeToFrequency[numberType] or 0) + 1
			elseif valueType == "string" then
				typeToFrequency[valueType] = (typeToFrequency[valueType] or 0) + 1
				stringToFrequency[value] = (stringToFrequency[value] or 0) + 1
			elseif valueType == "table" then
				if tableVisited[value] then
					typeToFrequency["_tabref"] = (typeToFrequency["_tabref"] or 0) + 1
				else
					typeToFrequency["table"] = (typeToFrequency["table"] or 0) + 1
					tableVisited[value] = true

					local meta = getmetatable(value)
					if meta and meta.__call then
						error("table must not have a __call metamethod")
					end

					local nextIndex = 1
					for i, v in value do
						recurse(v)
						if i == nextIndex then
							nextIndex += 1
						else
							nextIndex = nil
							if type(i) == "string" then
								stringToFrequency[i] = (stringToFrequency[i] or 0) + 1
							else
								recurse(i)
							end
						end
					end
				end
			else
				if not types[valueType] then
					error("no encode function for type " .. valueType)
				end

				typeToFrequency[valueType] = (typeToFrequency[valueType] or 0) + 1
			end
		end

		recurse(value)

		return typeToFrequency, stringToFrequency
	end
end

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

local s = Serializer.newSerializer()
s:encode(sampleData)

local buff = s._buffer


local d = Serializer.newDeserializer(buff)

local x = d:decode()

print(x.a)
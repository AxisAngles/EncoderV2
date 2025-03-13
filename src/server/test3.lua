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


local function encodeHuffTree(write, encode, node)
	if node.value ~= nil then
		write(1, 1)
		encode(write, node.value)
	else
		write(1, 0)
		encodeHuffTree(write, encode, node.node0)
		encodeHuffTree(write, encode, node.node1)
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




local function encodeString(write, str)
	local l = #str
	encodeFib(write, l)
	for i = 1, l do
		local n = string.byte(str, i)
		write(8, n)
	end
end

local decodeStringMem = {}
local function decodeString(read)
	table.clear(decodeStringMem)
	local l = decodeFib(read)
	for i = 1, l do
		decodeStringMem[i] = string.char(read(8))
	end
	return table.concat(decodeStringMem)
end














local buff = buffer.create(100)
local whead = 0
local rhead = 0
local function write(bits, value)
	buffer.writebits(buff, whead, bits, value)
	whead += bits
end
local function read(bits)
	local value = buffer.readbits(buff, rhead, bits)
	rhead += bits
	return value
end

local function getStringFrequenciesRecurse(valueToFrequency, value)
	local valueType = type(value)
	if valueType == "string" then
		valueToFrequency[value] = (valueToFrequency[value] or 0) + 1
	elseif valueType == "table" then
		for i, v in next, value do
			getStringFrequenciesRecurse(valueToFrequency, i)
			getStringFrequenciesRecurse(valueToFrequency, v)
		end
	end
end

local function getStringFrequencies(value)
	local valueToFrequency = {}
	getStringFrequenciesRecurse(valueToFrequency, value)
	return valueToFrequency
end












local function tobinarystring(n, b)
	-- if n == 0 then
	-- 	return "0"
	-- end

	local p = math.abs(n)
	local s = ""
	for i = 1, b do--while p > 0 do
		if p%2 == 0 then
			s = "0" .. s
		else
			s = "1" .. s
		end
		p //= 2
	end

	if n < 0 then
		s = "-" .. s
	end

	return s
end






local heyo = {"A", "A", "A", "A", "A", "B", "B", "C", "C", "C", "D", "E", "F", "G", "H", "I", "J"}

local f = getStringFrequencies(heyo)
for i, v in f do
	print(i, v)
end

local huffRoot = buildHuffTree(f)

encodeHuffTree(write, encodeString, huffRoot)

local root = decodeHuffTree(read, decodeString)
print(root.node0)

local valueToBits, valueToCode = buildHuffCodes(huffRoot)

for i, v in valueToCode do
	local b = valueToBits[i]
	print(i, b, tobinarystring(v, b))
end


--[[




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




local sampleData = {
	a = true;
	b = false;
	c = {1, 2, 3, 4, 5};
	d = {
		a = {"a", "b", "c", "d", "e"};
		b = {nil, nil, nil, nil, true}
	}
}


-- for i = 1, 33 do
-- 	encodeString(write, tostring(i))
-- 	print(decodeString(read))
-- 	--print(decodeFib(read))
-- end


--encodeFib(write, 3525000)


print(math.frexp(4))
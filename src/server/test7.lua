local maxFib
local encodeFib
local decodeFib


-- all these are defined later on, they're just in here for organization
local subtypeFunctions = {
	["boolean"] = nil;
	["number"] = nil;
	["string"] = nil;
}

-- we split up types into subtypes when we expect some subtypes to be way more common than others
-- integers vs doubles
-- true vs false
-- binary strings vs ASCII strings (TODO)
local valueEncoders = {
	["_true"] = {};
	["_false"] = {};

	["_zero"] = {};
	["_double"] = {};
	["_pfib"] = {};
	["_nfib"] = {};

	["_estring"] = {};
	["_bstring"] = {};
	--["_ASCII"] = {};


}








-- Boolean
function subtypeFunctions.boolean(value)
	return value and "_true" or "_false"
end

function valueEncoders._true.encode(write, value)
end

function valueEncoders._true.decode(read, value)
	return true
end

function valueEncoders._false.encode(write, value)
end

function valueEncoders._false.decode(read, value)
	return false
end








-- Number
function subtypeFunctions.number(value)
	if value == 0 then
		return "_zero"
	elseif
		value%1 ~= 0      or
		value   < -maxFib or
		value   >  maxFib or
		value   ~= value
	then
		return "_double"
	elseif value < 0 then
		return "_nfib"
	elseif value > 0 then
		return "_pfib"
	else
		error("what kind of number is this")
	end
end

function valueEncoders._zero.encode(write, value)
end

function valueEncoders._zero.decode(read)
	return 0
end

local _f64buff = buffer.create(8)
function valueEncoders._double.encode(write, value)
	buffer.writef64(_f64buff, 0, value)
	write(32, buffer.readbits(_f64buff,  0, 32))
	write(32, buffer.readbits(_f64buff, 32, 32))
end

function valueEncoders._double.decode(read)
	buffer.writebits(_f64buff,  0, 32, read(32))
	buffer.writebits(_f64buff, 32, 32, read(32))
	return buffer.readf64(_f64buff, 0)
end

function valueEncoders._pfib.encode(write, value)
	encodeFib(write, value)
end

function valueEncoders._pfib.decode(read)
	return decodeFib(read)
end

function valueEncoders._nfib.encode(write, value)
	encodeFib(write, -value)
end

function valueEncoders._nfib.decode(read)
	return -decodeFib(read)
end








-- String
function subtypeFunctions.string(value)
	if value == "" then
		return "_estring"
	else
		return "_bstring"
	end
end

function valueEncoders._estring.encode(write, value)
end

function valueEncoders._estring.decode(read)
	return ""
end

function valueEncoders._bstring.encode(write, value)
	local len = #value
	encodeFib(write, len)
	for i = 1, len do
		write(8, string.byte(value, i))
	end
end

function valueEncoders._bstring.decode(read)
	local len = decodeFib(read)
	local strbuff = buffer.create(len)
	for i = 0, len - 1 do
		buffer.writeu8(strbuff, i, read(8))
	end

	return buffer.tostring(strbuff)
end

-- TODO: make more assumptions about the general kind of text we will encounter
-- function valueEncoders._ASCII.encode(write, value)
-- end

-- function valueEncoders._ASCII.decode(read)
-- end



















do
	local fibSeq = {}
	local a0, a1 = 1, 1

	for i = 1, 32 do
		a0, a1 = a1, a0 + a1
		fibSeq[i] = a0
	end

	maxFib = a1 - 1

	function encodeFib(write, n)
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

	function decodeFib(read)
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
end








--[[
		local listCount = 0
		local hashCount = 0

		local nextIndex = 1
		for i, v in value do
			if i == nextIndex then
				nextIndex += 1
				listCount += 1
			else
				nextIndex = nil
				hashCount += 1
			end
		end
]]




local function subtypeof(value)
	local valueType = typeof(value)

	-- if valueType == "table" then
	-- 	local hasList = 0
	-- 	local hasHash = 0

	-- 	local nextIndex = 1
	-- 	for i, v in value do
	-- 		if i == nextIndex then
	-- 			nextIndex += 1
	-- 			hasList = true
	-- 		else
	-- 			nextIndex = nil
	-- 			hasHash = true
	-- 			break
	-- 		end
	-- 	end

	-- 	if hasList and hasHash then
	-- 		return "_mtable" -- mixed table
	-- 	elseif hasList then
	-- 		return "_ltable" -- list table
	-- 	elseif hasHash then
	-- 		return "_htable" -- hash table
	-- 	else
	-- 		return "_etable" -- empty table
	-- 	end
	-- end

	local subtypeFunction = subtypeFunctions[valueType]
	if subtypeFunction then
		return subtypeFunction(value)
	else
		return valueType
	end
end

local function encodeValue(write, subtype, value)
	--assert(valueEncoders[subtype], subtype)
	valueEncoders[subtype].encode(write, value)
end

local function decodeValue(read, subtype)
	valueEncoders[subtype].decode(read, value)
end





-- in this section, we work on building the leaf data, calculating cost, frequency, and type data


local function buildValueLeaves(value)
	local valueToLeaf = {}

	-- this is just for finding costs
	-- we can cache this data later
	local cost = 0
	local function write(bits)
		cost += bits
	end

	local function recurse(value)
		if valueToLeaf[value] then
			valueToLeaf[value].freq += 1
			return
		end

		local subtype = subtypeof(value)

		if subtype == "table" then
			-- we don't really care about the cost, this is going in references for sure
			valueToLeaf[value] = {
				type = "table"; -- update this later when we can know what subtype of table this is
				value = value;
				freq = 1;
				cost = 0; -- update this later after we have the counts
			}

			-- local listCount = 0
			-- local hashCount = 0

			local nextIndex = 1
			for i, v in value do
				if i == nextIndex then
					nextIndex += 1
					--listCount += 1
					recurse(v) -- don't count indices, we don't need to encode these
				else
					nextIndex = nil
					--hashCount += 1
					recurse(i)
					recurse(v)
				end
			end

			return
		end

		cost = 0
		encodeValue(write, subtype, value)

		valueToLeaf[value] = {
			type = subtype;
			value = value;
			freq = 1;
			cost = cost;
		}
	end

	recurse(value)

	return valueToLeaf
end

local function dedupLeaves(leaves)
	-- this will combine all data which is the same type and same encode data
	return leaves
end

-- these indicate that the information follows the leaf
-- local function buildTypeLeaves(valueToLeaf)
-- 	local typeToLeaf = {}

-- 	for value, leaf in valueToLeaf do
-- 		local type = leaf.type
-- 		local freq = leaf.freq
-- 		if typeToLeaf[type] then
-- 			typeToLeaf[type].freq += freq
-- 			return
-- 		end

-- 		typeToLeaf[type] = {
-- 			type = "_type";
-- 			value = type;
-- 			freq = freq;
-- 			cost = 0; -- doesn't matter, but can fill in later for more accurate size estimation
-- 		}
-- 	end

-- 	return typeToLeaf
-- end




-- in this section we build two lists, references and literals
-- references will be encoded into a huffman table
-- literals will be encoded literally
	-- if you only have a instance of something, or a very small encodable value
	-- there's no need to waste space indexing it in a huffman table

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


--[[
	eventually we need
	valueToBits
	valueToCode


]]


-- Our goal is to create a list of leaves which should be encoded into a huffman tree
-- Special case for tables with more than 1 reference
local function balance(valueToLeaf)
	local typeToFreq = {}

	local lits = {}
	local refs = {}

	-- first, build literal types
	for value, leaf in valueToLeaf do
		local type = leaf.type
		local freq = leaf.freq
		assert(type, "leaves must have a type!")
		typeToFreq[type] = (typeToFreq[type] or 0) + freq
	end

	-- make a new table for leaves that we can pluck from
	for value, leaf in valueToLeaf do
		table.insert(lits, leaf)
	end

	-- move leaves over to refs when it is beneficial to do so (or necessary)
	for x = 1, 100 do -- this should eventually be while true do
		local changed = false
		for i = #lits, 1, -1 do
			local leaf = lits[i]
			local type = leaf.type
			local freq = leaf.freq
			local cost = leaf.cost

			local typeFreq = typeToFreq[type]
			local moveCost = litToRefCost(typeFreq, freq, cost)
			if moveCost < 0 or type == "table" and freq > 1 then
				table.insert(refs, leaf)
				lits[i] = lits[#lits]
				lits[#lits] = nil
				typeToFreq[type] -= freq

				changed = true
			end
		end

		if not changed then break end
	end

	-- now, for the ones we did not move over, we will have to have some way to create them literally
	for type, freq in typeToFreq do
		table.insert(refs, {
			type = "_type";
			value = type;
			freq = freq;
		})
	end

	return refs
end

local function compareNodes(nodeA, nodeB)
	return nodeA.freq > nodeB.freq
end

-- here, we are building the huffman tree
local function buildHuffTree(refs)
	local nodes = table.clone(refs)
	table.sort(nodes, compareNodes)

	local n = #nodes
	for i = n - 1, 1, -1 do
		local node1 = table.remove(nodes)
		local node0 = table.remove(nodes)

		local freq = node0.freq + node1.freq
		local node = {
			node0 = node0;
			node1 = node1;
			freq = freq;
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

-- this function is to make it easy to get the code needed to encode a referenced value
local function buildHuffCodes(huffRoot)
	local valueToBits = {}
	local valueToCode = {}
	local  typeToBits = {}
	local  typeToCode = {}

	local function recurse(node, code, bits)
		--print(node.type, node.value, node.node0, node.node1)
		if not node.type then
			recurse(node.node0, code + 2^bits*0, bits + 1)
			recurse(node.node1, code + 2^bits*1, bits + 1)
		elseif node.type == "_type" then
			typeToCode[node.value] = code
			typeToBits[node.value] = bits
		else
			valueToCode[node.value] = code
			valueToBits[node.value] = bits
		end
	end

	recurse(huffRoot, 0, 0)

	return
		valueToBits, valueToCode,
		 typeToBits,  typeToCode
end




-- now to encode the huffman tree, we'll need to collect types
local function buildTypeHuffTree(refs)
	local typeToFreq = {}

	-- first, build literal types
	for i, leaf in refs do
		local type = leaf.type
		local value = leaf.value
		local freq = leaf.freq
		assert(type, "leaves must have a type!")

		if type == "_type" then
			typeToFreq[type] = (typeToFreq[type] or 0) + 1 -- literal indicator
			typeToFreq[value] = (typeToFreq[value] or 0) + 1
		else
			typeToFreq[type] = (typeToFreq[type] or 0) + freq
		end
	end

	local nodes = {}
	for type, freq in typeToFreq do
		table.insert(nodes, {
			type = "_metatype";
			value = type;
			freq = freq;
		})
	end

	return buildHuffTree(nodes)
end











-- for type decoding
local function encodeString(write, value)
	local len = #value
	encodeFib(write, len)
	for i = 1, len do
		write(8, string.byte(value, i))
	end
end

local function decodeString(read)
	local len = decodeFib(read)
	local strbuff = buffer.create(len)
	for i = 0, len - 1 do
		buffer.writeu8(strbuff, i, read(8))
	end

	return buffer.tostring(strbuff)
end













local testData = {
	one = 1;
	two = 2;
	list = {"one", "two", "three"};
}

testData.self = testData




-- temporarily define a buffer
local buff = buffer.create(1000)
local whead = 0
local rhead = 0
local function write(bits, value)
	local str = ""
	local n = value
	for i = 1, bits do
		str ..= value%2
		value //= 2
	end
	print(str)
	buffer.writebits(buff, whead, bits, value)
	whead += bits
end
local function read(bits)
	local value = buffer.readbits(buff, rhead, bits)
	rhead += bits
	return value
end


-- in order to encode the data, we'll want to build a huffman tree for large duplicate items
-- build the value huffman tree
local valueToLeaf = buildValueLeaves(testData)
local references = balance(valueToLeaf)

-- in order to encode the value huffman tree, we'll want to encode a type huffman tree




-- this is specifically for encoding the type tree
local function encodeTypeHuffmanTree(node)
	-- it's all the same type
	if not node.value then -- it's a branch
		write(1, 0)
		encodeTypeHuffmanTree(node.node0)
		encodeTypeHuffmanTree(node.node1)
	else
		write(1, 1)
		print("encoding " .. node.value .. " type")
		encodeString(write, node.value)
	end
end

local typeHuffRoot = buildTypeHuffTree(references)
print("encoding type huffman tree")
encodeTypeHuffmanTree(typeHuffRoot)

-- now for encoding the value tree
local typeToBits, typeToCode = buildHuffCodes(typeHuffRoot)

local function encodeValueHuffmanTree(node)
	if not node.type then
		write(1, 0)
		encodeValueHuffmanTree(node.node0)
		encodeValueHuffmanTree(node.node1)
	else
		local bits = typeToBits[node.type]
		local code = typeToCode[node.type]
		write(1, 1)
		print("encoding '" .. tostring(node.value) .. "' (" .. node.type .. ")")
		write(bits, code)
		if node.type == "_type" then
			local bits = typeToBits[node.value]
			local code = typeToCode[node.value]
			--print(node.value, bits, code)
			write(bits, code)
			--encodeString(write, node.value)
		elseif node.type == "table" then
			-- nothing yet
		else
			encodeValue(write, node.type, node.value)
		end
	end
end

local valueHuffRoot = buildHuffTree(references)

print("encoding value huffman tree")
encodeValueHuffmanTree(valueHuffRoot)

local valueToBits, valueToCode, typeToBits, typeToCode = buildHuffCodes(valueHuffRoot)

local tableEncoded = {}
local function encode(value)
	local type = subtypeof(value)
	local bits, code = valueToBits[value], valueToCode[value]

	-- easy to encodde
	if type ~= "table" then
		if bits then
			print("encoding reference " .. tostring(value) .. " (" .. type .. ")")
			write(bits, code)
		else -- this must be literally encoded
			print("encoding literal " .. tostring(value) .. " (" .. type .. ")")
			write(typeToBits[type], typeToCode[type])
			encodeValue(write, type, value)
		end
		return
	end

	if bits then
		print("encoding reference " .. tostring(value) .. " (" .. type .. ")")
		write(bits, code)
	else -- this is not referenced
		print("encoding literal " .. tostring(value) .. " (" .. type .. ")")
		write(typeToBits[type], typeToCode[type])
	end

	-- don't double encode things
	if tableEncoded[value] then return end
	tableEncoded[value] = true

	-- ok now encode everything
	local listCount = 0
	local hashCount = 0

	local nextIndex = 1
	for i, v in value do
		if i == nextIndex then
			nextIndex += 1
			listCount += 1
		else
			nextIndex = nil
			hashCount += 1
		end
	end

	encodeFib(write, listCount + 1)
	encodeFib(write, hashCount + 1)

	-- now encode for real
	local nextIndex = 1
	for i, v in value do
		if i == nextIndex then
			nextIndex += 1
			encode(v)
		else
			nextIndex = nil
			encode(i)
			encode(v)
		end
	end
end

print("encoding data")
encode(testData)

for value, code in valueToCode do
	local bits = valueToBits[value]
	print(bits, code, value)
end

for type, code in typeToCode do
	local bits = typeToBits[type]
	print(bits, code, type)
end
local numbers = {
	[0] = 44,
	[1] = 1560,
	[2] = 321,
	[3] = 163,
	[4] = 112,
	[5] = 89,
	[6] = 49,
	[7] = 39,
	[8] = 41,
	[9] = 27,
	[10] = 21,
	[11] = 17,
	[12] = 19,
	[13] = 12,
	[14] = 16,
	[15] = 16,
	[16] = 4,
	[17] = 7,
	[18] = 19,
	[19] = 12,
	[20] = 7,
	[21] = 11,
	[22] = 9,
	[23] = 7,
	[24] = 20,
	[25] = 9,
	[26] = 12,
	[27] = 5,
	[28] = 6,
	[29] = 13,
	[30] = 12,
	[31] = 5,
	[32] = 5,
	[33] = 4,
	[34] = 6,
	[35] = 4,
	[36] = 4,
	[37] = 13,
	[38] = 3,
	[39] = 3,
	[40] = 5,
	[41] = 5,
	[42] = 3,
	[43] = 3,
	[45] = 3,
	[46] = 5,
	[47] = 2,
	[49] = 2,
	[50] = 14,
	[51] = 4,
	[52] = 1,
	[53] = 1,
	[54] = 6,
	[55] = 4,
	[56] = 2,
	[57] = 1,
	[58] = 6,
	[59] = 3,
	[60] = 3,
	[62] = 3,
	[63] = 5,
	[64] = 1,
	[65] = 2,
	[68] = 3,
	[69] = 2,
	[70] = 3,
	[71] = 2,
	[72] = 4,
	[73] = 7,
	[74] = 2,
	[75] = 3,
	[76] = 1,
	[77] = 3,
	[80] = 6,
	[81] = 1,
	[82] = 2,
	[83] = 1,
	[87] = 2,
	[89] = 1,
	[90] = 3,
	[92] = 1,
	[93] = 1,
	[94] = 3,
	[95] = 2,
	[96] = 3,
	[98] = 1,
	[99] = 2,
	[100] = 5,
	[101] = 2,
	[103] = 3,
	[104] = 1,
	[105] = 1,
	[108] = 5,
	[113] = 3,
	[114] = 2,
	[115] = 1,
	[117] = 1,
	[124] = 2,
	[125] = 3,
	[127] = 1,
	[128] = 1,
	[129] = 2,
	[131] = 1,
	[132] = 1,
	[133] = 1,
	[134] = 1,
	[136] = 2,
	[139] = 1,
	[140] = 1,
	[141] = 2,
	[143] = 2,
	[144] = 2,
	[150] = 7,
	[153] = 2,
	[155] = 3,
	[156] = 1,
	[158] = 1,
	[161] = 1,
	[162] = 1,
	[163] = 1,
	[173] = 1,
	[175] = 1,
	[176] = 1,
	[177] = 1,
	[179] = 3,
	[182] = 2,
	[183] = 1,
	[185] = 4,
	[188] = 2,
	[190] = 2,
	[191] = 2,
	[193] = 1,
	[195] = 1,
	[203] = 2,
	[204] = 1,
	[206] = 1,
	[209] = 1,
	[211] = 2,
	[212] = 3,
	[216] = 1,
	[218] = 1,
	[223] = 1,
	[226] = 1,
	[229] = 1,
	[245] = 1,
	[246] = 1,
	[250] = 2,
	[254] = 1,
	[255] = 17,
	[256] = 1,
	[258] = 1,
	[259] = 1,
	[273] = 1,
	[275] = 1,
	[278] = 1,
	[279] = 1,
	[282] = 2,
	[296] = 1,
	[314] = 2,
	[315] = 1,
	[317] = 1,
	[328] = 1,
	[332] = 2,
	[335] = 1,
	[346] = 1,
	[357] = 1,
	[359] = 1,
	[368] = 2,
	[369] = 1,
	[375] = 1,
	[381] = 1,
	[403] = 1,
	[424] = 1,
	[466] = 1,
	[467] = 1,
	[469] = 1,
	[473] = 1,
	[490] = 1,
	[495] = 1,
	[497] = 3,
	[505] = 1,
	[511] = 1,
	[516] = 1,
	[530] = 2,
	[565] = 1,
	[577] = 1,
	[578] = 1,
	[597] = 1,
	[606] = 1,
	[614] = 1,
	[632] = 1,
	[636] = 2,
	[638] = 1,
	[647] = 2,
	[676] = 1,
	[692] = 1,
	[753] = 1,
	[780] = 3,
	[793] = 1,
	[795] = 1,
	[834] = 1,
	[840] = 1,
	[843] = 1,
	[897] = 1,
	[907] = 1,
	[916] = 1,
	[940] = 1,
	[942] = 1,
	[970] = 1,
	[975] = 1,
	[1025] = 1,
	[1037] = 1,
	[1141] = 1,
	[1151] = 1,
	[1220] = 1,
	[1230] = 1,
	[1274] = 1,
	[1361] = 1,
	[1425] = 1,
	[1448] = 1,
	[1475] = 1,
	[1570] = 1,
	[1776] = 1,
	[1875] = 1,
	[1957] = 1,
	[2095] = 1,
	[2145] = 1,
	[2221] = 1,
	[2299] = 1,
	[2749] = 1,
	[2886] = 1,
	[2977] = 1,
	[3055] = 1,
	[3780] = 1,
	[5769] = 1,
	[6067] = 1,
	[7249] = 1,
	[7432] = 1,
	[30086] = 1,
	[67007] = 1,
	[104384] = 1,
	[785741] = 1,
	[1712380515] = 1,
	[1712380519] = 1,
	[1712723248] = 1,
	[1712723396] = 1,
	[1712723572] = 1,
	[1722742788] = 1,
	[1722742814] = 1,
	[1722742912] = 1,
	[1722742930] = 1,
	[1722744045] = 1,
	[1722744699] = 1,
	[1722744715] = 1,
	[1732864405] = 1,
	[1732866208] = 2,
	[1732866238] = 1,
	[1732866312] = 1,
	[1732866347] = 1,
	[1732866540] = 1,
	[1732866749] = 1,
	[1732866786] = 1,
	[1732907606] = 1,
	[1732928150] = 1,
	[1732928282] = 1,
	[-0.0012846416448417] = 1,
	[-0.0177133017548904] = 1,
	[-0.04100065763111048] = 1,
	[-0.0537183083617557] = 1,
	[0.0125] = 1,
	[0.02770896987882962] = 1,
	[0.1] = 1,
	[0.2] = 1,
	[0.48] = 1,
	[0.5] = 16,
	[0.5600000000000001] = 1,
	[0.6666666666666666] = 4,
	[0.7] = 3,
	[0.71] = 1,
	[0.73] = 1,
	[0.75] = 1,
	[0.7678823838498239] = 1,
	[0.776964007789086] = 1,
	[0.7803473699954172] = 1,
	[0.8] = 5,
	[0.8037148589408544] = 1,
	[0.8054220654561209] = 1,
	[0.8250587334673353] = 1,
	[0.8326089786096527] = 1,
	[0.8443374222733204] = 1,
	[0.8462355585096563] = 1,
	[0.85] = 9,
	[0.8573731369493707] = 1,
	[0.8583706265582437] = 1,
	[0.8608328064632318] = 1,
	[0.8620942127536509] = 1,
	[0.8828591138574458] = 1,
	[0.9] = 6,
	[0.9072085010750459] = 1,
	[0.925] = 1,
	[0.9362154821260963] = 1,
	[0.95] = 6,
	[1.031] = 1,
	[1.05] = 1,
	[1.125] = 1,
	[1.5] = 1,
	[1.94] = 1,
	[1570509018.055852] = 1,
	[2.36] = 1,
	[2.4] = 1,
	[211801.1892658473] = 1,
	[275.9683501822874] = 1,
	[33.7377005631903] = 1,
	[36.9758958081378] = 1,
	[41.602] = 1,
	[419.5818833543453] = 1,
	[428.8334751110524] = 1,
	[49.987] = 1,
	[50.1] = 2,
	[50.35685889409837] = 1,
	[510.6301402738318] = 1,
	[645.8516799882054] = 1,
	[66.59504788423747] = 1,
	[66.6666666] = 1,
	[66.78071905112637] = 1,
	[682.2071027412312] = 1,
	[942.6393068917096] = 1,
}


--[[
0
1
fib -- positive integers > 1
double -- everything else

]]


local fibSeq = {}
local a0, a1 = 1, 1
for i = 1, 64 do
	--print(math.frexp(a1), a1)
	fibSeq[i] = a1
	a0, a1 = a1, a0 + a1
end
local maxFib = a1


local fibMem = {}
local function writeFib(n)
	-- if n >= maxFib then
	--     return
	-- end
	local c = 1
	for i, f in next, fibSeq do
		if f > n then
			c = i - 1
			--print(fibSeq[c])
			break
		end
	end

	for i = c, 1, -1 do
		local f = fibSeq[i]
		fibMem[i] = n >= f
		n //= f
	end

	-- for i = 1, c do
	-- 	print(fibMem[i])
	-- end
	return fibMem
end

local function readFib(fibMem)
	local n = 0
	local armed = false
	for i, f in next, fibSeq do
		local d = fibMem[i] and 1 or 0
		n += f*d
	end
	return n
end



--writeFib(5)

local total0 = 0
local total1 = 0

local function gFib(n)
	-- if n >= maxFib then
	--     return
	-- end
	local c = 1
	for i, f in next, fibSeq do
		if f > n then
			c = i - 1
			--print(fibSeq[c])
			break
		end
	end

	local freq = 1/2^(c + 1)
	total1 += freq

	for i = c, 1, -1 do
		local f = fibSeq[i]
		if n >= f then
			total1 += freq
		else
			total0 += freq
		end
		n //= f
	end

	-- for i = 1, c do
	-- 	print(fibMem[i])
	-- end
	--return fibMem
end



for n = 1, 10 do
	gFib(n)
	-- local things = writeFib(n)
	-- local bits = #things + 1
	-- local freq = 1/2^bits

	-- total1 += freq
	-- for i = 1, bits - 1 do
	-- 	if things[i] then
	-- 		total1 += freq
	-- 	else
	-- 		total0 += freq
	-- 	end
	-- end
end

print(total0, total1)

--[[
1 11
2 011
3 0011
4 1011
5 00011
]]


local function cost(n)
	--local f, e = math.frexp(n)
	--local _, g = math.frexp(e)
	--return 2^g + g + 1
	--return 2*e + 1
	--return 3 + 2^g
	local a0, a1 = 1, 1
	local c = 2
	while a0 + a1 <= n do
		a0, a1 = a1, a0 + a1
		c += 1
		--print(a0, a1)
	end
	return c
end

-- 11

local bits = {}
local totalCount = 0
local totalCost = 0
for n, c in numbers do
	if n%1 == 0 then
		totalCount += c
		if n == 0 then
			totalCost += c*cost(2)
		elseif n == 1 then
			totalCost += c*cost(1)
		else
			totalCost += c*cost(n + 1)
		end
	end

	--print(n, e)
end

print(totalCost/totalCount)

for i, v in bits do
	print(i, v)
end

-- local totalCount = 0
-- local totalCost = 0

-- local function classify(number)
--     local f, e = math.frexp(number)
--     if number == 0
-- end

-- print(totalCost/totalCount)



local frequencies = {
	{15, false, "a"},
	{12, false, "b"},
	{8, false, "c"},
	{6, false, "d"},
	{1, false, "e"},
}



local function buildDecodeTree(nodes)
	local n = #nodes
	for i = n - 1, 1, -1 do
		local node1 = table.remove(nodes)
		local node0 = table.remove(nodes)

		local freq = node0[1] + node1[1]
		local node = {freq, true, node0, node1}

		local pos = i + 1
		for k, nodeK in next, nodes do
			if nodeK[1] <= freq then
				pos = k
				break
			end
		end

		table.insert(nodes, pos, node)
	end
end

buildDecodeTree(frequencies)







local Huff = {}
Huff.__index = Huff

function Huff.new()
	local self = setmetatable({}, Huff)

	self.NYT = {
		count = 0;
		indexToValue = {};
		valueToIndex = {};
	} -- just make a table that contains 

	self._count = 0
	self._frequencies = {}
	self._order = {}

	self._total = 0
	self._nextRebuild = 1
	self._rebuildRatio = 2

	self._treeRoot = nil
	self._valueToCode = {}
	self._valueToBits = {}
	self:rebuild()

	return self
end

function Huff:addSample(value)
	local current = self._frequencies[value]
	if current then
		self._frequencies[value] = current + 1
	else
		self._count += 1
		self._frequencies[value] = 1
		self._order[value] = self._count

		self.NYT.indexToValue[self.NYT.count] = value -- index at 0
		self.NYT.valueToIndex[value] = self.NYT.count
		self.NYT.count += 1
	end

	self._total += 1
	--print(self._total, self._nextRebuild)
	if self._total == self._nextRebuild then
		self._nextRebuild = -(-self._nextRebuild*self._rebuildRatio//1)
		self:rebuild()
	end
end

--local buff = buffer.create(10)

-- returns true if the value was not able to be encoded
function Huff:encode(write, value)
	local code = self._valueToCode[value]
	local bits = self._valueToBits[value]

	print("writing", value)
	if code then
		write(bits, code)
		--self:addSample(value)
		return true
	else
		local code = self._valueToCode[self.NYT]
		local bits = self._valueToBits[self.NYT]
		write(bits, code, "NYT")

		local index = self.NYT.valueToIndex[value]
		local _, ibits = math.frexp(self.NYT.count)
		if index then
			write(ibits, index)
			--self:addSample(value)
			return true
		else
			write(ibits, self.NYT.count, "new")
			--self:addSample(value)
			return false -- could not encode
		end
	end
end

-- returns true if the value was not able to be decoded
function Huff:decode(read)
	local node = self._treeRoot
	print("begin")
	while true do
		if node[3] then -- is not a leaf
			local bit = read(1)
			if bit == 0 then -- left
				print("branch 0")
				node = node[4]
			else -- right
				print("branch 1")
				node = node[5]
			end
		else
			local value = node[4]
			if value == self.NYT then
				local _, ibits = math.frexp(self.NYT.count)
				local index = read(ibits)
				if index == self.NYT.count then
					print("NYT new")
					return false -- could not read, must call addSample
				else
					print("NYT read", value)
					return true, self.NYT.indexToValue[index]
				end
			else
				print("read", value)
				return true, value
			end
		end 
	end
end

function Huff:rebuild()
	self:rebuildTree()
	self:rebuildCodes()
	self.NYT.count = 0
	table.clear(self.NYT.indexToValue)
	table.clear(self.NYT.valueToIndex)
end

local function compareNodes(nodeA, nodeB)
	if nodeA[1] == nodeB[1] then
		return nodeA[2] < nodeB[2]
	else
		return nodeA[1] > nodeB[1]
	end
end

function Huff:rebuildTree()
	--print("building")
	local nodes = {}

	for value, freq in self._frequencies do
		local order = self._order[value]
		table.insert(nodes, {freq, order, false, value})
	end

	table.insert(nodes, {1, 0, false, self.NYT})
	table.sort(nodes, compareNodes)

	local n = self._count + 1
	for i = n - 1, 1, -1 do
		local node1 = table.remove(nodes)
		local node0 = table.remove(nodes)

		local freq = node0[1] + node1[1]
		local order = math.min(node0[2], node1[2])
		local node = {freq, order, true, node0, node1}

		local pos = i
		for k, nodeK in next, nodes do
			if not compareNodes(nodeK, node) then
				pos = k
				break
			end
		end

		table.insert(nodes, pos, node)
	end

	self._treeRoot = nodes[1]
end

local function buildCodesRecurse(valueToCode, valueToBits, node, code, bits)
	if node[3] then
		buildCodesRecurse(valueToCode, valueToBits, node[4], code + 2^bits*0, bits + 1)
		buildCodesRecurse(valueToCode, valueToBits, node[5], code + 2^bits*1, bits + 1)
	else
		valueToCode[node[4]] = code
		valueToBits[node[4]] = bits
		--print(code,bits)
	end
end

function Huff:rebuildCodes()
	table.clear(self._valueToCode)
	table.clear(self._valueToBits)
	buildCodesRecurse(self._valueToCode, self._valueToBits, self._treeRoot, 0, 0)
end


local whead = 0
local rhead = 0
local buff = buffer.create(1000)
local function write(bits, code)
	buffer.writebits(buff, whead, bits, code)
	whead += bits
end

local function read(bits)
	local code = buffer.readbits(buff, rhead, bits)
	rhead += bits
	return code
end

local huffI = Huff.new()
local huffO = Huff.new()

local nums = {1, 2, 3, 1, 2, 1}
for i, value in nums do
	local success = huffI:encode(write, value)
	huffI:addSample(value)
	if not success then
		write(8, value)
	end
end

for i = 1, 6 do
	local success, value = huffO:decode(read)
	if not success then
		value = read(8)
	end
	huffO:addSample(value)
	--print(value)
end




--buffer.writebits(buff, 0, 10, 7)
--print(buffer.readbits(buff, 0, 3))


-- local predictors = {}
-- for i = 0, 255 do
-- 	predictors[i] = Huff.new()
-- end

-- local nullPredictor = Huff.new()

-- local huff = Huff.new()

-- local totalBits = 0
-- local write = function(bits, code, ...)
-- 	local bstr = ""
-- 	for i = 1, bits do
-- 		bstr ..= code%2
-- 		code //= 2
-- 	end
-- 	totalBits += bits
-- 	print(bits, bstr, ...)
-- end


-- ASCII string vs binary string.
-- binary string is anything that contans values outside the range
local str = "Hello! How are you doing today, this is an example of some english being written into a string. I am using this as an example because I feel that there will be many repeated words and things in here, just as there will be many repeated words and things in actual variables and text in data."

-- for i = 1, #str do
-- 	local c = string.sub(str, i, i)
-- 	local writeRaw = huff:encode(write, c)
-- 	if writeRaw then
-- 		totalBits += 8
-- 	end
-- 	-- huff:rebuild()
-- 	-- for i, v in huff._valueToCode do
-- 	-- 	print(i[4], v)
-- 	-- end
-- end
-- print(totalBits)
-- print(#str*8)


-- ASCII string vs binary string.
-- binary string is anything that contans values outside the range
local str = "Hello! How are you doing today, this is an example of some english being written into a string. I am using this as an example because I feel that there will be many repeated words and things in here, just as there will be many repeated words and things in actual variables and text in data."
-- print(#str)
-- for n = 1, 10 do
-- 	local predictor = nullPredictor -- start
-- 	for i = 1, #str do
-- 		local c = string.sub(str, i, i)
-- 		local writeRaw = predictor:encode(write, c)
-- 		if writeRaw then
-- 			local writeRaw = huff:encode(write, c)
-- 			if writeRaw then
-- 				totalBits += 8
-- 			end
-- 		else
-- 			huff:addSample(c)
-- 		end
-- 		predictor = predictors[string.byte(c)]
-- 		-- huff:rebuild()
-- 		-- for i, v in huff._valueToCode do
-- 		-- 	print(i[4], v)
-- 		-- end
-- 	end
-- end
-- 	print(totalBits)
-- 	print(totalBits/(#str*8*10))

--local root = huff:rebuildTree()
--local codes = buildCodes(root)

-- for i, v in codes do
-- 	print(i[4], v)
-- end


-- local function rebuildTree(freq)
-- 	local n = #freq
-- 	for k = n - 1, 1, -1 do
-- 		local dat1 = table.remove(freq)
-- 		local dat0 = table.remove(freq)

-- 		local dat = {{dat0[1], dat1[1]}, dat0[2] + dat1[2]}

-- 		table.insert(freq, dat)

-- 		for i = k - 1, 1, -1 do
-- 			if freq[i][2] < freq[i + 1][2] then
-- 				freq[i], freq[i + 1] = freq[i + 1], freq[i]
-- 			else
-- 				break
-- 			end
-- 		end

-- 		print("")
-- 		for i, v in frequencies do
-- 			print(i, v[1], v[2])
-- 		end
-- 	end
-- end

-- rebuildTree(frequencies)


-- print(frequencies[1][1][1][1][2][2])
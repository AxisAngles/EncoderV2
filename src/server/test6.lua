-- total*log(total) - sum(freq*log(freq))

-- (total + freq)*log(total + freq) - total*log(total) - freq*log(freq)


-- cost of incorporating into the 



-- each time you turn a leaf into a branch,
-- remove a leaf
-- add a branch
-- add two more leaves
-- + leaf + branch
-- start with 1 leaf
-- if you have 10 leaves, you will have 9 branches


local ln2 = math.log(2)
local function partialEntropy(x)
	if x == 0 then return 0 end
	return x*math.log(x)/ln2--
	--return x*select(2, math.frexp(x))--
end

-- cost of going from literal to reference
local function litToRefCost(typeFreq, freq, cost)
	return
		- partialEntropy(typeFreq - freq) -- adding the new type cost
		- partialEntropy(freq) -- adding the new cost of encoding a reference 
		+ cost -- adding the one time encoding cost
		+ 2 -- extra encoding cost

		+ partialEntropy(typeFreq) -- removing the old type cost
		- freq*cost -- removing the multi-time encoding cost
end

-- cost of going from reference to literal
local function refToLitCost(typeFreq, freq, cost)
	return
		- partialEntropy(typeFreq + freq) -- adding the new type cost
		+ freq*cost -- adding the multi-time encoding cost

		+ partialEntropy(typeFreq) -- removing the old type cost
		+ partialEntropy(freq) -- removing the old cost of encoding a reference
		- cost -- removing the one time encoding cost
		- 2 -- no more encoding cost for the reference
end



local typeToFreq = {}
local literals = {}
local references = {}

local function newLiteral(name, type, freq, cost)
	local literal = {
		name = name;
		type = type;
		freq = freq;
		cost = cost;
	}

	table.insert(literals, literal)
	typeToFreq[type] = (typeToFreq[type] or 0) + freq

	return literal
end

--log(range)*8

-- discovery!
--[[

	frequency distributions raised to any power result in a similar

]]

for i = 1, 2000 do
	local freq = 2^math.random(0, 5)
	local cost = math.random(1, 200)
	local type = math.random(1, 2)
	local name = freq .. "/" .. cost
	newLiteral(name, type, freq, cost)
end


--newLiteral("1000/3", type, freq, cost)

-- newLiteral("a", "string", 4, 8)
-- newLiteral("b", "string", 2, 8)
-- newLiteral("ab", "string", 2, 16)

-- balance
local function getBestLitToRefMove()
	local bestI
	local bestCost = 0
	--print("litToRef costs")
	for i, lit in literals do
		local typeFreq = typeToFreq[lit.type]
		local moveCost = litToRefCost(typeFreq, lit.freq, lit.cost)
		if moveCost < bestCost then
			bestI = i
			bestCost = moveCost
		end
		--print(lit.name, litToRefCost(typeFreq, lit.freq, lit.cost))
	end

	return bestI, bestCost
end

local function getBestRefToLitMove()
	local bestI
	local bestCost = 0
	--print("refToLit costs")
	for i, lit in references do
		local typeFreq = typeToFreq[lit.type]
		local moveCost = refToLitCost(typeFreq, lit.freq, lit.cost)
		if moveCost < bestCost then
			bestI = i
			bestCost = moveCost
		end
		--print(lit.name, refToLitCost(typeFreq, lit.freq, lit.cost))
	end

	return bestI, bestCost
end




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

local function computeTrueCost(valueToFrequency)
	local valueToFrequency = {}

	local cost = 1

	for i, lit in references do
		valueToFrequency[lit] = lit.freq
		cost += lit.cost
		cost += 2
	end

	for i, lit in literals do
		cost += lit.freq*lit.cost
	end

	for type, freq in typeToFreq do
		valueToFrequency[type] = freq
	end

	local huffRoot = buildHuffTree(valueToFrequency)
	local valueToBits, valueToCode = buildHuffCodes(huffRoot)

	for value, freq in valueToFrequency do
		local bits = valueToBits[value]
		cost += freq*bits
	end

	return cost
end

local function computeTotalCost()
	local cost = 1
	local totalFreq = 0
	for i, lit in references do
		cost -= partialEntropy(lit.freq)
		cost += 2
		cost += lit.cost
		totalFreq += lit.freq
	end

	for i, lit in literals do
		cost += lit.cost*lit.freq
	end

	for i, freq in typeToFreq do
		cost -= partialEntropy(freq)
		totalFreq += freq
	end

	cost += partialEntropy(totalFreq)

	return cost
end












local function iterateRebalance()
	for i = #literals, 1, -1 do
		local lit = literals[i]

		local typeFreq = typeToFreq[lit.type]
		local moveCost = litToRefCost(typeFreq, lit.freq, lit.cost)
		if moveCost >= 0 then continue end

		--local value = table.remove(literals, i)
		table.insert(references, lit)
		literals[i] = table.remove(literals)
		typeToFreq[lit.type] -= lit.freq
		--print("moving lit to ref", moveCost)
	end

	for i = #references, 1, -1 do
		local lit = references[i]

		local typeFreq = typeToFreq[lit.type]
		local moveCost = refToLitCost(typeFreq, lit.freq, lit.cost)
		if moveCost >= 0 then continue end

		local value = table.remove(references, i)
		table.insert(literals, value)
		typeToFreq[value.type] += value.freq
		print("!!!!!!!!!!!!!!!!!!", moveCost)
	end
end




print(computeTrueCost(), #literals, #references)
for i = 1, 10 do
	print("ATTEMPT", i)
	iterateRebalance()
	print(computeTrueCost(), #literals, #references)
end


for i = 1, 1000 do
	--print(computeTotalCost())
	--print(computeTrueCost(valueToFrequency))
	-- table.sort(literals, function(litA, litB)
	-- 	local moveCostA = litToRefCost(typeToFreq[litA.type], litA.freq, litA.cost)
	-- 	local moveCostB = litToRefCost(typeToFreq[litB.type], litB.freq, litB.cost)
	-- 	return moveCostA > moveCostB
	-- end)
	-- table.sort(references, function(litA, litB)
	-- 	local moveCostA = refToLitCost(typeToFreq[litA.type], litA.freq, litA.cost)
	-- 	local moveCostB = refToLitCost(typeToFreq[litB.type], litB.freq, litB.cost)
	-- 	return moveCostA > moveCostB
	-- end)
	-- local printStr = "lit: "
	-- for i, lit in literals do
	-- 	printStr ..= " " .. lit.name
	-- end
	-- print(printStr)
	-- local printStr = "ref: "
	-- for i, lit in references do
	-- 	printStr ..= " " .. lit.name
	-- end
	-- print(printStr)

	--local bestLitI, bestLitCost = getBestLitToRefMove()
	--local bestRefI, bestRefCost = getBestRefToLitMove()
	-- if bestRefI then
	-- 	print("WHOA")
	-- end
	--print(#literals)
	--print(bestLitI, bestRefI, bestLitCost)
	-- if bestLitI and bestRefI then
	-- 	if bestLitCost < bestRefCost then
	-- 		cost += bestLitCost
	-- 		local value = table.remove(literals, bestLitI)
	-- 		table.insert(references, value)
	-- 		typeToFreq[value.type] -= value.freq
	-- 	else
	-- 		local value = table.remove(references, bestRefI)
	-- 		table.insert(literals, value)
	-- 		typeToFreq[value.type] += value.freq
	-- 	end
	-- elseif bestLitI then
	-- 	local value = table.remove(literals, bestLitI)
	-- 	table.insert(references, value)
	-- 	typeToFreq[value.type] -= value.freq
	-- elseif bestRefI then
	-- 	local value = table.remove(references, bestRefI)
	-- 	table.insert(literals, value)
	-- 	typeToFreq[value.type] += value.freq
	-- else
	-- 	print("done")
	-- 	break
	-- end
end



--[[
	a:  8  bits 4x
	b:  8  bits 2x
	ab: 16 bits 2x


	a b ab (00000000 00000001 0000000000000001)
	a a a a b b ab ab (0 0 0 0 10 10 11 11)
	total: 44

	vs

	a b lit (00000000 00000001) -- hmm there's actually an encoding cost for the literal
	a a a a b b lit ab lit ab (0 0 0 0 10 10 11 0000000000000001 11 0000000000000001)
	total: 60

	vs

	a lit (00000000) -- hmm there's actually an encoding cost for the literal
	a a a a lit b lit b lit ab lit ab (0 0 0 0 1 00000001 1 00000001 1 0000000000000001 1 0000000000000001)
	total: 64
]]

-- print(refToLitCost(0, 2, 16))
-- print(refToLitCost(2, 2, 8))



print(typeof == type)
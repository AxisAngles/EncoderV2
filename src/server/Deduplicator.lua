local function roll(n, d)
	return 48271*(n + d)%(2^31 - 1)
end

local function hashBuffer(buff, orig, bits)
	local hash = 0
	local inc = 32
	while bits > inc do
		hash = roll(hash, buffer.readbits(buff, orig, inc))
		orig += inc
		bits -= inc
	end
	hash = roll(hash, buffer.readbits(buff, orig, bits))
	return hash
end

local function compareBuffer(
	buffA, origA, bitsA,
	buffB, origB, bitsB
)
	if bitsA ~= bitsB then
		return false
	end

	local bits = bitsA
	while bits > 32 do
		local codeA = buffer.readbits(buffA, origA, 32)
		local codeB = buffer.readbits(buffB, origB, 32)
		if codeA ~= codeB then
			return false
		end

		origA += 32
		origB += 32
		bits  -= 32
	end

	local codeA = buffer.readbits(buffA, origA, bits)
	local codeB = buffer.readbits(buffB, origB, bits)
	return codeA == codeB
end



local Deduplicator = {}
Deduplicator.__index = Deduplicator

function Deduplicator.new()
	local self = setmetatable({}, Deduplicator)

	self._typeToHashToHitList = {}
	self._valueToHit = {}

	return self
end

local isDistinct = {
	["nil"] = true;
	["boolean"] = true;
	["number"] = true;
	["string"] = true;
	["table"] = true;
	["Vector3"] = true;
	["vector"] = true;
}


-- returns the first matching value ever indexed
function Deduplicator:index(value, buff, orig, bits)
	local type = typeof(value)
	if isDistinct[type] then
		return value
	end

	local hit = self._valueToHit[value]
	if hit then
		return hit.value
	end

	if not (buff and orig and bits) then
		error("must pass buff orig and bits if value not yet indexed")
	end

	local hashToHitList = self._typeToHashToHitList[type]
	if not hashToHitList then
		hashToHitList = {}
		self._typeToHashToHitList[type] = hashToHitList
	end

	local hash = hashBuffer(buff, orig, bits)
	local hitList = hashToHitList[hash]
	if not hitList then
		hitList = {}
		hashToHitList[hash] = hitList
	end

	for i, hit in hitList do
		local match = compareBuffer(hit.buff, hit.orig, hit.bits, buff, orig, bits)
		if match then
			return hit.value
		end
	end
	-- no match
	local hit = {
		value = value;
		buff = buff;
		orig = orig;
		bits = bits;
	}

	self._valueToHit[value] = hit
	table.insert(hitList, hit)

	return value
end


--print(typeof(vector.create(1, 2, 3)))

-- local buff = buffer.create(2)
-- buffer.writeu8(buff, 0, 10)
-- buffer.writeu8(buff, 1, 10)

-- local deduplicator = Deduplicator.new()

-- print(deduplicator:index(0, buff, 0, 8))
-- print(deduplicator:index(1, buff, 8, 8))

return Deduplicator

-- local buff = buffer.create(8)

-- buffer.writebits(buff,  0, 8, 0)
-- buffer.writebits(buff,  8, 8, 1)
-- buffer.writebits(buff, 16, 8, 2)
-- buffer.writebits(buff, 24, 8, 3)
-- buffer.writebits(buff, 32, 8, 4)
-- buffer.writebits(buff, 40, 8, 5)
-- buffer.writebits(buff, 48, 8, 6)
-- buffer.writebits(buff, 56, 8, 7)

-- print(hashBuffer(buff, 0, 64))
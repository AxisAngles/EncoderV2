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
			self._valueToHit[value] = hit
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

return Deduplicator
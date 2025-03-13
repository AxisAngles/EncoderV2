local BitBuffer = {}

local Writer = {}
Writer.__index = Writer

local Reader = {}
Reader.__index = Reader

local function getCaller(detailFunction, level)
	level = (level or 2) + 1

	local file, name, line, func, args, variadic = debug.info(level, "snlfa")
	if not file then
		return "level out of bounds"
	end

	local fileString = string.match(file, "[^/]*$")
	if detailFunction then
		local argList = {}
		for i = 1, args do table.insert(argList, "_") end
		if variadic then table.insert(argList, "...") end
		local argString = table.concat(argList, ", ")

		return fileString .. ":" .. line .. " function " .. name .. "(" .. argString .. ")"
	else
		return fileString .. ":" .. line
	end
end

function Writer.new()
	local self = setmetatable({}, Writer)
	self._totalLen = 0

	self._buffs = {}
	self._buff = buffer.create(1)
	self._head = 0
	self._len = 8*buffer.len(self._buff)
	self._origin = getCaller()

	return self
end

function Writer:__tostring()
	return "BitWriter(" .. self._totalLen .. "): " .. self._origin
end

function Writer:getHead()
	return self._totalLen
end

function Reader.new(buff)
	local self = setmetatable({}, Reader)
	self._totalLen = 8*buffer.len(buff)

	self._buff = buff
	self._head = 0
	self._origin = getCaller()

	return self
end

function Reader:__tostring()
	return "BitReader(" .. self._head .. "/" .. self._totalLen .. "): " .. self._origin
end

function Reader:getHead()
	return self._head
end








-- Bits
function Writer:write(bits, code)
	-- local str = ""
	-- local n = code
	-- for i = 1, bits do
	-- 	str ..= n%2
	-- 	n //= 2
	-- end
	-- print(str)
	self._totalLen += bits

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

function Writer:dump()
	local length = -(-self._totalLen//8)

	local dumpBuff = buffer.create(length)
	local head = 0
	for i, buff in self._buffs do
		buffer.copy(dumpBuff, head, buff)
		head += buffer.len(buff)
	end

	buffer.copy(dumpBuff, head, self._buff, 0, -(-self._head//8))

	return dumpBuff
end

function Reader:read(bits)
	local code = buffer.readbits(self._buff, self._head, bits)
	self._head += bits

	-- local str = ""
	-- local n = code
	-- for i = 1, bits do
	-- 	str ..= n%2
	-- 	n //= 2
	-- end
	-- print(str)

	return code
end








-- Fibonacci positive integer coding
local fibSeq = {}
local a0, a1 = 1, 1

for i = 1, 32 do
	a0, a1 = a1, a0 + a1
	fibSeq[i] = a0
end

Reader.maxFib = a1 - 1 -- ehh why not
Writer.maxFib = a1 - 1

function Writer:writeFib(n)
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

function Reader:readFib()
	local n = 0
	local armed = false
	for i, f in next, fibSeq do
		local d = self:read(1)
		if armed and d == 1 then
			return n
		end
		armed = d == 1
		n += f*d
	end
end








-- Binary Strings
function Writer:writeString(value, len)
	for i = 1, len or #value do
		self:write(8, string.byte(value, i))
	end
end

function Reader:readString(len)
	local strbuff = buffer.create(len)
	for i = 0, len - 1 do
		buffer.writeu8(strbuff, i, self:read(8))
	end

	return buffer.tostring(strbuff)
end








-- Huffman trees
function Writer:writeCode(tree, node)
	local bits = tree.leafToBits[node]
	local code = tree.leafToCode[node]
	if bits then
		self:write(bits, code)
		return true
	else
		return false
	end
end

--TODO: convert to take tree argument instead of root?
function Reader:readCode(root)
	local node = root
	while node.node0 do -- while it's a branch
		local branch = self:read(1)
		if branch == 0 then
			node = node.node0
		else
			node = node.node1
		end
	end

	return node
end

BitBuffer.Writer = Writer
BitBuffer.Reader = Reader

return BitBuffer
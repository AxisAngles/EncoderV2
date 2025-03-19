local Base64Converter = {}

local digits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+-"
local map = {}
local inv = {}
for i = 1, #digits do
	local c = string.byte(digits, i)
	map[i - 1] = c
	inv[c] = i - 1
end

function Base64Converter.toBuffer256(str)
	local strLen = #str
	local bufLen = -(-6*strLen//8) -- integer division rounding up instead of down
	local buf = buffer.create(bufLen)

	-- 12 full bytes at a time
	for i = 16, strLen, 16 do
		local
			c0, c1, c2, c3, -- 24 bits/row
			c4, c5, c6, c7,
			c8, c9, ca, cb,
			cc, cd, ce, cf = string.byte(str, i - 15, i)

		local i0 = inv[c0]      + 2^6*inv[c1] + 2^12*inv[c2] + 2^18*inv[c3] + 2^24*inv[c4] + 2^30*inv[c5]
		local i1 = inv[c5]//2^2 + 2^4*inv[c6] + 2^10*inv[c7] + 2^16*inv[c8] + 2^22*inv[c9] + 2^28*inv[ca]
		local i2 = inv[ca]//2^4 + 2^2*inv[cb] + 2^8 *inv[cc] + 2^14*inv[cd] + 2^20*inv[ce] + 2^26*inv[cf]
		local index = (i/16 - 1)*12
		buffer.writeu32(buf, index    , i0)
		buffer.writeu32(buf, index + 4, i1)
		buffer.writeu32(buf, index + 8, i2)
	end

	for i = strLen//16*16 + 1, strLen do
		local c0 = string.byte(str, i)
		local v0 = inv[c0]
		buffer.writebits(buf, 6*(i - 1), 6, v0)
	end

	return buf
end

-- function Base64Converter.fromBuffer256_1(buf)
-- 	local bufLen = buffer.len(buf)
-- 	local strLen = -(-8*bufLen//6) -- integer division rounding up instead of down
-- 	local str = buffer.create(strLen)

-- 	for i = 12, bufLen, 12 do
-- 		local i0 = buffer.readu32(buf, i - 12)
-- 		local i1 = buffer.readu32(buf, i -  8)
-- 		local i2 = buffer.readu32(buf, i -  4)
-- 		local index = (i/12 - 1)*16
-- 		buffer.writeu8(str, index + 0,  map[i0      %2^6])
-- 		buffer.writeu8(str, index + 1,  map[i0//2^6 %2^6])
-- 		buffer.writeu8(str, index + 2,  map[i0//2^12%2^6])
-- 		buffer.writeu8(str, index + 3,  map[i0//2^18%2^6])

-- 		buffer.writeu8(str, index + 4,  map[i0//2^24%2^6])
-- 		buffer.writeu8(str, index + 5,  map[i0//2^30     + 2^2*i1%2^6])
-- 		buffer.writeu8(str, index + 6,  map[i1//2^4 %2^6])
-- 		buffer.writeu8(str, index + 7,  map[i1//2^10%2^6])

-- 		buffer.writeu8(str, index + 8,  map[i1//2^16%2^6])
-- 		buffer.writeu8(str, index + 9,  map[i1//2^22%2^6])
-- 		buffer.writeu8(str, index + 10, map[i1//2^28     + 2^4*i2%2^6])
-- 		buffer.writeu8(str, index + 11, map[i2//2^2 %2^6])

-- 		buffer.writeu8(str, index + 12, map[i2//2^8 %2^6])
-- 		buffer.writeu8(str, index + 13, map[i2//2^14%2^6])
-- 		buffer.writeu8(str, index + 14, map[i2//2^20%2^6])
-- 		buffer.writeu8(str, index + 15, map[i2//2^26%2^6])
-- 	end


-- 	for i = bufLen//12*12*8, 8*bufLen, 6 do
-- 		local v = buffer.readbits(buf, i - 6, 6)
-- 		buffer.writeu8(str, i/6 - 1, map[v])
-- 	end

-- 	local blen = 8*bufLen
-- 	local bits = blen%6
-- 	local orig = blen - bits

-- 	-- probably a prettier way to do this
-- 	if bits > 0 then
-- 		local v = buffer.readbits(buf, orig, bits)
-- 		buffer.writeu8(str, strLen - 1, map[v])
-- 	end

-- 	return buffer.tostring(str)
-- end

-- function Base64Converter.fromBuffer256_2(buf)
-- 	local bufLen = buffer.len(buf)
-- 	local strLen = -(-8*bufLen//6) -- integer division rounding up instead of down
-- 	local str = buffer.create(strLen)

-- 	-- 6 bits at a time
-- 	--print(8*bufLen)
-- 	for i = 6, 8*bufLen, 6 do
-- 		local v = buffer.readbits(buf, i - 6, 6)
-- 		buffer.writeu8(str, i/6 - 1, map[v])
-- 	end

-- 	local blen = 8*bufLen
-- 	local bits = blen%6
-- 	local orig = blen - bits

-- 	-- probably a prettier way to do this
-- 	if bits > 0 then
-- 		local v = buffer.readbits(buf, orig, bits)
-- 		buffer.writeu8(str, strLen - 1, map[v])
-- 	end

-- 	return buffer.tostring(str)
-- end

function Base64Converter.fromBuffer256(buf)
	local blen = 8*buffer.len(buf)
	local slen = -(-blen//6)
	local str = buffer.create(slen)

	local bit0 = 0
	local bit1 = blen//96*96
	local bit2 = blen//6*6
	local bit3 = blen

	local head = 0

	--  12 bytes at a time
	for i = bit0/8, bit1/8 - 12, 12 do
		local i0 = buffer.readu32(buf, i    )
		local i1 = buffer.readu32(buf, i + 4)
		local i2 = buffer.readu32(buf, i + 8)
		buffer.writeu8(str, head    ,  map[i0      %2^6])
		buffer.writeu8(str, head + 1,  map[i0//2^6 %2^6])
		buffer.writeu8(str, head + 2,  map[i0//2^12%2^6])
		buffer.writeu8(str, head + 3,  map[i0//2^18%2^6])

		buffer.writeu8(str, head + 4,  map[i0//2^24%2^6])
		buffer.writeu8(str, head + 5,  map[i0//2^30     + 2^2*i1%2^6])
		buffer.writeu8(str, head + 6,  map[i1//2^4 %2^6])
		buffer.writeu8(str, head + 7,  map[i1//2^10%2^6])

		buffer.writeu8(str, head + 8,  map[i1//2^16%2^6])
		buffer.writeu8(str, head + 9,  map[i1//2^22%2^6])
		buffer.writeu8(str, head + 10, map[i1//2^28     + 2^4*i2%2^6])
		buffer.writeu8(str, head + 11, map[i2//2^2 %2^6])

		buffer.writeu8(str, head + 12, map[i2//2^8 %2^6])
		buffer.writeu8(str, head + 13, map[i2//2^14%2^6])
		buffer.writeu8(str, head + 14, map[i2//2^20%2^6])
		buffer.writeu8(str, head + 15, map[i2//2^26%2^6])
		head += 16
	end

	for i = bit1, bit2 - 6, 6 do
		local v = buffer.readbits(buf, i, 6)
		buffer.writeu8(str, head, map[v])
		head += 1
	end

	if bit2 < bit3 then
		local v = buffer.readbits(buf, bit2, bit3 - bit2)
		buffer.writeu8(str, head, map[v])
		head += 1
	end

	return buffer.tostring(str)
end


-- local str = "0123456789abcdefghijklmnopqrs0123456789ab"
-- -- for i = 1, 1000000, 64 do
-- -- 	str ..= digits
-- -- end

-- for i = 1, 10 do
-- 	str = Base64Converter.fromBuffer256(Base64Converter.toBuffer256(str))
-- 	print(str)
-- end

-- print(#str)

-- local t0 = os.clock()
-- local value = Base64Converter.toBuffer256(str)
-- local t1 = os.clock()
-- Base64Converter.fromBuffer256_3(value)
-- local t2 = os.clock()
-- Base64Converter.fromBuffer256_2(value)
-- local t3 = os.clock()
-- Base64Converter.fromBuffer256_1(value)
-- local t4 = os.clock()
-- print(t1 - t0)
-- print(t2 - t1)
-- print(t3 - t2)
-- print(t4 - t3)

--[[


]]

-- from buffer256 to string64
-- 100000100000100000100000
-- 100000001000000010000000
--[[
read in steps of 3 bytes?
maybe 6
maybe 12 bytes, 96 bits?


local blen = 8*bufLen

local bit0 = 0
local bit1 = blen//96*96
local bit2 = blen//6*6
local bit3 = blen

local head = 0

--  12 bytes at a time
for i = bit0/8, bit1/8 - 12, 12 do
	local i0 = buffer.readu32(buf, i    )
	local i1 = buffer.readu32(buf, i + 4)
	local i2 = buffer.readu32(buf, i + 8)
	buffer.writeu8(str, index    ,  map[i0      %2^6])
	buffer.writeu8(str, index + 1,  map[i0//2^6 %2^6])
	buffer.writeu8(str, index + 2,  map[i0//2^12%2^6])
	buffer.writeu8(str, index + 3,  map[i0//2^18%2^6])

	buffer.writeu8(str, index + 4,  map[i0//2^24%2^6])
	buffer.writeu8(str, index + 5,  map[i0//2^30     + 2^2*i1%2^6])
	buffer.writeu8(str, index + 6,  map[i1//2^4 %2^6])
	buffer.writeu8(str, index + 7,  map[i1//2^10%2^6])

	buffer.writeu8(str, index + 8,  map[i1//2^16%2^6])
	buffer.writeu8(str, index + 9,  map[i1//2^22%2^6])
	buffer.writeu8(str, index + 10, map[i1//2^28     + 2^4*i2%2^6])
	buffer.writeu8(str, index + 11, map[i2//2^2 %2^6])

	buffer.writeu8(str, index + 12, map[i2//2^8 %2^6])
	buffer.writeu8(str, index + 13, map[i2//2^14%2^6])
	buffer.writeu8(str, index + 14, map[i2//2^20%2^6])
	buffer.writeu8(str, index + 15, map[i2//2^26%2^6])
	head += 16
end

for i = bit1, bit2 - 6, 6 do
	local v = buffer.readbits(buf, i, 6)
	buffer.writeu8(str, head, map[v])
	head += 1
end

if bit2 < bit3 then
	local v = buffer.readu32(buf, bit2, bit3 - bit2)
	buffer.writeu8(str, head, map[v])
	head += 1
end

AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDD
aaaaaabbbbbbccccccddddddeeeeeeffffffgggggghhhhhhiiiiiijjjjjjkkkkkkllllllmmmmmmnnnnnnooooooppppppqqqqqqrrrrrr
]]


-- local i0 = buffer.readu32(buf, i + 0)
-- local i1 = buffer.readu32(buf, i + 4)
-- local i2 = buffer.readu32(buf, i + 4)
-- 	2^32*buffer.readu16(buf, i + 4)

-- v//2^6




-- local b = buffer.create(1)
-- buffer.writebits(b, 0, 8, 255)
-- print(Base64Converter.fromBuffer256(b))

return Base64Converter
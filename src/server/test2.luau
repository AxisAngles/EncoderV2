local lower = 0
local range = 2^4
local maxRange = 2^4

local function tobinarystring(n)
	-- if n == 0 then
	-- 	return "0"
	-- end

	local p = math.abs(n)
	local s = ""
	local c = maxRange
	while c > 1 do
		c //= 2
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

local _print = print
local function print(...)
	local n = select("#", ...)
	local args = {...}
	for i = 1, n do
		local v = args[i]
		if type(v) == "number" and v%1 == 0 then
			args[i] = tobinarystring(v)
		end
	end

	_print(unpack(args, 1, n))
end

local bstr = ""
local buff = buffer.create(1000)
local whead = 0
local function writebit(value)
	bstr ..= value
	buffer.writebits(buff, whead, 1, value)
	whead += 1
end

local function encode(c, l, r)
	while range < c do
		print("AAAAAA", tostring(range), tostring(c))
		writebit(2*lower // maxRange)
		range *= 2
		lower = 2*lower%maxRange
	end
	---[[
	range //= c
	lower  += l*range
	range  *= r
	--[=[
	--]]
	lower  += range*l//c
	range   = range*r//c
	--]=]

	--print((lower + range))--//(maxRange//2))
	--print(lower, "-", (lower + range - 1), tostring(range))
	--print("write")
	while 2*lower // maxRange == 2*(lower + range - 1) // maxRange do
		writebit(2*lower // maxRange)
		range *= 2
		lower = 2*lower%maxRange
	end
	print(bstr .. ":" .. tobinarystring(lower))
	print(bstr .. ":" .. tobinarystring(lower + range - 1))
	--print("buffer", bstr)
end

print(lower, "-", (lower + range - 1))--//(maxRange//2))
--for i = 1, 20 do
	encode(5, 2, 1)
	encode(5, 2, 1)
	encode(5, 2, 1)
	encode(5, 2, 1)
	encode(5, 2, 1)
	encode(5, 2, 1)
--end
-- encode(5, 2, 1)
-- encode(5, 2, 1)
-- encode(5, 2, 1)

--print(lower*5//10000)
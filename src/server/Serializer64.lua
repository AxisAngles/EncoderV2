local Serializer64 = {}
local Bitwriter = {}

local nan = tostring(0/0)

--base64 yo
local alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+-"
local map = {}
local inv = {}
for i = 1, #alphabet do
	local c = string.byte(alphabet, i)
	map[i - 1] = c
	inv[c] = i - 1
end

local function comp48(n)
	local c0 = n%64 n = (n - c0)/64
	local c1 = n%64 n = (n - c1)/64
	local c2 = n%64 n = (n - c2)/64
	local c3 = n%64 n = (n - c3)/64
	local c4 = n%64 n = (n - c4)/64
	local c5 = n%64 n = (n - c5)/64
	local c6 = n%64 n = (n - c6)/64
	local c7 = n%64 n = (n - c7)/64
	return string.char(map[c0], map[c1], map[c2], map[c3],
		map[c4], map[c5], map[c6], map[c7])
end

local function decomp48(d, i)
	local c0, c1, c2, c3,
	c4, c5, c6, c7 = string.byte(d, 8*i - 7, 8*i)
	return inv[c0]*2^0 + inv[c1]*2^6
		+ inv[c2]*2^12 + inv[c3]*2^18
		+ inv[c4]*2^24 + inv[c5]*2^30
		+ inv[c6]*2^36 + inv[c7]*2^42
end

function Bitwriter.newbitwriter()
	local ndat = 0
	local dat = {}
	local ncache = 0
	local cache = 0
	local function write(nvalue, value)
		while 48 <= ncache + nvalue do
			local nrem = 48 - ncache
			local mod = 2^nrem
			local rem = value%mod
			ndat = ndat + 1
			dat[ndat] = comp48(cache + rem*2^ncache)
			ncache = 0
			cache = 0
			nvalue = nvalue - nrem
			value = (value - rem)/mod
		end
		cache = cache + value*2^ncache
		ncache = ncache + nvalue
	end

	local function finalize()
		dat[ndat + 1] = comp48(cache)
		return table.concat(dat)
	end

	return write, finalize
end

function Bitwriter.newbitreader(dat)
	local ndat = 0
	local ncache = 0
	local cache = 0
	local function read(bits)
		local nvalue = 0
		local value = 0
		while ncache + nvalue < bits do
			value = value + cache*2^nvalue
			nvalue = nvalue + ncache
			ndat = ndat + 1
			cache = decomp48(dat, ndat)
			ncache = 48
		end
		local nrem = bits - nvalue
		local mod = 2^nrem
		local rem = cache%mod
		ncache = ncache - nrem
		cache = (cache - rem)/mod
		value = value + rem*2^nvalue
		return value
	end

	return read
end

function Serializer64.serialize(data, yieldFunc)
	local write, finalize = Bitwriter.newbitwriter()
	local nrefs = 0
	local refs = {}
	local function encode(data)
		if yieldFunc and yieldFunc() then
			coroutine.yield()
		end
		local ref = refs[data]
		if ref then
			write(3, 0)
			local fr, exp = math.frexp(ref)
			write(5, exp)
			write(exp, ref)
			return
		end
		local datatype = typeof(data)
		if datatype == "boolean" then
			write(3, 1)
			if data then
				write(1, 1)
			else
				write(1, 0)
			end
		elseif datatype == "number" then
			if data%1 == 0 and -2^31 < data and data < 2^31 then
				write(3, 2)
				local fr, exp = math.frexp(data)
				write(5, exp)
				if data < 0 then
					write(1, 1)
					write(exp, -data)
				else
					write(1, 0)
					write(exp, data)
				end
			else
				write(3, 3)
				if data == data then
					local pos
					if data < 0 then
						write(1, 1)
						pos = -data
					else
						write(1, 0)
						pos = data
					end
					if pos == 1/0 then
						write(11, 2047)
						write(52, 0)
					elseif pos < 2^-1022 then
						write(11, 0)
						write(52, pos*2^1022*2^52)
					else
						local fr, exp = math.frexp(pos)
						write(11, exp + 1022)
						write(52, 2^52*(2*fr - 1))
					end
				else
					write(1, 0)
					write(11, 2047)
					if tostring(data) == nan then
						write(52, 1)--ind
					else
						write(52, 2)--qnan
					end
				end
			end
		elseif datatype == "string" then
			nrefs = nrefs + 1
			refs[data] = nrefs
			write(3, 4)
			local len = #data
			if 2^31 <= len then
				error("string must be less than 2 gigabytes. Sorry! :(")
			end
			local fr, exp = math.frexp(len)
			write(5, exp)
			write(exp, len)
			for i = 1, len do
				local c = string.byte(data, i)
				write(8, c)
			end
		elseif datatype == "table" then
			nrefs = nrefs + 1
			refs[data] = nrefs
			write(3, 5)
			local numi = 0
			while data[numi + 1] do
				numi = numi + 1
			end
			local numk = -numi
			for k in next, data do
				numk = numk + 1
			end
			local fri, expi = math.frexp(numi)
			local frk, expk = math.frexp(numk)
			write(5, expi)
			write(expi, numi)
			write(5, expk)
			write(expk, numk)
			for i = 1, numi do
				encode(data[i])
			end
			for i, v in next, data do
				if type(i) ~= "number" or i%1 ~= 0 or i < 1 or numi < i then
					encode(i)
					encode(v)
				end
			end
		elseif datatype == "Color3" then
			
		else
			error("unknown datatype. sorry :( "..typeof(data).." "..tostring(data))
		end
	end

	encode(data)
	local final = finalize()
	return final
end


function Serializer64.deserialize(bin)
	local read = Bitwriter.newbitreader(bin)
	local nrefs = 0
	local refs = {}
	local function decode()
		local datatype = read(3)
		if datatype == 0 then
			local exp = read(5)
			local ref = read(exp)
			return refs[ref]
		elseif datatype == 1 then
			local raw = read(1)
			return raw == 1
		elseif datatype == 2 then
			local exp = read(5)
			local sign = read(1)
			local mag = read(exp)
			if sign == 0 then
				return mag
			else
				return -mag
			end
		elseif datatype == 3 then
			local sign = read(1)
			local pow = read(11)
			local coef = read(52)
			local smul
			if sign == 0 then
				smul = 1
			else
				smul = -1
			end
			if pow == 2047 then
				if coef == 0 then
					return smul/0
				elseif coef == 1 then
					return 0/0
				else
					return -(0/0)
				end
			elseif pow == 0 then
				return smul*coef*2^-1074
			else
				return smul*(coef/2^52 + 1)*2^(pow - 1023)
			end
		elseif datatype == 4 then
			local exp = read(5)
			local len = read(exp)
			local chars = {}
			for i = 1, len do
				chars[i] = string.char(read(8))
			end
			local str = table.concat(chars)
			nrefs = nrefs + 1
			refs[nrefs] = str
			return str
		elseif datatype == 5 then
			local expi = read(5)
			local numi = read(expi)
			local expk = read(5)
			local numk = read(expk)
			local tab = {}
			nrefs = nrefs + 1
			refs[nrefs] = tab
			for i = 1, numi do
				tab[i] = decode()
			end
			for i = 1, numk do
				tab[decode()] = decode()
			end
			return tab
		else
			error("unknown datatype. sorry :(")
		end
	end

	local final = decode()
	return final
end

return Serializer64
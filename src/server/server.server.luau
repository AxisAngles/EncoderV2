-- By Trey Reynolds (AxisAngle)
--!native
--!strict


local Encoder = require("./Encoder")


-- local RangeBuffer = require(script.Parent.RangeBuffer)

-- local types = {
-- 	["nil"] = {
-- 		encode = function(encoder, data) end;
-- 		decode = function(decoder) return nil end;
-- 	}
-- 	boolean = {
-- 		encode = function(encoder, data)
-- 			encoder.writer:write(2, data and 1 or 0)
-- 		end;
-- 		decode = function(decoder)
-- 			return decoder.reader:read(2) == 1
-- 		end;
-- 	}
-- 	number = {
-- 		--[[
-- 			0 ->    0
-- 			1 -> +- 1
-- 			2 -> 
-- 			3
-- 			4
-- 			5
-- 			6

-- 		]]
-- 		encode = function(encoder, data)

-- 			if data == 0
-- 			local f, e = math.frexp(data)
-- 			f = 2*f - 1
-- 			e =   e - 1
-- 			writer()
-- 		end;
-- 		decode = function(decoder)
-- 		end;
-- 	}
-- }

-- local Serializer = {}
-- Serializer.__index = Serializer

-- -- we do something special for strings:
-- -- often times, we encounter strings which are just limited to being vairable names.

-- local varCharsCount
-- local decodeVarChar = {} -- decode
-- local encodeVarChar = {} -- encode
-- do
-- 	for v = string.byte("0"), string.byte("9") do
-- 		table.insert(decodeVarChar, v)
-- 	end
-- 	for v = string.byte("A"), string.byte("Z") do
-- 		table.insert(decodeVarChar, v)
-- 	end
-- 	table.insert(decodeVarChar, string.byte("_"))
-- 	for v = string.byte("a"), string.byte("z") do
-- 		table.insert(decodeVarChar, v)
-- 	end
-- 	for i, v in decodeVarChar do
-- 		encodeVarChar[v] = i
-- 	end
-- 	varCharsCount = #decodeVarChar + 1 -- to account for null terminator
-- end

-- local function writeString(writer, str)
-- 	-- first we determine what kind of string it is.
-- 	-- variable strings can include numbers, letters and underscores.
-- 	-- text strings are in the range from 
-- end

-- function Serializer.serialize(...)
-- 	-- nil is always 0
-- 	-- new is always typeCount
-- 	local self = {}

-- 	self.typeCount = 1
-- 	self.typeHash = {["nil"] = 0;}
-- 	self.writer = RangeBuffer.newWriter()

-- 	for i = 1, select("#", ...) do
-- 		self:encode(select(i, ...))
-- 	end

-- 	return self.writer:dump()
-- end

-- function Serializer:encode(data)
-- 	local dataType = typeof(data)
-- 	local typeId = self.typeHash[dataType]
-- 	if not typeId then
-- 		self.writer:write(self.typeCount + 1, self.typeCount)
-- 		for i = 1, #dataType do
-- 			local byte = string.byte(dataType, i)
-- 			self.writer:write(varCharsCount, encodeVarChar[byte])
-- 		end
-- 		self.writer:write(varCharsCount, 0) -- terminate
-- 		self.typeHash[dataType] = self.typeCount
-- 		self.typeCount += 1
-- 	else
-- 		self.writer:write(self.typeCount + 1, typeId)
-- 	end

-- 	self:encodeType(dataType, data)
-- end

-- function Serializer:encodeType(dataType, data)
-- 	types[dataType].encode(self, data)
-- end

-- return Serializer

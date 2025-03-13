--[[
	some basic encode/decode ability is built in to the encoder/decoder that gets passed in

	encoder:write(bits, code)
		writes a code up to 32 bits
	encoder:writeFib(number)
		writes an integer from 1 to encoder.maxFib
	encoder:writeString(string)
		writes out the bytes of a string


	tables are handled internally
]]


-- all these are defined later on, they're just in here for organization
local subtypeFuncs = {
	["boolean"] = nil;
	["number"] = nil;
	["string"] = nil;
}

-- we split up types into subtypes when we expect some subtypes to be way more common than others
-- integers vs doubles
-- true vs false
-- binary strings vs ASCII strings (TODO)
local encodeFuncs = {
	["_true"] = nil;
	["_false"] = nil;

	["_zero"] = nil;
	["_double"] = nil;
	["_pfib"] = nil;
	["_nfib"] = nil;

	["_estring"] = nil;
	["_bstring"] = nil;
	--["_ASCII"] = nil;
}

local decodeFuncs = {
	["_true"] = nil;
	["_false"] = nil;

	["_zero"] = nil;
	["_double"] = nil;
	["_pfib"] = nil;
	["_nfib"] = nil;

	["_estring"] = nil;
	["_bstring"] = nil;
	--["_ASCII"] = nil;
}








-- Boolean
function subtypeFuncs.boolean(encoder, value)
	return value and "_true" or "_false"
end

function encodeFuncs._true(encoder, value)
end

function decodeFuncs._true(decoder)
	return true
end

function encodeFuncs._false(encoder, value)
end

function decodeFuncs._false(decoder)
	return false
end








-- Number
function subtypeFuncs.number(encoder, value)
	if value == 0 then
		return "_zero"
	elseif
		value%1 ~= 0      or
		value   < -encoder.maxFib or
		value   >  encoder.maxFib or
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

function encodeFuncs._zero(encoder, value)
end

function decodeFuncs._zero(decoder)
	return 0
end

local _f64buff = buffer.create(8)
function encodeFuncs._double(encoder, value)
	buffer.writef64(_f64buff, 0, value)
	encoder:write(32, buffer.readbits(_f64buff,  0, 32))
	encoder:write(32, buffer.readbits(_f64buff, 32, 32))
end

function decodeFuncs._double(encoder)
	buffer.writebits(_f64buff,  0, 32, encoder:read(32))
	buffer.writebits(_f64buff, 32, 32, encoder:read(32))
	return buffer.readf64(_f64buff, 0)
end

function encodeFuncs._pfib(encoder, value)
	encoder:writeFib(value)
end

function decodeFuncs._pfib(decoder)
	return decoder:readFib()
end

function encodeFuncs._nfib(encoder, value)
	encoder:writeFib(-value)
end

function decodeFuncs._nfib(decoder)
	return -decoder:readFib()
end








-- String
function subtypeFuncs.string(encoder, value)
	if value == "" then
		return "_estring"
	else
		return "_bstring"
	end
end

function encodeFuncs._estring(encoder, value)
end

function decodeFuncs._estring(decoder)
	return ""
end

function encodeFuncs._bstring(encoder, value)
	encoder:writeFib(#value)
	encoder:writeString(value)
end

function decodeFuncs._bstring(decoder)
	local len = decoder:readFib()
	return decoder:readString(len)
end

-- TODO: make more assumptions about the general kind of text we will encounter
-- function encodeFuncs._ASCII(write, value)
-- end

-- function decodeFuncs._ASCII(read)
-- end












local function subtypeof(encoder, value)
	local valueType = typeof(value)

	local subtypeFunction = subtypeFuncs[valueType]
	if subtypeFunction then
		return subtypeFunction(encoder, value)
	else
		return valueType
	end
end

local function encode(encoder, subtype, value)
	if not encodeFuncs[subtype] then
		error("no subtype encoder " .. subtype)
	end
	encodeFuncs[subtype](encoder, value)
end

local function decode(decoder, subtype)
	return decodeFuncs[subtype](decoder)
end


return {
	subtypeof = subtypeof;
	encode = encode;
	decode = decode;
}
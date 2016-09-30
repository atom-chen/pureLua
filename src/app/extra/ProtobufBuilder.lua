local s_inst = nil
local ProtobufBuilder = class("ProtobufBuilder")
import(".protobuf")
local pb = require "protobuf"

local helper = PbcHelper:getInstance()

function ProtobufBuilder:getInstance()
	if s_inst == nil then
		s_inst = ProtobufBuilder.new()
	end
	return s_inst
end

function ProtobufBuilder:ctor()

end

function ProtobufBuilder:encode(proto,desc,data)
	helper:registerProto(proto)
	return pb.encode(desc,data)
end

--[[
build a message
param.proto = proto file
param.desc = descriptor
param.input = input message
]]
function ProtobufBuilder:build(param)
	-- self:begin(param.proto)
	-- param.input.sign = self:finish()
	-- dump(param.input)
	helper:registerProto(param.proto)
	return pb.encode(param.desc,param.input)
end

--[[
decode a message
param.proto = proto file
param.desc = descriptor
param.input = input message
]]
function ProtobufBuilder:decode(param)
	helper:registerProto(param.proto)
	return pb.decode(param.desc,param.input)
end

-- param.proto
-- param.desc
-- param.filename
function ProtobufBuilder:decodeFile(proto,desc,filename)
	helper:registerProto(proto)
	return pb.decodeFile(desc,helper.decodeFile,filename)
end


function ProtobufBuilder:loadFromFile(proto,desc,filename)
  local pbData = self:decodeFile(proto, desc, filename)
	if nil ~= pbData then
    return pbData
	else
		printInfo(string.format("Can't load pb:%s", filename))
		return nil
	end
end

return ProtobufBuilder

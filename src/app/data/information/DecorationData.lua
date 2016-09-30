local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local infoManager 	= import(".InfoManager", CURRENT_MODULE_NAME):getInstance()

--
-- DecorationData
--
local DecorationData = class("DecorationData")


function DecorationData:ctor( pb )
	--self.id  		= pb.id
	self.class_id = pb.class_id
	self.state    = pb.state

	self.info = infoManager:findInfo("decorations","class_id",pb.class_id)
end

return DecorationData

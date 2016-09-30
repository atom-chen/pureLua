

local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local infoManager 	= import(".InfoManager", CURRENT_MODULE_NAME):getInstance()

--
-- MonsterData
--
local MonsterData = class("MonsterData")


function MonsterData.findInfo( class_id )
	-- print(id)
	return infoManager:findInfo("monsters","class_id",class_id)
end

function MonsterData:ctor( pb )
	
	self.id  		= pb.id
	self.class_id   = pb.id  --(monster 静态pb id = class_id)

	self.name     	= pb.name
	--print(pb.class_id)
	self.info       = MonsterData.findInfo(self.class_id)

	--dump(self.info)

	-- equipments
	self.equipments = { }

	-- attributes
	local attr    	= { }

	self.attr 		= attr
end

return MonsterData

local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local infoManager 	= import(".InfoManager", CURRENT_MODULE_NAME):getInstance()

--
-- HeroData
--
local HeroData = class("HeroData")


function HeroData:ctor( pb )
	--self.id  		= pb.id
	dump(pb)
	self.class_id   = pb.class_id
	self.level      = pb.level
	self.exp        = pb.exp
	self.count      = pb.count
	self.intensify  = pb.intensify

	self.info = infoManager:findInfo("heros","class_id",pb.class_id)

	--dump(self.info)
end

return HeroData

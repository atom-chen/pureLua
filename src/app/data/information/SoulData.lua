local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local infoManager 	= import(".InfoManager", CURRENT_MODULE_NAME):getInstance()
-- local playerMgr = import(".PlayerDataManager", CURRENT_MODULE_NAME):getInstance()

--
-- SoulData 元神信息
--
local SoulData = class("SoulData")

local function copyRepeatedWithPb(repeated,key)
    local result = { }
    for _,item in ipairs(repeated) do
        -- local data = cls.new(item)
        result[item[key]] = item
    end
    return result
end



function SoulData.findInfo(classId)
	--printInfo("SoulData : class_id="..classId)
	return infoManager:findInfo("souls","class_id",classId)
end

function SoulData:ctor( pb )
	-- dump(pb.intensify)

   -- local intensifysTable = {pb.intensify.soul_id,pb.intensify.atkIntensifyId,pb.intensify.atkSpeedIntensifyId,pb.intensify.baojiIntensifyId,
   --                          pb.intensify.baojiAtkIntensifyId,pb.intensify.pojiaIntensifyId,pb.intensify.skillIntensifyId}


	self.class_id 		       = pb.class_id
	self.level 		           = pb.level
	self.exp 	 	           = pb.exp
	self.count 		           = pb.count
	self.star 		           = pb.star
	self.assemblages 	       = copyRepeatedWithPb(pb.assemblages,"id")
	self.intensifys            = pb.intensify
    self.status                = pb.status
    self.currentEnergy         = pb.currentEnergy
    self.loveLevel 	           = pb.loveLevel
    self.currentLove 	       = pb.currentLove
    self.secrets 	           = copyRepeatedWithPb(pb.secrets,"class_id")
    self.fashions 	           = copyRepeatedWithPb(pb.fashions,"class_id")
    self.shopFashions 	       = copyRepeatedWithPb(pb.shopFashions,"class_id")
    self.projects 	           = copyRepeatedWithPb(pb.projects,"class_id")
    self.currentFashionClassId = pb.currentFashionClassId
	self.info 		           = SoulData.findInfo(self.class_id)

    -- 测试数据
    -- self.projects = {}
    -- for i=1,5 do
    --     local p = {}
    --     p.state = math.random(1, 3)
    --     p.type = 1
    --     p.class_id = self.class_id * 1000 + p.type * 100 + i
    --     self.projects[p.class_id] = p
    -- end
    -- for i=1,1 do
    --     local p = {}
    --     p.state = math.random(1, 3)
    --     p.type = 2
    --     p.class_id = self.class_id * 1000 + p.type * 100 + i
    --     self.projects[p.class_id] = p
    -- end
    --
    --
	-- dump(self)
end

return SoulData

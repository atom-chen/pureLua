local CURRENT_MODULE_NAME = ...

local Bullet = import(".Bullet",CURRENT_MODULE_NAME)
local AnimationNode       = import("..controls.CocostudioNode")

local WarningNode  = class("WarningNode", display.newNode)
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()


function WarningNode:ctor(params)

	self:enableNodeEvents()
    
	self.warningNode = AnimationNode.new({csbName = "nodes/battle/warning.csb"}):addTo(self)

    --dump(params)

    self.pb = params

end


function WarningNode:onEnter()
	print("进入 onEnter")
	--local node = self:getParent():getParent()
	--dump(self.pb)

    self.warningNode:runAnimation("in",false,function()

    local bullet = Bullet:create({id = self.pb.id,
                                type = self.pb.type,
                                dmgValue = self.pb.dmgValue,
                                range = self.pb.range,
                                angle = self.pb.angle,
                                height = self.pb.height,
                                speed = self.pb.speed,
                                camp = 1,
                                pos = self.pb.pos})
                                :addTo(self.pb.target,2000)
--,emanate = emanate,target = data.target,checkMod = skillInfo.checkMod
    bullet:setPosition(self.pb.pos)
    self:removeFromParent()
 


   end)
   musicManager:play(girl.UiMusicId.MISSILE_CROSS)
  
end


return WarningNode
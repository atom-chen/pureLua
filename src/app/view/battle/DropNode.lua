local CURRENT_MODULE_NAME = ...
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()

local DropNode = class("DropNode",display.newNode)

DropNode.dropType = 
{
	DROP_BOX 			= 1,
	DROP_EX_SKILL_EXP 	= 2, --奥义点
	DROP_HP 			= 3, --HP
	DROP_SP 			= 4, --（作废）暂时不做处理
}

function DropNode.create(params)

	return DropNode.new({plistName = "plist/drop.plist",
		type = params.type,
		value = params.value,
		targetPos= params.targetPos,
		effTarget = params.effTarget})
end

function DropNode:ctor(params)

	self:enableNodeEvents()

	self.type = params.type
	self.effTarget = params.effTarget
	self.value = params.value
	self.targetPos = cc.p(params.targetPos)

	local iconType = {"Box","EXskill","Hp","Sp"}
	local dropIcon = cc.Sprite:create("sundry/textures/icon/battle/icon_drop"..iconType[params.type]..".png")
	self:addChild(dropIcon)

	local particle = cc.ParticleSystemQuad:create(params.plistName)
	self:addChild(particle)

	self.isAddValue = false
	
end


function DropNode:onEnter()

	self:schedule(self,handler(self, self.updateSelf))

end

function DropNode:updateSelf(dt)
	if self:getPositionX() <= battleManager.hero:getPositionX() then
		self:unschedule()
		--切换到ui层处理
		self:changeParent(battleManager.battleUi,1024)
		self:setPosition(cc.p(battleManager.cameraPos.x + self:getPositionX(),battleManager.cameraPos.y + self:getPositionY()))
		local moveto = cc.MoveTo:create(1.0,cc.p(self.targetPos.x,self.targetPos.y))
		local scale  = cc.ScaleTo:create(1.0,0.5)
		local callBack = cc.CallFunc:create(handler(self, self.destroy))
		local action = cc.Spawn:create(cc.Sequence:create(moveto,callBack,nil),scale)
		self:runAction(action)
	else
		self:setLocalZOrder(display.height - self:getPositionY())
	end
end

--处理各种数据
function DropNode:processDoSth()

	if self.type == DropNode.dropType.DROP_BOX then
		battleManager.boxNum = battleManager.boxNum + self.value
	elseif self.type == DropNode.dropType.DROP_EX_SKILL_EXP then
		self.effTarget:addExSkillPoint(self.effTarget.exSkillPointMax*(self.value/100.0))
	elseif self.type == DropNode.dropType.DROP_HP then
		self.effTarget:addHp(self.effTarget.topHp*(self.value/100.0))
	elseif self.type == DropNode.dropType.DROP_SP then
		self.effTarget:addSp(self.value)
	end

end

function DropNode:destroy()

	print("DropNode:destroy()000")
	if self.isAddValue then
		return
	end
	print("DropNode:destroy()111")
	self:processDoSth()
	self.isAddValue = true
	self:removeFromParent()
	
end

return DropNode
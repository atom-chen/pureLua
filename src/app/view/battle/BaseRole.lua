local CURRENT_MODULE_NAME = ...

local SpineNode = import("..controls.SpineNode", CURRENT_MODULE_NAME)
local BloodLabel = import("..fragment.BattlePanelFragment.BloodLabel",CURRENT_MODULE_NAME)

local BaseRole = class("BaseRole",SpineNode)

--singleton
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()

BaseRole.roleType  = table.enumTable(
{
    "ROLE_TYPE_HERO",
    "ROLE_TYPE_SOUL",
    "ROLE_TYPE_MONSTER",
})

BaseRole.dirType = table.enumTable(
{
	"DIR_UP",
	"DIR_DOWN",
	"DIR_LEFT",
	"DIR_RIGHT"
})

BaseRole.statusType = table.enumTable
{
	"STATUS_WAIT",
    "STATUS_MOVE",
    "STATUS_ATTACK",
    "STATUS_EX",			--奥义
    "STATUS_SKL",
    "STATUS_FAST",			--前冲
    "STATUS_DMG",
    "STATUS_DEAD",
    "STATUS_JUMP",    		--跳
    "STATUS_SKITE",  		--滑
    "STATUS_WIN"
}

BaseRole.campType =
{
	CAMP_HERO 		= 0,
	CAMP_MONSTER 	= 1,
	CAMP_SOUL		= 2
}

BaseRole.OBJ_TYPE =
{
	MONSTER 		= 0, 		--怪
	BOMB 			= 1,    	--地雷
	ELECTRICITY_NET = 2, 		--电网
	BARRIER 		= 3,		--栅栏
	BOSS 			= 4, 		--boss
}

BaseRole.SKILL_ATK_DIS  = display.width*0.75                     --//远程攻击检测距离//
BaseRole.KEEP_DIS 		= 32
BaseRole.HERO_POSITION  = cc.p(-128,208)

--[[
-- params.atlasName
-- params.jsonName
params.id
]]
function BaseRole:ctor(params)

	--dump(params)
	BaseRole.super.ctor(self,params)
	self:enableNodeEvents()
	self.curTarget=nil
	self.curTargetPool=0
	self.shadow = cc.Sprite:create("spine/shadow.png")

	self.initSpine = false
	self.shadowScale=1.0
	self.bornPosY =0
	self.curSpeed=128.0
	self.dir=0
	self.type=0
	self.step=1
	self.status=-1
	self.safeTime = 0
	self.height = 0
	self.fireOrder 	= 1
	--界面里加载的角色都不执行ai逻辑
	if false ==params.onUi then
		self:onUpdate(handler(self,self.updateSelf))
		self:addChild(self.shadow)
	end
	
end

function BaseRole:updateSelf(dt)
	
	--print("updateSelf")
	self:updateInitGetSpineSize(dt)
	self:updateAi(dt)

end

function BaseRole:updateInitGetSpineSize(dt)

	if self.initSpine == false  then
		local size = self:getCascadeBoundingBox()
		--dump(size)
   		self.shadow:setScale(size.width/165.0)
   		self.bornPosY = self:getPositionY()
    	self.shadowScale=self.shadow:getScale()
    	self.initSpine=true
	end
end


function BaseRole:isArcRectCollides(circle_pt, radius, rect)
    local cx = nil
    local cy = nil
 
    -- Find the point on the collision box closest to the center of the circle
    if circle_pt.x < rect.x then
        cx = rect.x
    elseif circle_pt.x > rect.x + rect.width then
        cx = rect.x + rect.width
    else
        cx = circle_pt.x
    end
 
    if circle_pt.y < rect.y then
        cy = rect.y
    elseif circle_pt.y > rect.y + rect.height then
        cy = rect.y + rect.height
    else
        cy = circle_pt.y
    end
 
    if cc.pGetDistance(circle_pt, cc.p(cx, cy)) < radius then
        return true
    end
 
    return false
end

function BaseRole:setDir(dir)

	self.dir = dir 
	if dir== BaseRole.dirType.DIR_RIGHT then
		self:setScaleX(self.scale)
	else
		self:setScaleX(-self.scale)
	end

	return self.dir
end

function BaseRole:setScaleEx(scale)
	
	self:setScaleX(scale)
	self:setScaleY(scale)

end
function BaseRole:spineCallBack(events)
	
end


function BaseRole:changeStatus(status , idx)

	if self.status == status then
		return
	end
	self.status = status
	--printInfo("status"..self.status)
	if status == BaseRole.statusType.STATUS_WAIT then
		--todo
		self:runAnimation(string.format("WAIT%d",idx+10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_MOVE then
		self:runAnimation(string.format("MOV%d",idx+10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_ATTACK then
		self:runAnimation(string.format("ATK%d",idx+10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_DMG then
		self:runAnimation(string.format("DMG%d",idx+10),false,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_SKL then
		self:runAnimation(string.format("SKL%d",idx+self.step*10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_EX then
		self:runAnimation(string.format("EX%d",idx+10),false,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_FAST then
		self:runAnimation(string.format("FAST%d",idx+10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_DEAD then
		self:runAnimation(string.format("DIE%d",idx+10),false,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_JUMP then
		self:runAnimation(string.format("JUMP%d",idx+10),false,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_SKITE then
		self:runAnimation(string.format("SKITE%d",idx+10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	elseif status == BaseRole.statusType.STATUS_WIN then
		self:runAnimation(string.format("WIN%d",idx+10),true,{ onComplete = handler(self,self.spineCallBack)})
		return
	end

end

function BaseRole:updateAi(dt)

	if battleManager.mapW>0 then
		self:setShadowScale(self.bornPosY)
		--极端检测(地图尽头)
		if (self:getPositionX() > battleManager.mapW-display.width*0.2) then
        	self:setPositionX(battleManager.mapW-display.width*0.2)
	    elseif (self:getPositionX() <=0) then
	        self:setPositionX(0)
	    end
	end
end

function BaseRole:setShadowScale(bottomY)
 	if (self:getPositionY()-bottomY)<=48 and (self:getPositionY()-bottomY)>=0 then
        self.shadow:setPositionY(self:getPositionY()-bottomY)
        self.shadow:setScale(self.shadowScale)
        return
    elseif self:getPositionY()-bottomY < 0 then
    	self.shadow:setPositionY(0)
        self.shadow:setScale(self.shadowScale)
        return
	end
    self.shadow:setPositionY(-math.abs(self:getPositionY()-bottomY))
    self.shadow:setScale(self.shadowScale*(32.0/math.abs(self:getPositionY()-bottomY)))
end

function BaseRole:setTargetObj(target)

	self.curTarget = target
	--dump(self.curTarget)
end
--need add
function BaseRole:getCloseTarget(targets)
	if  table.nums(targets) ==0 then
		--todo
		return nil
	end
	self.curTargetPool = {}
	local idx = -1
	local dis = cc.pGetDistance(cc.p(self:getPositionX(),self:getPositionY()),cc.p(targets[1]:getPositionX(),self:getPositionY())) --self:distanceBetweenPointAndPoint(self:getPosition(),cc.p(targets[1]:getPositionX(),self:getPositionY()))
	for i,v in ipairs(targets) do
			
		local tempDis = cc.pGetDistance(cc.p(self:getPositionX(),self:getPositionY()),cc.p(targets[i]:getPositionX(),self:getPositionY()))--self:distanceBetweenPointAndPoint(self:getPosition(),cc.p(targets[k]:getPositionX(),self:getPositionY()))
		if tempDis<=dis then
			dis = tempDis
			idx = i
		end
		-- -- //get in-screen monsters//
        if targets[i]:checkInScreen() then
     		--printInfo("curTargetPool insert ......")
            table.insert(self.curTargetPool,targets[i])
        end
	end

	if (idx==-1) then
        return nil
    else
        self:setTargetObj(targets[idx]);
        return targets[idx];
    end
end
--检测是否在屏内
function BaseRole:checkInScreen()
	if (self:getPositionX() + battleManager.cameraPos.x > 0 and
        self:getPositionX() + battleManager.cameraPos.x < display.width) then
        return true
    else
    	return false
    end
end

function BaseRole:damage( type, damage )

	--printInfo("[BaseRole] : self:getSize().height:"..self:getSize().height)
  	BloodLabel.create(type, damage)
    :setPositionY(self.height)
    :addTo(self)
end

function BaseRole:addHpGreenEff( type, damage )

	--printInfo("[BaseRole] : self:getSize().height:"..self:getSize().height)
  	BloodLabel.create(type, damage)
    :setPositionY(self.height)
    :addTo(self)
end


return BaseRole

local CURRENT_MODULE_NAME = ...

local BaseRole 		= import(".BaseRole")
local MonsterData   = import("...data.information.MonsterData", CURRENT_MODULE_NAME)
--singleton
local resManager 	= import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()

local Trap = class("Trap", BaseRole)

function Trap.createWithId( id )
	return Trap.new({id = id})
end

function Trap.createOnUiWithId(id)
	return Trap.new({id = id,onUi = true})
end

--need add
function Trap:ctor(params)
	--dump(params)
	self.pb  =  MonsterData.new(params)
	--dump(self.pb)
	self.info = self.pb.info
	--dump(self.info)
	local jsonName = resManager:getResPath(self.info.avatar_id)
	params.jsonName = string.sub(jsonName,0,string.len(jsonName)-3)..".json"
	params.atlasName = resManager:getResPath(self.info.avatar_id)..".atlas"

	--dump(params.jsonName)
	Trap.super.ctor(self, params)
	self:enableNodeEvents()

	self.curHp 		= self.info.hp
	self.type  		= Trap.roleType.ROLE_TYPE_MONSTER
	self.objType 	= self.info.objType
	self.height 	= self.info.rect_height
	self.scale 		= self.info.scale
	self.curSpeed 	= self.info.speed
	self.otherHalfObj	= nil --源对象（另外半个当作怪处理）
	self:setScaleEx(self.scale)
	self:setDir(Trap.dirType.DIR_LEFT)
	self:changeStatus(Trap.statusType.STATUS_WAIT,2)
	self.shadow:setVisible(false)
end


function Trap:updateSelf( dt )
	self.super.updateSelf(self,dt)
end

function Trap:getRect()

	local rt = cc.rect(self:getPositionX()-self.info.rect_x,
					self:getPositionY()+self.info.rect_y,
					self.info.rect_width,
					self.info.rect_height)
	return rt
end

--need add --
function Trap:destroy()
	self:stopAllActions()
	self:setVisible(false)
	local fadeout = cc.FadeOut:create(0.5)
	self:setCascadeOpacityEnabled(true)
	local action = cc.Sequence:create(fadeout,cc.CallFunc:create(function()
			self:setVisible(false)
			self:removeFromParent()
		end))
	self:runAction(action)
end

return Trap

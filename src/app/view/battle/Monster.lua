local CURRENT_MODULE_NAME = ...

local BaseRole 		= import(".BaseRole")
local MonsterData   = import("...data.information.MonsterData", CURRENT_MODULE_NAME)
local Effect 		= import("..controls.EffectManager", CURRENT_MODULE_NAME)
local Skill    		= import(".Skill", CURRENT_MODULE_NAME)
local HpNode 		= import("..fragment.BattlePanelFragment.HpNode", CURRENT_MODULE_NAME)

--singleton
local resManager 	= import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager",CURRENT_MODULE_NAME):getInstance()
local infoMgr 		= import("...data.information.InfoManager",CURRENT_MODULE_NAME):getInstance()

local Monster = class("Monster", BaseRole)

local DMG_COMMON = 0
local DMG_CRIT   = 1

function Monster.createWithId( id )
	return Monster.new({id = id,onUi = false})
end

function Monster.createOnUiWithId(id)
	return Monster.new({id = id,onUi = true})
end

--need add
function Monster:ctor(params)

	--dump(params)
	self.pb  =  MonsterData.new(params)
	--dump(self.pb)
	self.info = self.pb.info
	--dump(self.info)

	local jsonName = resManager:getResPath(self.info.avatar_id)
	params.jsonName = string.sub(jsonName,0,string.len(jsonName)-3)..".json"
	params.atlasName = resManager:getResPath(self.info.avatar_id)..".atlas"

	--dump(params.jsonName)
	Monster.super.ctor(self, params)
	self:enableNodeEvents()
	--print("shadow scale ",self.shadowScale)
	self.curHp 		= self.info.hp
	self.topHp 		= self.info.hp
	self.type  		= Monster.roleType.ROLE_TYPE_MONSTER
	self.objType 	= self.info.objType
	self.height 	= self.info.rect_height
	self.scale 		= self.info.scale
	self.curSpeed 	= self.info.speed
	self.name 		= self.info.name
	self.level 		= self.info.level
	self.bloodBarNum= self.info.bloodBarNum
	self:setScaleEx(self.scale)
	self:setDir(Monster.dirType.DIR_LEFT)
	self:changeStatus(Monster.statusType.STATUS_WAIT,1)
 
	self:setSpineEventListener()
	self.damageTimes = 0
	if self.info.skill0_id > 0 then
		self.skill = Skill.create({class_id = self.info.skill0_id})
	end
	
	--add hp bar
	if self.objType == BaseRole.OBJ_TYPE.MONSTER then
		self.hpBar = HpNode.create({obj = self}):addTo(self,10)
		self.hpBar:setPosition(0,self.height)
		self.hpBar:hide()
	elseif self.objType == BaseRole.OBJ_TYPE.BOSS then
		MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.PROCESS_BOSS,{status = "NORMAL",obj = self})
	end

	self.atk = self.info.atk
	self.deff = self.info.deff
	self.baoJiRate = self.info.baoJi   				--暴击率
	self.baoJiAtk = self.info.baoJiAtk           	--暴击伤害率
	self.poJia = self.info.poJia
	self.tenacity = self.info.tenacity

	self.isInAction = false
	self.isInFreeMove = false
	self.cloneRoot = nil  --克隆体
	self.effRoot = {}
	self.effRoot["eff1"] = cc.Node:create():addTo(self) 	--特效结点
	self.effRoot["eff2"] = cc.Node:create():addTo(self)
	self.effRoot["eff3"] = cc.Node:create():addTo(self)
	
	self.aiId = 0
	self.aiInfo=nil
	self.activeTimes=0
	self.isInAi = false
	self.aiCd = 0
	self.emanate = nil
	-- local rt = cc.rect(-self.info.rect_x,
	-- 					self.info.rect_y,
	-- 					self.info.rect_width,
	-- 					self.info.rect_height)
	-- girl.createTestRect(rt):addTo(self)
end

function Monster:onEnter()
	-- 设置目标
	if self.aiId > 0 then
		self.aiInfo = infoMgr:findInfo("monsterais","class_id",self.aiId)
	end
	-- if self.objType == BaseRole.OBJ_TYPE.BOSS then
	-- 	MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.PROCESS_BOSS,{status = "NORMAL",obj = self})
	-- end
	self:setTargetObj(battleManager.hero)
	self:schedule(self,handler(self, self.checkAttackUpdate),2.0)
end


function Monster.clone(obj)
	--dump(obj.pb)
	local role = Monster.createOnUiWithId(obj.pb.class_id)
	--dump(role)
	return role
end

--记录下自身克隆源本体
function Monster:setCloneRoot(obj)
	self.cloneRoot = obj
end


function Monster:updateSelf( dt )

	self.super.updateSelf(self,dt)
	self:checkUpdate(dt)
	self:collideBulletUpdate(dt)
	self:trapLogic()
	self:onAiUpdate(dt)
	self:updateEffRoot(dt)

end
--ok---
function Monster:checkUpdate(dt)

	if ((self.objType ~= Monster.OBJ_TYPE.MONSTER and self.objType ~= Monster.OBJ_TYPE.BOSS) or false == self:checkInScreen()) then
		return
	end
	
	if self.curHp > 0 and self.curTarget ~= nil and self.status ~= Monster.statusType.STATUS_DMG then
		if self.isInFreeMove or self.isInAi or self.isInAction then
			return
		end
		if self.curTarget:getPositionX() +self.curTarget.info.rect_x+self.curTarget.info.rect_width + Monster.KEEP_DIS > self:getPositionX()  then
			--printInfo("[Monster]: 主角位置超过与怪物保持的最小距离，怪物会退后....")
			if battleManager.isPushMonster then
				self:toFreeMove()
			else
				self:blockHero()
			end
		elseif self:getPositionX() - self.info.atk_check_dis > self.curTarget:getPositionX() + self.curTarget.info.rect_x+self.curTarget.info.rect_width  then
			--printInfo("[Monster]: 怪物未满足可以攻击主角距离，向目标移动....")
			local pos = cc.p(self.curTarget:getPositionX() + self.curTarget.info.rect_x+self.curTarget.info.rect_width ,self.curTarget:getPositionY())
	   		self:moveTo(pos)
	   	else
	   		--printInfo("[Monster]: 满足可以攻击距离，做等待下一次 atkcheck dt....")
	   		if self.isInAction == false and self.isInSkill == false then
	   			self:changeStatus(Monster.statusType.STATUS_WAIT,1)
	   		end
		end
	end
end

function Monster:updateEffRoot(dt)

	local boneHead = self:getBoneData("effHead")
	if boneHead then
		local boneHeadX= boneHead.x
	    local boneHeadY= boneHead.y
	    self.effRoot["eff2"]:setPosition(boneHeadX,boneHeadY)
	end

	local boneBody = self:getBoneData("effBody")
	if boneBody then
		local boneBodyX = boneBody.x
    	local boneBodyY = boneBody.y
    	self.effRoot["eff3"]:setPosition(boneBodyX,boneBodyY)
	end

	local boneFoot = self:getBoneData("effFoot")
	if boneFoot then
    	local boneFootX = boneFoot.x
    	local boneFootY = boneFoot.y
    	self.effRoot["eff1"]:setPosition(boneFootX,boneFootY)
	end
end

function Monster:toFreeMove()

	if self.isInFreeMove then
		return
	end
	self.isInFreeMove = true
	self:changeStatus(Monster.statusType.STATUS_MOVE,1)
	self:setPositionX(self.curTarget:getPositionX() + self.curTarget.info.rect_x+self.curTarget.info.rect_width + Monster.KEEP_DIS)
	local moveBack = cc.MoveBy:create(0.15,cc.p(256 + math.random(128),0))
	local action   = cc.Sequence:create(moveBack,cc.CallFunc:create(function()
		self.isInFreeMove = false
		self:changeStatus(Monster.statusType.STATUS_WAIT,1)
	end))
	self:runAction(action)

end
--------增加怪物ai趣味性---------------- 
--[[
		
	1.傻傻的移动，后退
	2.走进攻击区域，攻击一次目标后逃离
	3.根据血量值％，触发技能或逃跑
	
]]--
-- function Monster:autoAi(dt)
-- 	if self.isInFreeMove or self.isInAction  or self.isInSkill or self.isInAi
-- 		or false == self:checkInScreen() then
-- 		return
-- 	end
-- 	-- self.isInFreeMove = true
-- 	-- local idx = math.random(4)
-- 	-- --printInfo("Monster:autoAi idx:"..idx)
-- 	-- if idx == 1 then
-- 	-- 	self:changeStatus(Monster.statusType.STATUS_MOVE,1)
-- 	-- 	local moveBack = cc.MoveBy:create(1,cc.p(256 + math.random(128),0))
-- 	-- 	local action   = cc.Sequence:create(moveBack,cc.CallFunc:create(function()
-- 	-- 		self.isInFreeMove = false
-- 	-- 		self:changeStatus(Monster.statusType.STATUS_WAIT,1)
-- 	--  	end))
-- 	-- 	self:runAction(action)
-- 	-- else
-- 	   	self.isInFreeMove = false
-- 		self:toCheckNextStep()
-- 	-- end
-- end

function Monster:collideWithRect(rect)
	--dump(size)
	local rt = self:getRect()
	return cc.rectIntersectsRect(rt,rect)
end
--cc.pGetDistance(cc.p(self.recPos), cc.p(self:getPosition()))
function Monster:collideWithBullet(bullet)

	--dump(bullet.lastPos)
	local pt1 = cc.p(bullet.lastPos)
	local pt2 = cc.p(bullet:getPosition())
	local size= cc.size(bullet.info.width,bullet.info.height)
	local rt1 = cc.rect(pt1.x-size.width/2.0,pt1.y -size.height/2.0,size.width,size.height)
	local rt2 = cc.rect(pt2.x-size.width/2.0,pt2.y -size.height/2.0,size.width,size.height)
	local rect= cc.rectUnion(rt1,rt2)
	--dump(rect)
	return self:collideWithRect(rect)
end

function Monster:collideBulletUpdate(dt)
	--dump(battleManager.bulletPool)
	if self.curHp <= 0 or self.objType == Monster.OBJ_TYPE.BOMB or self.objType == Monster.OBJ_TYPE.ELECTRICITY_NET then
		return
	end
	for _,v in ipairs(battleManager.bulletPool) do
		--[[checkMod:
		-- 0、无效
		-- 1、对对象和地面判定
		-- 2、对地面判定]]
		if (v.camp == Monster.campType.CAMP_HERO or v.camp == Monster.campType.CAMP_SOUL) and v.checkMod == 1 then --玩家&子弹针对对像
			self.safeTime = self.safeTime - dt
			--print("safeTime="..self.safeTime  .."dt="..dt)
			if self:collideWithBullet(v) == true and self.safeTime <= 0 then
				self.safeTime = 0.2
				self:damageWithBullet(v)
				if v.info.atkMusicId > 0 then
					musicManager:play(v.info.atkMusicId)
				end
				if v.info.hitEffId>0 then
					--print("collideWithBullet=true 11111")
					local eff = Effect.createWithId(v.info.hitEffId):addTo(self)
						--dump(eff)
						eff:setPosition(-32+math.random(64),32+math.random(64))
					 	eff:runAnimation(eff.DefaultAnimation,false, function()
				 		eff:destroy()
				 	end)
				end
				--add bullet crossTimes check
				--print("collideWithBullet=true crossTimes="..v.crossTimes)
				if v.crossTimes <= 0 then
					--在消毁前检测下是否有爆炸伤害范围（可伤及无辜）
					if  v.atkRange  > 0 then
						for _,vv in ipairs(battleManager.monsterPool) do
							if  vv ~= self and cc.pGetDistance(v:getPosition(),vv:getPosition()) <= v.atkRange then
								vv.safeTime = 0.2
								vv:damageWithBullet(v)
							end
						end
					end
					v:destroy()
				else
					v.crossTimes = v.crossTimes -1
				end
			end

			if self.safeTime <= 0 then
				self.safeTime = 0
			end
		end
	end

end

function Monster:checkAttackUpdate(dt)

	if self.curHp <= 0 or battleManager.isAoyiAction or (self.objType ~= Monster.OBJ_TYPE.MONSTER and self.objType ~= Monster.OBJ_TYPE.BOSS) then
		return
	end
	-- self:autoAi(dt)
	self:toCheckNextStep()
end

function Monster:moveTo(pos)
	
	if 	self.curHp <= 0 then
		return
	end
	self:changeStatus(Monster.statusType.STATUS_MOVE,1)
	if pos.x - self:getPositionX() >0 then
		self:setDir(Monster.dirType.DIR_RIGHT)
	else
		self:setDir(Monster.dirType.DIR_LEFT)
	end
	--local dis = cc.pGetDistance(cc.p(self:getPositionX(),self:getPositionY()),cc.p(pos.x,self:getPositionY()))
	self:setPosition(cc.pAdd(cc.p(self:getPosition()),cc.p(-self.curSpeed/60.0,0)))

end


function Monster:spineCallBack(events)

	self.fireOrder = 1

	if events.type == girl.AnimationNodeEventType.ANIMATION_COMPLETE then
		self:checkAi()
	end
end
--need add--
function Monster:setSpineEventListener()

	self:setFrameEventCallFunc({_all = function ( name,params )
		--printInfo("Monster:setSpineEventListener")
		--print("[monster] spineEvent:"..name) -- name == jump
		local param = params.stringValue
		if name == "music" then

			if self.skill and self.skill.info.musicId >0 then
				musicManager:play(self.skill.info.musicId)
			end

		elseif name == "fire" then
			--order 是发射顺序
			--print("[monster] spineEvent:"..name)
			
			if param == "" or param == 0 or param == nil then
				--order 是发射顺序
				--print("+++++++++++++++++++++++000++++++++++++++param:"..param)
				if self.skill ~= nil then
					if self.skill.info.buffId >0 then
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = self,camp = Monster.campType.CAMP_MONSTER,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					elseif self.skill.info.bulletId >0 then
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BULLET_ADD,{emanate = self,camp = Monster.campType.CAMP_MONSTER,target = self.curTarget,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					end
				end
			else
				--print("+++++++++++++++++++++++111++++++++++++++param:"..param)
				local  tmpStr  = string.split(param,"#")
				local  data    = table.values(tmpStr)
				local  type  = tonumber(data[1])  -- [1:子弹表，2:buff表]
				local  id  	 = tonumber(data[2])
				if self.skill ~= nil then
					if type == 2 then
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = self,buffId = id,camp = Monster.campType.CAMP_MONSTER,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					elseif type == 1 then
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BULLET_ADD,{emanate = self,bulletId = id,camp =Monster.campType.CAMP_MONSTER,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					end
				end
			end

		elseif name == "bomb" then
			--print("[monster] spineEvent:"..name)
			self:bomb()
		end
	end})
end

function Monster:toCheckNextStep()

	if self.isInAction or self.isInSkill or self.isInAi or self.curTarget == nil then
		return
	end
	self.isInAction = true

	if	self:getPositionX() - self.info.atk_check_dis <= self.curTarget:getPositionX() + self.curTarget.info.rect_x + self.curTarget.info.rect_width then
	   	self:changeStatus(Monster.statusType.STATUS_ATTACK,1)
	   	if self.info.skill0_id > 0 then
			self.skill = Skill.create({class_id = self.info.skill0_id})
		end
	end

end



function Monster:checkAi()
	if self.status == Monster.statusType.STATUS_DEAD or self.curHp <= 0 then
		self:destroy()
		return
	end
	self.isInAction = false
	self.isInSkill = false
	if self.status ~= Monster.statusType.STATUS_MOVE then
		self:changeStatus(Monster.statusType.STATUS_WAIT,1)
	end
end

--need add--
function Monster:damageWithBullet(params)
	
	if params == nil then
		return
	end
	self:toDamageStatus()
	local dmgValue = 0
	local isBaoJi = false
	if params.emanate == nil  then
		dmgValue = tonumber(params.dmgValue + 5 - math.random(5))
	else
		self.emanate = params.emanate
		local baseAtk = tonumber(params.dmgValue + 5 - math.random(5))
	    --伤害 =  攻击力 * ( 1 + 暴击加成 * ( 1 - 韧性 ) ) * ( 1 - ( 防御力 / ( 防御力 + 防御力参数 ) ) * ( 1 - 破甲 ) )
	    isBaoJi  = (math.random(10000) <= params.emanate.baoJiRate) and true or false
		local baoJiAdd =  isBaoJi and  params.emanate.baoJiAtk/10000.0 or 0
	    dmgValue = baseAtk * (1 + baoJiAdd *(1 - self.tenacity/10000.0))*(1 - (self.deff/(self.deff + 1250.0))*(1 - params.emanate.poJia/10000.0))
	end
    self:damage(isBaoJi and 1 or 2,dmgValue)
 	self:addHp(-dmgValue)
 	MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_COMBO,{target = self})
end

function Monster:damageWithBuff(params)

	--dump(params)
	if params.buff == nil  then
		return
	end
	self.emanate = params.emanate
    self:toDamageStatus()
    local baseAtk  = tonumber(params.buff.info.once_atk_rate/10000.0 * params.emanate.atk + params.buff.info.once_atk + 5 - math.random(5))
    --伤害 =  攻击力 * ( 1 + 暴击加成 * ( 1 - 韧性 ) ) * ( 1 - ( 防御力 / ( 防御力 + 防御力参数 ) ) * ( 1 - 破甲 ) )
    local isBaoJi  = (math.random(10000) <= params.emanate.baoJiRate) and true or false
	local baoJiAdd =  isBaoJi and  params.emanate.baoJiAtk/10000.0 or 0
    local dmgValue = baseAtk * (1 + baoJiAdd *(1 - self.tenacity/10000.0))*(1 - (self.deff/(self.deff + 1250))*(1 - params.emanate.poJia/10000.0))
    self:damage(isBaoJi and 1 or 2,dmgValue)
    self:addHp(-dmgValue)
    MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_COMBO,{target = self})
    return dmgValue
end

function Monster:damageWithExSkill(params)

	self:toDamageStatus()
    local baseAtk = params.dmgValue
    self.emanate = params.emanate
    --伤害 =  攻击力 * ( 1 + 暴击加成 * ( 1 - 韧性 ) ) * ( 1 - ( 防御力 / ( 防御力 + 防御力参数 ) ) * ( 1 - 破甲 ) )
    local isBaoJi  = (math.random(10000) <= params.emanate.baoJiRate)  and true or false
	local baoJiAdd =  isBaoJi and  params.emanate.baoJiAtk/10000.0 or 0
    local dmgValue = baseAtk * (1 + baoJiAdd *(1 - self.tenacity/10000.0))*(1 - (self.deff/(self.deff + 1250))*(1 - params.emanate.poJia/10000.0))

    self:damage(isBaoJi and 1 or 2,dmgValue)
    --扣血是真实的本体掉血
    self.cloneRoot:addHp(-dmgValue)
end

function Monster:getRect()

	local rt = cc.rect(self:getPositionX()-self.info.rect_x,
				self:getPositionY()+self.info.rect_y,
				self.info.rect_width,
				self.info.rect_height)
	return rt
end
function Monster:addHp(value)
	if self.curHp <= 0 then
		return
	end
   	self.curHp = self.curHp + value
   	self:flash()
	if self.curHp <= 0 then
 		self.curHp = 0
 		if self.emanate and self.emanate.type  == Monster.roleType.ROLE_TYPE_SOUL then
			self.emanate:addExSkillPoint(self.emanate.spInfo.killAddNum)
			--print("------------------addKillNum:"..self.emanate.spInfo.killAddNum)
		end
 		if self.objType == Monster.OBJ_TYPE.BOMB then
 			self:changeStatus(Monster.statusType.STATUS_WAIT,1)
 		else
 			self:changeStatus(Monster.statusType.STATUS_DEAD,1)
 			if self.objType ~= Monster.OBJ_TYPE.MONSTER and self.objType ~= Monster.OBJ_TYPE.BOSS then
 				local i = 1
 				while battleManager.trapPool[i] do
 					--dump(battleManager.trapPool[i].otherHalfObj)
		    		if battleManager.trapPool[i].otherHalfObj == self then
		    			local trap = battleManager.trapPool[i]
		    			table.remove(battleManager.trapPool,i)
		    			trap:destroy()
		    			--print(">>>>>>>>>>>>>>>>>>>>>>>table.remove(battleManager.trapPool,i)")
		    		else
		    			i= i+1
		    		end
		    	end
		    else
		    	--记录杀怪数
		    	battleManager:addKillNum(1)
		    	battleManager.isKilledTarget = battleManager:checkTargetDead(self)

 			end
 		end

 		local i = 1
    	while battleManager.monsterPool[i] do
    		if battleManager.monsterPool[i] == self then
    			if battleManager.target == self then
    				battleManager.target = nil
    			end
    			table.remove(battleManager.monsterPool,i)
    			break
    		else
    			i= i+1
    		end
    	end
    	--print("monster  num:"..#battleManager.monsterPool ..">>>>> trapPool num:"..#battleManager.trapPool)
 	end
end

-- [怪受伤状态切换，惟一入口]
function Monster:toDamageStatus()

	if self.status == Monster.statusType.STATUS_DEAD or self.status == Monster.statusType.STATUS_DMG then
		return
	end

	if self.isInAction == false and self.isInSkill == false and self.isInAi == false and self.curHp > 0  then
		if self.hpBar then
			self.hpBar:show()
		end
		self:changeStatus(Monster.statusType.STATUS_DMG,1)
		if self.objType == BaseRole.OBJ_TYPE.BOSS then
			MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.PROCESS_BOSS,{status = "DMG",obj = self})
		end
	end
end

function Monster:hitBack(backDisValue) 

	if self.isInAction then
		return
	end
	local  move = cc.MoveBy:create(0.3,cc.p(backDisValue,0))
	self:runAction(move)
end

--need add --
function Monster:destroy()
	self:unschedule()
	if self.shadow then
		self.shadow:setVisible(false)
	end
	if self.objType == BaseRole.OBJ_TYPE.BOSS then
		MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.PROCESS_BOSS,{status = "DEAD",obj = self})
	end
	--add drop goods
	if self:checkInScreen() and self.dropId > 0 then
		--local pos = cc.p(battleManager.cameraPos.x + self:getPositionX(),battleManager.cameraPos.y + self:getPositionY())
		-- MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_DROP,{type = self.dropId,value = 10,pos = cc.p(self:getPosition())})
	end

	local fadeout = cc.FadeOut:create(0.5)
	self:setCascadeOpacityEnabled(true)
	local action = cc.Sequence:create(fadeout,cc.CallFunc:create(function()
			self:setVisible(false)
			self:removeFromParent()
		end))
	self:runAction(action)
end

--自爆必死处理
function Monster:bomb()
	self:setVisible(false)
	self:addHp(-self.info.hp)
end
--陷阱处理
--[[
	一、栅栏特殊性处理:
	1.可以被破坏；
	2.不可以被硬冲穿过（只能滑或跳过）；
	3.滑过者zorder小于栅栏；
	二、电力网处理：
	1.不可以被破坏；
	2.靠近会掉血；
	3.不可以被硬冲穿过（只能滑或跳过）；
	4.滑过者zorder小于栅栏；
]]
function Monster:trapLogic()

	--怪物出左屏自动消毁处理（防错）
	if (self:getPositionX() + battleManager.cameraPos.x < -32) then
		self:bomb()
		--print("超屏 自爆处理〜")
		return
	end
	if (self.objType == Monster.OBJ_TYPE.MONSTER or self.objType == Monster.OBJ_TYPE.BOSS) or nil == self.curTarget or self.curHp <=0 then
		self:setLocalZOrder(display.height-self:getPositionY())
		return
	end

	if (self.objType == Monster.OBJ_TYPE.BOMB) then
		if self:collideWithRect(self.curTarget:getRect()) then
			self:toDamageStatus()
		end
	else
		self.shadow:setVisible(false)
		if (self.objType == Monster.OBJ_TYPE.BARRIER) then
			if self.curTarget.status ~= Monster.statusType.STATUS_SKITE  and
		   		self.curTarget.status ~= Monster.statusType.STATUS_JUMP then
		   		self:blockHero()
			end
		end
	end
end

--阻碍主角移动
function Monster:blockHero()
	-- 
	if self.curTarget:getPositionX() + 96 > self:getPositionX() and (self.objType == BaseRole.OBJ_TYPE.MONSTER or self.objType == BaseRole.OBJ_TYPE.BOSS 
		or (self:collideWithRect(self.curTarget:getRect()) and  self.objType == BaseRole.OBJ_TYPE.BARRIER)) then
		self.curTarget:setPositionX(self:getPositionX() - 96)
	end
end


--[[[
	1、发动技能
	2、自身以2倍主角移动速度移动到屏幕最右侧后施放技能，技能施放过程完成后回到正常状态
--]]
function Monster:onAiUpdate(dt)

	--[触发条件：0、直接触发 ; 1、自身血量在一定比例以下（万分率）]
	if self.aiInfo == nil or self.curHp <= 0 or battleManager.isAoyiAction then
		return
	end
	self.aiCd = self.aiCd - dt*1000
	if self.isInAi then
		self:setPosition(cc.p(display.width - battleManager.cameraPos.x-160,self:getPositionY()))
		--print("boss 靠近边")
	end
	if self.aiInfo.active_condition == 0 then
		
	elseif self.aiInfo.active_condition == 1 then
		if  self.curHp <= self.info.hp*(self.aiInfo.condition_value/10000.0) and self.aiCd <= 0 then
			--print("Monster hp < 50% ..exe ai.. ")
			self.aiCd = self.aiInfo.active_cd
			self:changeStatus(Monster.statusType.STATUS_MOVE,2)
			local moveTo = cc.MoveBy:create(0.5, cc.p(display.width - (self:getPositionX() + battleManager.cameraPos.x)-160 ,0))
			local callBack = cc.CallFunc:create(function()
						
					self.isInAi = true
					--有次数限制[0:无限 ，>0 次数]
					if  self.aiInfo.active_times == 0 then
						if self.aiInfo.active_event == 1 then
							self:toSkill()
						elseif self.aiInfo.active_event == 2 then
							self:toSkill()
						end
					else
						self.activeTimes = self.activeTimes + 1
						if self.activeTimes >= self.aiInfo.active_times then
							activeTimes = 0
							self:unschedule(self.aiSchedule)
						else
							--[1、发动技能 2、自身以2倍主角移动速度移动到屏幕最右侧后施放技能，技能施放过程完成后回到正常状态]
							if self.aiInfo.active_event == 1 then
								self:toSkill()
							elseif self.aiInfo.active_event == 2 then
								self:toSkill()
							end
						end
					end

				end)
			self:runAction(cc.Sequence:create(moveTo,callBack,cc.DelayTime:create(self.aiInfo.keep_time/1000.0),cc.CallFunc:create(function() 
				self.isInAi = false
			end),nil))
		end
	end
end

function Monster:toSkill()

	if true == self.isInSkill then
		return
	end
	self.isInSkill = true
	self:changeStatus(Monster.statusType.STATUS_SKL,1)
	if self.aiInfo.active_value > 0 then
		self.skill = Skill.create({class_id = self.aiInfo.active_value})
		--dump(self.skill.info)
	end

end


return Monster

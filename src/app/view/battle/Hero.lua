local CURRENT_MODULE_NAME = ...
-- classes
local AnimationNode         = import("..controls.CocostudioNode")
local BaseRole = import(".BaseRole",CURRENT_MODULE_NAME)
local HeroData = import("...data.information.HeroData",CURRENT_MODULE_NAME)
local Skill = import(".Skill",CURRENT_MODULE_NAME)
local Effect = import("..controls.EffectManager", CURRENT_MODULE_NAME)
-- singleton
local resManager 	= import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local playerManager = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()
local infoManager 	= import("...data.information.InfoManager",CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager",CURRENT_MODULE_NAME):getInstance()

local Hero 	   = class("Hero", BaseRole)

function Hero.createWithId( id )
	return Hero.new({id = id,onUi = false})
end

function Hero.createOnUiWithId(id)
	return Hero.new({id = id,onUi = true})
end

--need add
function Hero:ctor(params)

	self.pb   = playerManager.heros[params.id]
	--dump(self.pb)

	self.info = self.pb.info
	--dump(self.info)

	--获取角色信息（基础）
	self.rolePb = nil
	--dump(self.rolePb)

	local jsonName = resManager:getResPath(self.info.avatar_id)
	params.jsonName = string.sub(jsonName,0,string.len(jsonName)-3)..".json"
	params.atlasName = resManager:getResPath(self.info.avatar_id)..".atlas"


	Hero.super.ctor(self, params)
	self:enableNodeEvents()

	self.isOnUi = params.onUi
	--dump(self.isOnUi)

	--dump(self.rolePb)
	self.curSp = 0

	self.type  = Hero.roleType.ROLE_TYPE_HERO

	self.height = self.info.rect_height
	
	self.curSpeed = self.info.speed

	self.recSpeed = self.curSpeed

	self.scale = self.info.scale
	self:setScaleEx(self.scale)
	
	self:setDir(Hero.dirType.DIR_RIGHT)
	self:changeStatus(Hero.statusType.STATUS_WAIT,1)
	self.skill  = Skill.create({class_id = self.info.skill0_id})

	self:updateRolePbWithLevel(self.pb.level)


	--[主角处于跳｜滑｜冲 等 状态时，任何外界都不能打断此状态（可以受伤但不改变）]
	self.isInAction = false
	self.isInAtk    = false

	self:setSpineEventListener()

  	--dump(self.info)
	self.moveEff 	= Effect.createWithId(self.info.move_eff_id):addTo(self):setVisible(false)
 	self.skiteEff	= Effect.createWithId(self.info.skite_eff_id):addTo(self):setVisible(false)
	self.fastEff 	= Effect.createWithId(self.info.fast_eff_id):addTo(self):setVisible(false)

	-- 	local rt = cc.rect(self.info.rect_x,
	-- 					self.info.rect_y,
	-- 					self.info.rect_width,
	-- 					self.info.rect_height)
	-- girl.createTestRect(rt):addTo(self)
end

--根据等级获取最
function Hero:updateRolePbWithLevel(level)
	self.rolePb = infoManager:findInfo("roles","class_id",level)
	self.equipInfo = {}
	--[[
	1、攻击
	2、破甲
	3、防御
	4、韧性
	5、血量
	6、暴率
	7、暴伤
	--]]
	local atkAdd = 0
	local poJiaAdd= 0
	local deffAdd = 0
	local tenacityAdd = 0
	local curHpAdd = 0
	local baoJiRateAdd =0
	local baoJiAtkAdd = 0
	for i=1,#self.pb.intensify do
		
		local equip 	= infoManager:findInfo("equipments","class_id",self.pb.intensify[i].class_id)
		local intensify = infoManager:findInfo("eqIntensifys","class_id",self.pb.intensify[i].intensifyId)
		-- dump(equip)
		-- dump(intensify)
		--属性1--(强化值 ＝ 装备强化值 ＋ 装备基础值)
		local intensify1Value = equip.proValue1 +  equip.deltaValue1 * (intensify.percent/10000.0)
		if equip.proType1 == 1 then
			atkAdd = atkAdd + intensify1Value
		elseif equip.proType1 == 2 then
			poJiaAdd = poJiaAdd + intensify1Value
		elseif equip.proType1 == 3 then
			deffAdd = deffAdd  + intensify1Value
		elseif equip.proType1 == 4 then
			tenacityAdd = tenacityAdd + intensify1Value
		elseif equip.proType1 == 5 then
			curHpAdd = curHpAdd+ intensify1Value
		elseif equip.proType1 == 6 then
			baoJiRateAdd = baoJiRateAdd + intensify1Value
		elseif equip.proType1 == 7 then
			baoJiAtkAdd = baoJiAtkAdd + intensify1Value
		end

		--属性2--(强化值 ＝ 装备强化值 ＋ 装备基础值)
		local intensify2Value = equip.proValue2 +  equip.deltaValue2 * (intensify.percent/10000.0)
		if equip.proType2 == 1 then
			atkAdd = atkAdd + intensify2Value
		elseif equip.proType2 == 2 then
			poJiaAdd = poJiaAdd + intensify2Value
		elseif equip.proType2 == 3 then
			deffAdd = deffAdd + intensify2Value
		elseif equip.proType2 == 4 then
			tenacityAdd = tenacityAdd + intensify2Value
		elseif equip.proType2 == 5 then
			curHpAdd = curHpAdd + intensify2Value
		elseif equip.proType2 == 6 then
			baoJiRateAdd = baoJiRateAdd + intensify2Value
		elseif equip.proType2 == 7 then
			baoJiAtkAdd = baoJiAtkAdd + intensify2Value
		end
	end
	self.atk = self.info.atk_rate/10000.0 * self.rolePb.atk + atkAdd
	self.deff = self.info.deff_rate/10000.0 * self.rolePb.deff + deffAdd
	self.baoJiRate = self.info.baoJi_per_rate/10000.0 * self.rolePb.baoJi_rate + baoJiRateAdd  --暴击率
	self.baoJiAtk = self.info.baoJi_rate/10000.0 * self.rolePb.baoJi + baoJiAtkAdd            --暴击伤害率
	self.poJia = self.info.poJia_rate/10000.0 * self.rolePb.poJia + poJiaAdd 
	self.tenacity = self.info.tenacity_rate/10000.0 * self.rolePb.tenacity + tenacityAdd
	self.topHp = self.info.hp_rate/10000.0 * self.rolePb.hp + curHpAdd
	self.curHp = self.topHp

	print(string.format("self.atk:%d, self.deff:%d, self.baoJiRate:%d, self.baoJiAtk:%d, self.poJia:%d, self.tenacity:%d,  self.curHp:%d,topHp:%d"
		,self.atk,self.deff,self.baoJiRate,self.baoJiAtk,self.poJia,self.tenacity,self.curHp,self.topHp))
end

function Hero:updateSelf( dt )
	self.super.updateSelf(self,dt)
	self:checkUpdate(dt)
	self:checkAttackUpdate(dt)
	self:collideBulletUpdate(dt)
	self:setLocalZOrder(display.height-self:getPositionY())
end

function Hero:collideWithRect(rect)

	--dump(size)
	local rt = self:getRect()
	return cc.rectIntersectsRect(rt,rect)
end

function Hero:collideWithBullet(bullet)

	--dump(bullet.lastPos)
	local pt1 = cc.p(bullet.lastPos)
	local pt2 = cc.p(bullet:getPosition())

	local size = cc.size(bullet.info.width,bullet.info.height)


	local rt1 = cc.rect(pt1.x-size.width/2.0,pt1.y -size.height/2.0,size.width,size.height)

	local rt2 = cc.rect(pt2.x-size.width/2.0,pt2.y -size.height/2.0,size.width,size.height)
	local rect  =  cc.rectUnion(rt1,rt2)
	--dump(rect)
	return self:collideWithRect(rect)
end

-- [主角受伤状态切换，惟一入口]
function Hero:toDamageStatus()

	if self.status == Hero.statusType.STATUS_DEAD or self.status == Hero.statusType.STATUS_DMG then
		return
	end 
	if self.isInAction == false and self.isInAtk == false then

		self:changeStatus(Hero.statusType.STATUS_DMG,1)
	end

end

function Hero:collideBulletUpdate(dt)

	if self.curHp <= 0 then
		return
	end 
    for _,v in ipairs(battleManager.bulletPool) do
    	--[[checkMod:
		-- 0、无效
		-- 1、对对象和地面判定
		-- 2、对地面判定]]
		if v.camp == Hero.campType.CAMP_MONSTER and v.checkMod == 1 then --敌方子弹
			
            if self:collideWithBullet(v) == true then
				self:damageWithBullet(v)
				if v.info.atkMusicId>0 then
					musicManager:play(v.info.atkMusicId)
				end
             	--print("碰撞到了")
				if v.info.hitEffId>0 then
					local eff = Effect.createWithId(v.info.hitEffId):addTo(self,1)
						eff:setPosition(-32+math.random(64),32+math.random(64))
					 	eff:runAnimation(eff.DefaultAnimation,false, function()
				 		eff:destroy()
				 	end)
				end
               	if v.crossTimes <= 0 then
					v:destroy()
				else
					v.crossTimes = v.crossTimes -1
				end
				
       		end
		end
	end

end

--need add--
function Hero:damageWithBullet(bullet)
	
	if bullet == nil then
		return
	end
	self:toDamageStatus()
	local dmgValue = 0
	local isBaoJi = false
	if bullet.emanate == nil  then
		dmgValue = tonumber(bullet.dmgValue + 5 - math.random(5))
	else
		local baseAtk = tonumber(bullet.dmgValue + 5 - math.random(5))
	    --伤害 =  攻击力 * ( 1 + 暴击加成 * ( 1 - 韧性 ) ) * ( 1 - ( 防御力 / ( 防御力 + 防御力参数 ) ) * ( 1 - 破甲 ) )
	    isBaoJi  = (math.random(10000) <= bullet.emanate.baoJiRate)  and true or false
		local baoJiAdd =  isBaoJi and  bullet.emanate.baoJiAtk/10000.0 or 0
	    dmgValue = baseAtk * (1 + baoJiAdd *(1 - self.tenacity/10000.0))*(1 - (self.deff/(self.deff + 1250))*(1 - bullet.emanate.poJia/10000.0))
	end

    self:damage(isBaoJi and 1 or 2,dmgValue)
 	self:addHp(-dmgValue)

end

function Hero:damageWithBuff(params)

	if params.buff == nil  then
		return
	end
    self:toDamageStatus()

    local baseAtk = tonumber(params.buff.info.once_atk_rate/10000.0 * params.emanate.atk + params.buff.info.once_atk + 5 - math.random(5))
    --伤害 =  攻击力 * ( 1 + 暴击加成 * ( 1 - 韧性 ) ) * ( 1 - ( 防御力 / ( 防御力 + 防御力参数 ) ) * ( 1 - 破甲 ) )
    local isBaoJi  = (math.random(10000) <= params.emanate.baoJiRate)  and true or false
	local baoJiAdd =  isBaoJi and  params.emanate.baoJiAtk/10000.0 or 0
    local dmgValue = baseAtk * (1 + baoJiAdd *(1 - self.tenacity/10000.0))*(1 - (self.deff/(self.deff + 1250))*(1 - params.emanate.poJia/10000.0))

    self:damage(isBaoJi and 1 or 2,dmgValue)
    self:addHp(-dmgValue)
    return dmgValue
end

function Hero:getRect()

	local rt = nil
	if self.status == Hero.statusType.STATUS_SKITE then
		rt = cc.rect(self:getPositionX()+self.info.rect_x,
					self:getPositionY()+self.info.rect_y,
					self.info.rect_width,
					self.info.rect_height/2)
	else
		rt = cc.rect(self:getPositionX()+self.info.rect_x,
					self:getPositionY()+self.info.rect_y,
					self.info.rect_width,
					self.info.rect_height)
	end
	return rt

end

function Hero:spineCallBack(events)
	-- body
	self.fireOrder = 1
	if events.type == girl.AnimationNodeEventType.ANIMATION_COMPLETE then
		self:checkAi()
	end
end

function Hero:setSpineEventListener( )

	self:setFrameEventCallFunc({_all = function ( name, params)
		--print("{Hero}:"..name) -- name == jumpF
		--print("{Hero}:"..param.."name :"..name)
		if name == "music" then

		elseif name == "fire" then
			local param = params.stringValue
			local  tmpStr  = string.split(param,"#")
			local  data    = table.values(tmpStr)
			local  type  = tonumber(data[1])  -- [1:子弹表，2:buff表]
			local  id  	 = tonumber(data[2])
			--printInfo("{Hero: fire type:}"..type)
			--printInfo("{Hero: fire id:}"..id)
			--dump(self.skill.info)
			if type == 1 then
				MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BULLET_ADD,{emanate = self,bulletId = id,camp = Hero.campType.CAMP_HERO,order = self.fireOrder})
				self.fireOrder = self.fireOrder + 1
			elseif type == 2 then
				--printInfo("{Hero}type:"..type)
				MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = self,buffId = id,camp = Hero.campType.CAMP_HERO,order = self.fireOrder})
				self.fireOrder = self.fireOrder + 1
			end

		end

	end})
end

function Hero:randNormalAtk()

	self:changeStatus(Hero.statusType.STATUS_ATTACK,1)
	self.isInAtk = true
	
end

function Hero:toFastMoveCb()

	self.isInAction = false
	self.isInAtk = false
	self.fastEff:setVisible(false)
	self.skiteEff:setVisible(false)

end

function Hero:toFastMove()

	if 	self.isInAction or self.status == Hero.statusType.STATUS_DEAD then
		return
	end
	self.isInAction = true
	musicManager:play(self.info.fast_eff_music_id)

	-- self:stopAllActions()
	self:setDir(Hero.dirType.DIR_RIGHT)
	self:changeStatus(Hero.statusType.STATUS_FAST,1)

	self.fastEff:setVisible(true)

	local actions = cc.CallFunc:create(function()
					self:toFastMoveCb()
				end)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),actions))

end


function Hero:toSkite()

	if 	self.isInAction or self.status == Hero.statusType.STATUS_DEAD then
		return
	end
	self.isInAction = true
	-- self:stopAllActions()
	self:setDir(Hero.dirType.DIR_RIGHT)
	self:changeStatus(Hero.statusType.STATUS_SKITE,1)

	local actions = cc.CallFunc:create(function()
					self:toFastMoveCb()
				end)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),actions))
	self.skiteEff:setVisible(true)
end

function Hero:toJump()

	if 	self.isInAction or self.status == Hero.statusType.STATUS_DEAD then
		return
	end
	self.isInAction = true
	-- self:stopAllActions()
	self:setDir(Hero.dirType.DIR_RIGHT)

    local action1 = cc.CallFunc:create(function()
          self:changeStatus(Hero.statusType.STATUS_JUMP,1)
        end)

    local moveup =  cc.JumpTo:create(0.5,cc.p(self:getPositionX(),self:getPositionY()),180,1)

    local action2 = cc.CallFunc:create(function()
        -- self:changeStatus(Hero.statusType.STATUS_JUMP,2)
		self:runAnimation(string.format("JUMP%d",2+self.step*10),false,{onComplete = function()
				self:toFastMoveCb()
         		self:toCheckNextStep()
			end})
	 end)
    local action1_ = cc.Spawn:create(action1,moveup)
    self:runAction(cc.Sequence:create(action1_,action2))

	---跳动时影子
    local scale = cc.ScaleTo:create(0.25,0.1)
    local scaleback = cc.ScaleTo:create(0.25, self.shadowScale)
    local action1 = cc.Sequence:create(scale,scaleback,nil)
    self.shadow:runAction(action1)
    local move1 = cc.MoveBy:create(0.25, cc.p(0,96))
    local moveback1 = cc.MoveBy:create(0.25, cc.p(0,-96))
    self.shadow:runAction(cc.Sequence:create(moveback1,move1,nil))

end

local isWin = false
function Hero:checkAi()

	if 	self.isInAction or self.status == Hero.statusType.STATUS_DEAD then
			return
	end
	if self.curTarget then

		isWin = false
		self.isInAtk = false
		if (self.status ~= Hero.statusType.STATUS_DEAD and self.status ~= Hero.statusType.STATUS_DMG) then

			self:toCheckNextStep()
		else
			self:toMove()
		end
	else
		
		if battleManager.battleResultCode == 1 or self.isOnUi then

			if (isWin == false and self.isOnUi == false) then
				isWin = true
				self:changeStatus(Hero.statusType.STATUS_WIN,1)

				printInfo("[Hero]: STATUS_WIN")
			else
				self:changeStatus(Hero.statusType.STATUS_WAIT,1)
			end

		else
			self:changeStatus(Hero.statusType.STATUS_MOVE,1)
		end
	end

end

function Hero:toMove()
	
	if false == self.isInAtk then
		-- self:stopAllActions()
		self:changeStatus(Hero.statusType.STATUS_MOVE,1)
	end
	
end

function Hero:toCheckNextStep()

	if self.status == Hero.statusType.STATUS_DEAD then
		return
	end
	if self.curTarget then
		if self.dir == Hero.dirType.DIR_RIGHT and
		   	self:getPositionX()+ self.info.atk_check_dis >= self.curTarget:getPositionX() -  self.curTarget.info.rect_x and
		   	self:getPositionX() <  self.curTarget:getPositionX() then ---背后的目标是无法攻击的
			self:randNormalAtk()
		else
		   	self:toMove()
		end
	else
		self:toMove()
	end
end

function Hero:checkAttackUpdate(dt)
	-- body
	--print("func checkAttackUpdate")
	if self.curTarget == nil then

		self:checkAi()
		return
	end
	if 	self.isInAction == false then

		self:toCheckNextStep()
	end
end

function Hero:checkUpdate(dt)

	--print("Hero checkUpdate"..self.status)
	-- recSpeed = self.curSpeed
	if self.status == Hero.statusType.STATUS_MOVE then
			self.moveEff:setVisible(true)
	else
			self.moveEff:setVisible(false)
	end

	if self.status == Hero.statusType.STATUS_MOVE or
		self.status == Hero.statusType.STATUS_FAST or
		self.status == Hero.statusType.STATUS_SKITE or
		self.status == Hero.statusType.STATUS_JUMP
	 then
	 	if 	self.isInAction == true then
	 		self.curSpeed = self.recSpeed*2
	 	else
	 		self.curSpeed = self.recSpeed
	 	end
	 	self:setPositionX(self:getPositionX()+dt*self.curSpeed)
	end
	if self.curTarget and (self.curTarget.objType == BaseRole.OBJ_TYPE.MONSTER or self.curTarget.objType == BaseRole.OBJ_TYPE.BOSS) then
		if false == battleManager.isPushMonster and self:getPositionX() + 64 > self.curTarget:getPositionX() then
			self:setPositionX(self.curTarget:getPositionX()-64)
		end
	end
	--边缘处理（不往后退出屏外处理，与地图尽头极端处理不同）
	if (self:getPositionX() + battleManager.cameraPos.x < 100) then
		self:setPositionX(100 - battleManager.cameraPos.x)
	elseif (self:getPositionX() + battleManager.cameraPos.x > display.width*0.6) then
		self:setPositionX(display.width*0.6 - battleManager.cameraPos.x)
	end
end

function Hero:addHp(value)
	local value = math.floor(value)
	if self.curHp<=0 and  value <= 0 then
		self.curHp = 0
		return
	end
	---加血--
	if value > 0 then
		MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_HP_EFF,{addNumText = "HP+"..value,addValue = value})
	end

	self.curHp = self.curHp + value
	self:flash()
	if self.curHp <= 0 then
 		self.curHp = 0
 		self:changeStatus(Hero.statusType.STATUS_DEAD,1)
		self.isInAction = false
		self.isInAtk 	= false
 		battleManager.battleResultCode = 0
 		print("-------Hero Dead---")
 	elseif self.curHp >= self.topHp then
 		self.curHp = self.topHp
    end
end

function Hero:addSp(value)
	self.curSp = self.curSp + value
	if self.curSp <= 0 then
 		self.curSp = 0
 	elseif self.curSp>=100 then
 		self.curSp = 100
    end
end

function Hero:hitBack(backDisValue)

	if self.isInAction then
		return
	end
	-- self:stopAllActions()
	local  move = cc.MoveBy:create(0.3,cc.p(backDisValue,0))
	self:runAction(move)
end

function Hero:onEnter()
end


return Hero

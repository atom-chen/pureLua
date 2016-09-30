local CURRENT_MODULE_NAME = ...
-- classes
local BaseRole 	= import(".BaseRole",CURRENT_MODULE_NAME)
local SoulData 	= import("...data.information.SoulData", CURRENT_MODULE_NAME)
local Skill    	= import(".Skill", CURRENT_MODULE_NAME)
local infoMgr 	= import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local Buff    	= import(".Buff", CURRENT_MODULE_NAME)


--singleton
local resManager 	= import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local playerManager = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager",CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory"):getInstance()

local Soul 	   = class("Soul", BaseRole)


function Soul.createWithId( id )
	return Soul.new({id = id,onUi = false})
end

function Soul.createOnUiWithId(id)
	return Soul.new({id = id,onUi = true})
end

--need add

function Soul:ctor(params)
	-- dump(params)
	-- dump(playerManager.souls)
	if params.onUi then
	   self.info = SoulData.findInfo(params.id)
	else
	   self.pb   = playerManager.souls[params.id]
	   self.info = self.pb.info
	end
	--self.pb   = playerManager.souls[params.id]
	--self.info = self.pb.info

	self.exSkillInfo = infoMgr:findInfo("exSkills","class_id",self.info.class_id)
	--dump(self.exSkillInfo)
	self.spInfo = infoMgr:findInfo("sps","class_id",1)
	-- dump(self.spInfo)

	local jsonName = resManager:getResPath(self.info.avatar_id)
	--print(jsonName)
	params.jsonName = string.sub(jsonName,0,string.len(jsonName)-3)..".json"
	params.atlasName = resManager:getResPath(self.info.avatar_id)..".atlas"

	Soul.super.ctor(self, params)
	self:enableNodeEvents()

	self.posId = 1
	self.type  = Soul.roleType.ROLE_TYPE_SOUL
	self.followerTarget = nil
	self.isInAtk 		= false 	--是否普攻技能(可以被玩家发技能打断)
	self.isInSkill 		= false 	--是否使用技能(技能状态是不能被打断)
	self.isInExSkill	= false     --是否使用大招
	self.scale 			= 1
	self.isCanExskill   = false
	self.atk 			= 0
	self.skillMasterValue = {} 		--技能精通值
	self:setScaleEx(self.scale)
	--元神基础攻击伤害值 ＝ 突破atk + 进阶表里攻击力成长值(atk*level) + 当前强化值(每次变化量相加值) ＋。。。

	if params.onUi == false then
		self:loadSoulAllInfo()
	end
	--self:loadSoulAllInfo()

	self:setDir(Soul.dirType.DIR_RIGHT)
	self:changeStatus(Soul.statusType.STATUS_WAIT,1)
	self:setSpineEventListener()

	--普通攻击冷却时间
	-- self.atkTimeDt = cc.Label:createWithTTF("0", "fonts/STHeiti-Medium_1.ttf", 28)
	-- self:addChild(self.atkTimeDt,1000)
	-- self.atkTimeDt:setPositionY(self:getCascadeBoundingBox().height+32)


end

--根据等级获取最
function Soul:loadSoulAllInfo()

	--元神基础攻击伤害值 ＝ 突破atk + 进阶表里攻击力成长值(atk*level) + 当前强化值(每次变化量相加值) ＋。。。
	local breachId = tonumber(self.pb.class_id.."0"..self.pb.star)
    self.breachInfo= infoMgr:findInfo("breachs","class_id",breachId)
    local coldTime = infoMgr:findInfo("skills","class_id",self.breachInfo.skill0_id).coldTime

    --强化&突破
    local info = self.pb.intensifys
    --dump(info)
  	local intensifysTable = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}
   	--dump(intensifysTable)
   	
   	if info.atkId%100 ~= 0 then
   		local intensifyInfo1 		= infoMgr:findInfo("intensifys","class_id",info.atkId) --攻击值
   		self.atk 					= self.info.base_attack + self.breachInfo.atk * self.pb.level + intensifyInfo1.atkValue
   	else
   		self.atk 					= self.info.base_attack + self.breachInfo.atk * self.pb.level
   	end
   	if info.speedId%100 ~= 0 then
   		local intensifyInfo2 		= infoMgr:findInfo("intensifys","class_id",info.speedId)--攻速
   		self.normalAtkColdTimeMax 	= coldTime - (self.breachInfo.atkSpeed + intensifyInfo2.speedValue)
   	else
   		self.normalAtkColdTimeMax 	= coldTime - (self.breachInfo.atkSpeed)
   	end
   	if info.perId%100 ~= 0 then
   		local intensifyInfo3 		= infoMgr:findInfo("intensifys","class_id",info.perId)--暴击率
   		self.baoJiRate 				= self.breachInfo.baoJi + intensifyInfo3.perValue
   	else
   		self.baoJiRate 				= self.breachInfo.baoJi
   	end
   	if info.valueId%100 ~= 0 then
   		local intensifyInfo4 		= infoMgr:findInfo("intensifys","class_id",info.valueId)--暴击伤害率
   		self.baoJiAtk  				= self.breachInfo.baoJiAtk  + intensifyInfo4.dmgValue
   	else
   		self.baoJiAtk  				= self.breachInfo.baoJiAtk
   	end
   	if info.armorId%100 ~= 0 then
   		local intensifyInfo5 		= infoMgr:findInfo("intensifys","class_id",info.armorId)--破甲
   		self.poJia 	   				= self.breachInfo.poJia + intensifyInfo5.armorValue
   	else
   		self.poJia 	   				= self.breachInfo.poJia
   	end
   	if info.masterId%100 ~= 0 then
   		local intensifyInfo6 		= infoMgr:findInfo("intensifys","class_id",info.masterId)
   		self.skillMasterValue[self.info.skill_type] = self.breachInfo.skill_master +intensifyInfo6.masterValue 	--技能精通值
  	else
   		self.skillMasterValue[self.info.skill_type] = self.breachInfo.skill_master
   	end

    --以下为计算配件加成的属性--------------------------------------------------------------------------
    for k,v in girl.pairsByKeys(playerManager.souls[self.pb.class_id].assemblages) do
      print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self["assemblage"..v.order] = infoMgr:findInfo("assemblages","class_id",v.class_id)
    end

   self.skillColdTimeMax 		= infoMgr:findInfo("skills","class_id",self.breachInfo.skill1_id).coldTime --技能冷却最高值（一般情况是技能表codeTime）
 


   --攻击力，普攻CD，暴击率，暴击伤害，破甲，技能CD
   self.valueTable = {self.atk,self.normalAtkColdTimeMax,self.baoJiRate,self.baoJiAtk,self.poJia,self.skillColdTimeMax}

    for i=1,4 do
      --  print("第%d次循环",i)
        if self["assemblage"..i] then

          if self["assemblage"..i].attributeType <= 6 then
              if self["assemblage"..i].attributeType == 2 then
                 self.valueTable[2] = self.valueTable[2] * (1-self["assemblage"..i].attributeValue/10000)
              else
                 self.valueTable[self["assemblage"..i].attributeType] = self.valueTable[self["assemblage"..i].attributeType] * (1+self["assemblage"..i].attributeValue/10000)
              end

          elseif self["assemblage"..i].attributeType ==8 then
             print("普攻攻速，技能cd")
             self.valueTable[2] = self.valueTable[2] * (1-self["assemblage"..i].attributeValue/10000)
             self.valueTable[6] = self.valueTable[6] * (1-self["assemblage"..i].attributeValue/10000)
             --print(self.valueTable[6])

          elseif self["assemblage"..i].attributeType ==9 then
             print("暴率暴伤")
            self.valueTable[3] = self.valueTable[3] * (1+self["assemblage"..i].attributeValue/10000)
            self.valueTable[4] = self.valueTable[4] * (1+self["assemblage"..i].attributeValue/10000)
          elseif self["assemblage"..i].attributeType ==10 then
        	 print("攻击破甲")
             self.valueTable[1] = self.valueTable[1] * (1+self["assemblage"..i].attributeValue/10000)
             self.valueTable[5] = self.valueTable[5] * (1+self["assemblage"..i].attributeValue/10000)
          end
        end
   end

    self.atk                  = self.valueTable[1]
    self.normalAtkColdTimeMax = self.valueTable[2]
    self.baoJiRate            = self.valueTable[3]
    self.baoJiAtk             = self.valueTable[4]
    self.poJia                = self.valueTable[5]
    self.skillColdTimeMax     = self.valueTable[6]
    self.skillColdTime	      = self.skillColdTimeMax-120					--self.info.coldTime --技能冷却时间(毫秒)

    self.normalAtkColdTime 		= self.normalAtkColdTimeMax
	self.exSkillPointMax 		= self.spInfo.pointMax 						--奥义技能点最高值（Sp表pointMax）
	self.exSkillPoint			= 0											--奥义技能点
	self.exSkillAutoAddColdTime = 0 										--奥义点自动增加冷却时间值（毫秒）
	self.step      				= math.floor((self.breachInfo.skill1_id%100)/10)		--阶数

	--print(string.format("coldTime:%d,normalAtkColdTimeMax:%d",coldTime,self.normalAtkColdTimeMax))
end


function Soul:updateSelf( dt )

	self.super.updateSelf(self,dt)
	self:checkUpdate(dt)
end

function Soul:setFollowerTarget(target)
	self.followerTarget =  target
end

function Soul:spineCallBack(events)
	-- body
	self.fireOrder = 1
	-- print("....spineCallBack ...00..%d,%d",events.type,events.params)
	if events.type == girl.AnimationNodeEventType.ANIMATION_COMPLETE then

		if self.status == Soul.statusType.STATUS_EX then
			
			printInfo("Soul:spineCallBack")
			--self.isInExSkill = false
			self.status = Soul.statusType.STATUS_WAIT
			-- self:stopAllActions()
			-- self:unRegisterSpineNode(girl.AnimationNodeEventType.ANIMATION_COMPLETE)
			--self:removeFromParent()
			MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.CLOSE_EXSKILL)
		
		end
	end

	
end

function Soul.clone(obj)

	local role = Soul.createWithId(obj.pb.class_id)
	return role
end

function Soul:checkAi()

	if self.followerTarget == nil then
		return
	end
	--dump(self.curTarget)
	if self.curTarget ~= nil then

		if self.isInAtk == true or self.isInSkill == true or self.isInExSkill == true then
			return
		end
		--printInfo("Soul:checkA")
		self:toCheckNextStep()
	end

end



--need add--
function Soul:setSpineEventListener( )

	self:setFrameEventCallFunc({_all = function ( name, params )
		local param = params.stringValue
		--print("+++++soul++++++++++++:"..name.."|"..param) -- name == jump
		if name == "music" then
			if self.skill and self.skill.info.musicId>0 then
				musicManager:play(self.skill.info.musicId)
			end
		elseif name == "fire" then
			--dump(param)
			-- print("+++++++++++++++++++++++fire++++++++++++++")
			if param == "" or param == 0 or param == nil then
				--order 是发射顺序
				--print("+++++++++++++++++++++++000++++++++++++++param:"..param)
				if self.skill ~= nil then
					if self.skill.info.buffId >0 then
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = self,camp = Soul.campType.CAMP_SOUL,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					elseif self.skill.info.bulletId >0 then
						--print("+++++++++++++++++++++++1111++++++++++++++")
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BULLET_ADD,{emanate = self,camp = Soul.campType.CAMP_SOUL,order = self.fireOrder})
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
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = self,buffId = id,camp = Soul.campType.CAMP_SOUL,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					elseif type == 1 then
						MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BULLET_ADD,{emanate = self,bulletId = id,camp = Soul.campType.CAMP_SOUL,order = self.fireOrder})
						self.fireOrder = self.fireOrder + 1
					end
				end
			end
		elseif name == "shake" then
			--printInfo("[Soul] shaking... ")
			MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.SHAKE_ADD)
		elseif name == "showMonster" then  --奥义时怪物出现
			--todo
			printInfo("[Soul] showMonster... ")
			MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.SHOW_MONSTER,{soul = self})
		elseif name == "hitDmg" then       --奥义时怪受伤
			local param = params.floatValue
			--todo
			if type(param) == "string" then
				printInfo("[Soul] hitDmg... param err:[string type]"..param .."soulId:"..self.info.class_id)
			end
			-- dump(param)

			MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.DMG_MONSTER,{dmgValue = (self.exSkillInfo.atkRate/10000.0) * self.atk * param,emanate = self})

		elseif name == "scale" then
			printInfo("[Soul] scale... ")
		elseif name == "eff_b" then
			--printInfo("[Soul] eff_b...")
			MessageManager.sendMessage(girl.MessageLayer.EXSKILL, girl.BattleMessage.ADD_BG_EFF)
		elseif name == "eff_f" then
			--printInfo("[Soul] eff_f...")
			MessageManager.sendMessage(girl.MessageLayer.EXSKILL, girl.BattleMessage.ADD_FRONT_EFF)
		elseif name == "setLayer_b" then
			--printInfo("[Soul] setLayer_b")
			MessageManager.sendMessage(girl.MessageLayer.EXSKILL, girl.BattleMessage.SET_LAYER_FOR_MONSTER,{type = "SET_LAYER_B"})
		elseif name == "setLayer_f" then
			--printInfo("[Soul] setLayer_f")
			MessageManager.sendMessage(girl.MessageLayer.EXSKILL, girl.BattleMessage.SET_LAYER_FOR_MONSTER,{type = "SET_LAYER_F"})
		end

	end})
end



function Soul:toNormalAtk()

	if self.isInAtk or self.isInSkill or self.isInExSkill or self.normalAtkColdTime < self.normalAtkColdTimeMax then
		return
	end
	self.normalAtkColdTime = 0
	self:stopAllActions()
	self.isInAtk = true
	self.isInSkill = false
	self:setDir(Soul.dirType.DIR_RIGHT)
	--self:changeStatus(Soul.statusType.STATUS_ATTACK,1)
	self.status = Soul.statusType.STATUS_ATTACK
	self.skill  = Skill.create({class_id = self.breachInfo.skill0_id})
	-- 0、主角普通攻击
	-- 1、近战攻击（元神需要移动到主角前方）
	-- 2、直线射击
	-- 3、抛物线射击(deprected)
	-- 4、抛物线随机散布(deprected)
	-- 5、BUFF
	--检测技能类型
	--musicId
	local type = self.skill.info.type
	if type == 1 then

			local function completeCallFun(events)

					local function  completeCallFun2(events)
						local moveto = cc.CallFunc:create(handler(self,self.normalAtkStartCb))
						self:runAction(cc.Sequence:create(moveto,cc.DelayTime:create(0.3),cc.CallFunc:create(function()
							local loopTimes = 0
							local function completeCallFun(events)
								loopTimes = loopTimes + 1
								-- print("+++++++++++++++近战++++++++++++++ loopTimes:"..loopTimes)
								if loopTimes >= self.skill.info.atkTimes  then
									loopTimes=0
									-- self:stopAllActions()
									self:runAnimation(string.format("ATK%d",9+10),true)
									local moveback = cc.MoveTo:create(0.3,cc.p(self:getDefaultPosition()))
										local action5  = cc.CallFunc:create(function()
											self:stopAllActions()
											self:setDir(Soul.dirType.DIR_RIGHT)
											self:changeStatus(Soul.statusType.STATUS_MOVE, 1)
											self.isInAtk = false
										end)
									self:runAction(cc.Sequence:create(moveback,action5,nil))
								end
							end
							self:runAnimation(string.format("ATK%d",2+10),true,{ onComplete = completeCallFun})
						end),nil))

					end
					self:runAnimation(string.format("ATK%d",8+10),false,{onComplete = completeCallFun2})
			end
			self:runAnimation(string.format("ATK%d",1+10),false,{onComplete = completeCallFun})

	else
		local function completeCallFun(events)
			if self.skill.info.atkTimes > 0 then
				local loopTimes = 0
				self:runAnimation(string.format("ATK%d",2+10),true,{onComplete = function()
					
					loopTimes = loopTimes + 1
					-- print("+++++++++++++++++++++++++++++ loopTimes:"..loopTimes.. "  应该攻击次数："..self.skill.info.atkTimes)
					if loopTimes >= self.skill.info.atkTimes then
						self:setDir(Soul.dirType.DIR_RIGHT)
						self:changeStatus(Soul.statusType.STATUS_MOVE, 1)
						self.isInAtk = false
					end
				end})
			else
				-- self:stopAllActions()
				self:setDir(Soul.dirType.DIR_RIGHT)
				self:changeStatus(Soul.statusType.STATUS_MOVE, 1)
				self.isInAtk = false
			end
		end
		self:runAnimation(string.format("ATK%d",1+10),false,{onComplete = completeCallFun})
	end
end

function Soul:toSkill()

	if self.isInSkill or self.skillColdTime < self.skillColdTimeMax then --
		return
	end
	self.skillColdTime = 0
	self:stopAllActions()
	self.isInSkill = true
	self.isInAtk   = false
	self.fireOrder = 1
	self:setDir(Soul.dirType.DIR_RIGHT)
	--self:changeStatus(Soul.statusType.STATUS_SKL,1)
	self.status = Soul.statusType.STATUS_SKL
	self.skill  = Skill.create({class_id = self.breachInfo.skill1_id})

	self.skillCodeTimeMax = self.skill.info.coldTime
	--printInfo("[Soul] toSkill....1111")
	MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.SCALE_CAMERA)
	if self.skill.info.music_id > 0 then
	 	musicManager:play(self.skill.info.music_id)
	end
	--dump(skill.info)
	-- 0、主角普通攻击
	-- 1、近战攻击（元神需要移动到主角前方）
	-- 2、直线射击
	-- 3、抛物线射击
	-- 4、抛物线随机散布
	-- 5、BUFF
	local type = self.skill.info.type
	if type == 1 then

		local function completeCallFun(events)
			local action2 = cc.CallFunc:create(function()
				--print("action2")
				self:runAnimation(string.format("SKL%d",8+self.step*10),true)
			end)
			local moveto = cc.CallFunc:create(handler(self, self.normalAtkStartCb))
			self:runAction(cc.Sequence:create(action2,moveto,cc.DelayTime:create(0.3),cc.CallFunc:create(function()
				local loopTimes = 0
				local function completeCallFun2(events)
					loopTimes = loopTimes + 1
					--print("+++++++++++++++近战++++++++++++++ loopTimes:"..loopTimes.."atkTimes:"..self.skill.info.atkTimes)
					if loopTimes >= self.skill.info.atkTimes  then
						-- self:stopAllActions()
						self:runAnimation(string.format("SKL%d",9+self.step*10),true)
						local moveback = cc.MoveTo:create(0.3,cc.p(self:getDefaultPosition()))
						local action5  = cc.CallFunc:create(function()
							--print("+++++++++++++++++++++++++++++++++++++++++++dada")
							-- self:stopAllActions()
							self:setDir(Soul.dirType.DIR_RIGHT)
							self:changeStatus(Soul.statusType.STATUS_MOVE, 1)
							self.isInSkill = false
						end)
						self:runAction(cc.Sequence:create(moveback,action5,nil))
					end
				end
				self:runAnimation(string.format("SKL%d",2+self.step*10),true,{ onComplete = completeCallFun2})
			end),nil))
		end
		self:runAnimation(string.format("SKL%d",1+self.step*10),false,{ onComplete = completeCallFun})

	else
		local function completeCallFun(events)
			if self.skill.info.atkTimes > 0 then
				local loopTimes = 0
				self:runAnimation(string.format("SKL%d",2+self.step*10),true,{onComplete = function()
					--print("++++++++++++++++远战+++++++++++++ loopTimes:"..loopTimes)
					loopTimes = loopTimes + 1
					if loopTimes >= self.skill.info.atkTimes then
						-- self:stopAllActions()
						self:setDir(Soul.dirType.DIR_RIGHT)
						self:changeStatus(Soul.statusType.STATUS_MOVE, 1)
						self.isInSkill = false
					end
				end})
			else
				-- self:stopAllActions()
				self:setDir(Soul.dirType.DIR_RIGHT)
				self:changeStatus(Soul.statusType.STATUS_MOVE, 1)
				self.isInSkill = false
			end
		end
		self:runAnimation(string.format("SKL%d",1+self.step*10),false,{onComplete = completeCallFun})
	end

end

function Soul:normalAtkStartCb()

	if self.curTarget == nil or false == self.curTarget:checkInScreen() then

		local moveback = cc.MoveTo:create(0.3,cc.p(self.followerTarget:getPositionX()+256,BaseRole.HERO_POSITION.y))
	 	self:runAction(moveback)
	 	return
	end
	--self.skill.info.shotWidth = 180
 	local moveback = cc.MoveTo:create(0.3,cc.p(self.curTarget:getPositionX() - 128,self.curTarget:getPositionY()))
 	self:runAction(moveback)

end

function Soul:normalAtkBackCb()

	local moveback = cc.MoveTo:create(0.3, self:getDefaultPosition())
	self:runAction(moveback)

end

function Soul:getDefaultPosition()

    if(self.followerTarget==nil) then
        return cc.p(0,0)
    end
    local v2 = cc.p(self.followerTarget:getPosition())
    if (self.posId == 1) then
    	return cc.p(v2.x-76,BaseRole.HERO_POSITION.y+52)
    elseif (self.posId == 2) then
    	return cc.p(v2.x-126,BaseRole.HERO_POSITION.y-52)
    elseif (self.posId == 3) then
    	return cc.p(v2.x-220,BaseRole.HERO_POSITION.y)
    end
end



function Soul:toCheckNextStep()

	if  (self.info.atk_check_dis == 0 and self.followerTarget.status == Soul.statusType.STATUS_ATTACK)
		or (self:getPositionX() + self.info.atk_check_dis >= self.curTarget:getPositionX() - self.curTarget.info.rect_x and 
			self:getPositionX() <  self.curTarget:getPositionX())  then

		self:toNormalAtk()

	else
		self:changeStatus(Soul.statusType.STATUS_MOVE,1)
	end

end

function Soul:getRect()

	local size = self:getCascadeBoundingBox()
	local rt = cc.rect(self:getPositionX()-size.width*0.5,
				self:getPositionY(),
				size.width,
				size.height)
	return rt
end

function Soul:checkUpdate(dt)

	if(self:getPositionX() < self:getDefaultPosition().x) then
		self:setPosition(self:getDefaultPosition())
	end
	self:codeTimeUpdate(dt)
	if self.isInAtk or self.isInSkill or self.isInExSkill  then
		return
	end
	self:setLocalZOrder(display.height-self:getPositionY())

	if self.followerTarget then
		if self.curTarget == nil then

			if self.followerTarget.isInAction == false then
				self:changeStatus(self.followerTarget.status,1)
			end
		else

			if self.followerTarget.status == Soul.statusType.STATUS_MOVE or
				self.followerTarget.status == Soul.statusType.STATUS_JUMP or
				self.followerTarget.status == Soul.statusType.STATUS_SKITE or
				self.followerTarget.status == Soul.statusType.STATUS_FAST or
				self.followerTarget.status == Soul.statusType.STATUS_DMG then
					self:changeStatus(Soul.statusType.STATUS_MOVE,1)
			end
		end
	end
end

--技能/奥义冷却
function Soul:codeTimeUpdate(dt)

	--if false == self.isInSkill then
		self.skillColdTime = self.skillColdTime + dt*1000
		if self.skillColdTime >= self.skillColdTimeMax then
			self.skillColdTime = self.skillColdTimeMax
		end
	--end
	--if false == self.isInAtk then
		self.normalAtkColdTime = self.normalAtkColdTime + dt*1000
		if self.normalAtkColdTime >= self.normalAtkColdTimeMax then
			self.normalAtkColdTime = self.normalAtkColdTimeMax
		end
	--end
	if false == self.isInExSkill then
		self.exSkillAutoAddColdTime = self.exSkillAutoAddColdTime + dt*1000
		if self.exSkillAutoAddColdTime >= self.spInfo.riseTime then
			self:addExSkillPoint(1)
			self.exSkillAutoAddColdTime = 0
		end	
	end

	--self.atkTimeDt:setString(""..math.floor(self.normalAtkColdTime))
end

--奥义加点处理
function Soul:addExSkillPoint(value)

	self.exSkillPoint = self.exSkillPoint + value
	if self.exSkillPoint >= self.exSkillPointMax then
		self.exSkillPoint = self.exSkillPointMax
	end
	
end

function Soul:howAddExSkillPoint(params)
	--每Ｘ个combo增加一个奥义点
	if params.obj.recComboNum >= self.spInfo.riseNeedComboNum then
		params.obj.recComboNum = 0
		self:addExSkillPoint(1)
	end
end
return Soul

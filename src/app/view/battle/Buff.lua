local CURRENT_MODULE_NAME = ...

local AnimationNode       = import("..controls.CocostudioNode")
local BaseRole = import(".BaseRole",CURRENT_MODULE_NAME)
local Effect   = import("..controls.EffectManager", CURRENT_MODULE_NAME)

--singleton
local resManager 	= import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager",CURRENT_MODULE_NAME):getInstance()
local infoMgr = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()



local Buff 	   = class("Buff",display.newNode)

function Buff.createWithId( id )

	return Buff.new({id = id})

end

function Buff.create(params)
	-- body


end
-- --need add
function Buff:ctor(params)

	self:enableNodeEvents()

	self.id = params.id

	self.pb  =  infoMgr:findInfo("buffs","class_id",params.id)
	--dump(self.pb)
	self.info = self.pb
	-- dump(self.info)
	self.atkTimes = self.info.atk_times
	self.totalValue = 0 	--会记录buff产生的总值
	self.affectParmas = nil
	self.isAddedBuff = false --是buff生成过buff
	--dump(self.info)
	--buff 音效
    if self.info.music_id > 0  then
    	musicManager:play(self.info.music_id)
    end
	-- local info = resManager:findInfo(params.id)
	-- dump(info)
	-- local rt = cc.rect(-self.info.check_dis/2,
 --        -self.info.check_dis/2,
 --        self.info.check_dis,
 --        self.info.check_dis)
 --    girl.createTestRect(rt):addTo(self)

 	-- print("check_dis : "..self.info.check_dis)
 	-- local rt = girl.createTestArc(cc.p(0,0),self.info.check_dis)
  --   rt:addTo(self,2222)

end



--[[-----------------------------------------
buff type:
0、空BUFF
1、将指定范围内的怪物吸到BUFF生成的点上并持续造成伤害
2、近战伤害
3、加血
4、对指定范围内的怪物造成伤害并将总伤害值传给下一个BUFF
5、以上一次BUFF造成的伤害值的一定比例给主角加血
6、击退对象
7、自爆：fire帧之后自身失去被攻击判定和碰撞判定，Spine播放完后销毁
8、增加攻击速度（【伤害频率】控制效果时间）
9、改属性
10、眩晕
11、生成能够抵挡敌方bullet的护盾
12、按照目标的最大血量百分比扣血
----------------------------------------------
target type:
1、怪物
2、场景，只伤害怪物
3、自身
4、主角
5、本队
6、场景，只伤害主角
---------------------------------------------]]
-- Buff 对作用目标产生的效果
--[[ params:{ emanate , target,affectValue(此值可以代表任何意义(加血、)),}]]
function Buff:affectToTarget(params)
	self.affectParmas = params
	--加特效(对像和场景两种)
	if self.info.target_type == 1  or self.info.target_type == 3
		or self.info.target_type == 4 or self.info.target_type == 5 then --1、怪物 3、自身 4、主角  5、本队
		if self.info.eff_id > 0 then
			local targets = {}
			if "table" ~=  type(params.target) then	
				table.insert(targets,params.target)
			else
				targets = params.target
			end
			for _,v in ipairs(targets) do
				local target = v
				--dump(self.info)
				local rt = target:getRect()
				--printInfo("[Hero] buff.check_dis :"..self.info.check_dis.."  buffX:"..self:getPositionX() .."  buffY:"..self:getPositionY())
				if (self.info.check_dis > 0 and target:isArcRectCollides(cc.p(self:getPositionX(),self:getPositionY()),self.info.check_dis,rt))
					or self.info.check_dis == 0 then

						if (target.type == BaseRole.roleType.ROLE_TYPE_MONSTER or target.type == BaseRole.roleType.ROLE_TYPE_BOSS) and self.info.effect_pos > 0 then
							local eff = Effect.createWithId(self.info.eff_id):addTo(target.effRoot["eff"..self.info.effect_pos])
						 	eff:setPosition(0,0)
						 	eff:runAnimation(eff.DefaultAnimation,false, function()
						 	eff:destroy()
						 	end)
						else
							local eff = Effect.createWithId(self.info.eff_id):addTo(target)
						 	eff:setPosition(0,0)
						 	eff:runAnimation(eff.DefaultAnimation,false, function()
						 	eff:destroy()
						 	end)
						end	
				end
			end
		end
	elseif self.info.target_type == 2 or self.info.target_type == 6 then --2、场景，只伤害怪物 6、场景，只伤害主角
		if self.info.eff_id > 0 then
		 	local eff = Effect.createWithId(self.info.eff_id):addTo(self:getParent(),2048)
		 	eff:setPosition(self:getPosition())
		 	eff:runAnimation(eff.DefaultAnimation,false, function()
		 	eff:destroy()
		 	end)
		 	--print(">>>>>>>>>>>>>>>>>>>>>>elf.info.target_type:"..self.info.target_type)
		end
	end
end
function Buff:affectToTargetUpdate(dt)
	--printInfo("[Buff] fun: type="..self.info.type)
	local params = self.affectParmas
	if not params or self.atkTimes <= 0 then
		return
	end
	--printInfo("Buff:affectToTarget ")
	local targets = {}
	if "table" ~=  type(params.target) then	
		table.insert(targets,params.target)
	else
		targets = params.target
	end
	for _,v in ipairs(targets) do
		local target = v
		if target then
			local rt = target:getRect()
			-- printInfo("buff.check_dis :"..self.info.check_dis.."  buffX:"..self:getPositionX() .."  buffY:"..self:getPositionY() )
			if (self.info.check_dis > 0 and true == target:isArcRectCollides(cc.p(self:getPositionX(),self:getPositionY()),self.info.check_dis,rt))
				or self.info.check_dis == 0 then

					if self.info.type == 0 then --空BUFF

					elseif self.info.type == 1 then --将指定范围内的怪物吸到BUFF生成的点上并持续造成伤害
						if target.objType == BaseRole.OBJ_TYPE.MONSTER or target.objType == BaseRole.OBJ_TYPE.BOSS  then
							target:setPosition(cc.p(self:getPosition()))
						end
					elseif self.info.type == 2 then --近战伤害
						if(target~= nil) then
							-- printInfo("self.info.type = 2   check_dis :"..self.info.check_dis)
							target:damageWithBuff({buff = self,emanate = params.emanate})
						end
					elseif self.info.type == 3 then --addHp
						if(target~= nil) then
							local addValue = params.emanate.atk * (self.info.once_atk_rate/10000.0) + self.info.once_atk
							target:addHp(addValue)
							self:setPosition(cc.p(target:getPosition()))
						end
					elseif self.info.type == 4 then --对指定范围内的怪物造成伤害并将总伤害值传给下一个BUFF
						if(target ~= nil) then
							local dmgValue = target:damageWithBuff({buff = self,emanate = params.emanate})
							self.totalValue = self.totalValue + dmgValue
						end
					elseif self.info.type == 5 then --以上一次BUFF造成的伤害值的一定比例给主角加血
						--printInfo("self.info.type = 5   ".."   once_atk_rate="..self.info.once_atk_rate)
						if(target~= nil) then
							target:addHp(params.affectValue * self.info.once_atk_rate/10000.0 + self.info.once_atk)
						end
					elseif self.info.type == 6 then --击退对象
						--printInfo("[Buff] fun:affectToTarget type = 6")
						if(target~= nil) then
							target:hitBack(target.info.hit_back_dis)
						end
					elseif self.info.type == 7 then --自爆
						target:damageWithBuff({buff = self,emanate = params.emanate})
					elseif self.info.type == 8 then --增加攻击速度
					elseif self.info.type == 9 then --改属性
					elseif self.info.type == 10 then --眩晕
					elseif self.info.type == 11 then --生成能够抵挡敌方bullet的护盾
					elseif self.info.type == 12 then --按目标最大血量值％扣血
						target:damageWithBuff({buff = self,emanate = params.emanate})
					end
					--击中音效
					if self.info.effect_music>0 then
						musicManager:play(self.info.effect_music)
					end
			end
		end
	end
	-- Buff 产生buff
	--产生的总值传递给下一个buff
    if self.info.buff_id>0 and self.isAddedBuff== false then
    	self.isAddedBuff = true
    	-- print("产生了新 的buff ")
    	-- dump(self:getPosition())
        MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = params.emanate,target = target,buffId = self.info.buff_id,order = 1,pos = cc.p(self:getPosition()),addValue = self.totalValue})
    end
	self:destroy()
end

function Buff:destroy()

	self.atkTimes = self.atkTimes -1
	if self.atkTimes<=0 then
		self.atkTimes = 0
		self:stopAllActions()
		self:removeFromParent()
		--printInfo("[Buff] fun: destroy")
	end

end

function Buff:onEnter()
	-- body
	--printInfo("[Buff] self.info.atk_rate:"..self.info.atk_rate)
	self:schedule(self,handler(self, self.affectToTargetUpdate),self.info.atk_rate/1000.0)
end

return Buff

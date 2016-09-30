local CURRENT_MODULE_NAME = ...

local manager_= nil
local BattleManager = class("BattleManager")

function BattleManager:getInstance()

	if nil == manager_ then
		manager_ = BattleManager.new()
	end
	return manager_
end

function BattleManager:ctor()
	
	--print("BattleManager:ator")
	self:resetBattleManager()
end

function BattleManager:resetBattleManager()
	
	self.mapW= 0
	self.mapH= 0
	self.monsterPool= {}
	self.trapPool = {}
	self.bulletPool= {}
  	self.eventPool = {}
  	self.recMonster = {}
  	self.hero = nil
  	self.cameraTarget = nil
	self.cameraPos=cc.p(0,0)
	self.recTouchPos=cc.p(0,0)
	self.battleResultCode = -1  --战斗结果：－1:未结束 0:失败 1:胜利
	self.isPushMonster = false
	self.boxNum = 0
	self.battleUi=nil
	self.killNum = 0 			--记录杀怪数量
	self.isKilledTarget = false
	self.target = nil 			--目标boss
	self.scriptMonsterPool = {}
	self.isAoyiAction = false

end

function BattleManager:setCameraTarget(target)

	if  self.cameraTarget == target then
		return
	end
    self.cameraTarget = target 

end

function BattleManager:addKillNum(num)
	self.killNum = self.killNum + num
	--print(">>>>>>>>>>>>>>>>>>>>>>>>>>killNum:"..self.killNum)
end

function BattleManager:checkTargetDead(target)
	if self.target == nil then
		return false
	end
	print("fun: checkTargetDead    id:"..self.target.pb.id .."  hp:"..self.target.curHp)
	if self.target == target then
		if target.curHp <= 0 then
			return true
		end
	end
	return false
end

return BattleManager

local CURRENT_MODULE_NAME = ...

local LiveNode              = import("..controls.LiveNode", CURRENT_MODULE_NAME)
local ImageLabel            = import("..fragment.ImageLabel", CURRENT_MODULE_NAME)
local AnimationNode         = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local TotalImageLabel       = import("..fragment.EduFragment.TotalImageLabel", CURRENT_MODULE_NAME)

---single
local resMgr 				= import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()

local BattleScript 			= class("BattleScript",import(".ScriptMachine", CURRENT_MODULE_NAME))

local s_inst        = nil

function BattleScript:getInstance()
	if nil == s_inst then
		s_inst = BattleScript.new()
	end
	return s_inst
end

BattleScript.Z_GILR = 2000
BattleScript.Z_TALK = 3000

---妹子包含（npc,me）
function BattleScript:initGirls(data)
	print("fun: BattleScript:initGirls(data) ")
	dump(data)
	for k,v in pairs(data) do
		if self.girls[k] == nil then
			self.girls[k] = {}
			self.girls[k].id = v
		end
	end
	self.girls["ME"] = {}
	self.girls["NPC"] = {}

	dump(self.girls)
end

function BattleScript:initMonsters(data)
	print("fun: BattleScript:initMonsters(data) ")
	dump(data)
	for k,v in pairs(data) do
		if self.monsters[k] == nil then
			self.monsters[k] = {}
			self.monsters[k].id = v
		end
	end
	dump(self.monsters)
end

function BattleScript:runScriptEnter(data)
	dump(data)
	dump(self.girls)
	dump(self.monsters)
	for _,v in ipairs(data) do
		local gl = self.girls[v.id] or self.monsters[v.id]
		
		gl.pos = v.pos

		gl.node = self.root:seek("girlNode_"..v.pos)
		gl.node.headLive05_1_1 = AnimationNode.seek(gl.node,"headLive05_1_1")
		gl.node.bossHead = AnimationNode.seek(gl.node,"bossHead")
		gl.talkNode = AnimationNode.seek(self.root, "girlTalkNode_"..v.pos)
		gl.talkNode:hide()
		dump(gl)
		if v.pos == 1 then
			gl.talkNode:seek("talk_0"):hide()
			gl.talk = ImageLabel.seek(gl.talkNode, "talk"):show()
		else
			gl.talkNode:seek("talk"):hide()
			gl.talk = ImageLabel.seek(gl.talkNode, "talk_0"):show()
		end
		
		gl.starNode = AnimationNode.seek(gl.talk, "starNode")

		gl.node:runAnimation("in", false, function()
			self:next()
		end)

		gl.state = "init"
	end

end

function BattleScript:runScriptExit(data)
	for _,v in ipairs(data) do

		local obj = self.girls[v.id] or self.monsters[v.id]
		obj.node:runAnimation("out", false, function()
			self:next()
		end)
	end
end

function BattleScript:runScriptTalk(data)
	dump(data)
	dump(self.girls)
	self:reset()

	local function _getExpressIdx()
		local expression = data.expression
		for i=1,10 do
			if expression == string.format("f%02d.exp",i) then
				if i%2 ~= 0 then
					expression = string.format("f%02d.exp",i+1)
					return i+1
				else
					return i
				end
			end
		end
	end

	local function _setNodeTexture(data,id,node)
		if data.expression then
			local soulId = math.floor((id/100)%100)
			printInfo("妹子表情: %s  ---soulId: %d",data.expression,soulId)
			node:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_FACE,soulId,string.format("%02d",_getExpressIdx())))
		else
			local type = {ME = "me",NPC = "npc",M1 = "M1",M2 = "M2"}
			dump(data.id[1])
			if data.id[1] ~= "ME" and data.id[1] ~= "NPC" then
				local monsterId = math.floor(id/100)
				node:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.BOSS_HEAD,monsterId))
			else
				node:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.ME_NPC_FACE,type[data.id[1]]))
			end
		end
	end

	local gl = self.girls[data.id[1]] or self.monsters[data.id[1]]
	-- dump(gl)
	if gl.pos == 1 then
		gl.talk:runAnimation("girlTalk")
		_setNodeTexture(data,gl.id,gl.node.headLive05_1_1)
	else

		gl.talk:runAnimation("bossTalk")
		_setNodeTexture(data,gl.id,gl.node.headLive05_1_1)
		-- print("---bossTalk ------------")
	end
	gl.talkNode:show()
	gl.talkNode:runAnimation("in")
	gl.state = "talk"
	gl.talk:setString(data.talk)
	gl.starNode:runAnimation("loop", true)
	self:next()
end

function BattleScript:runScriptThink(data)
	self:reset()

	local gl = self.girls[data.id[1]] or self.monsters[data.id[1]]
	if gl.pos == 1 then
		gl.talk:runAnimation("girlThink")
	else
		gl.talk:runAnimation("bossThink")
	end

	gl.talkNode:show()
	gl.talkNode:runAnimation("in")
	gl.state = "think"
	gl.talk:setString(data.talk)
	gl.starNode:runAnimation("loop", true)
	self:next()
end



function BattleScript:reset()
	for _,v in pairs(self.girls) do
		if v.state ~= "pass" and v.talk ~= nil then
			v.talkNode:runAnimation("pass")
			v.starNode:pause()
			v.state = "pass"
		elseif v.state == "pass" then
			v.talkNode:runAnimation("out")
			v.starNode:pause()
			v.state = "pass"
			v.talkNode:hide()
		end
	end
end

--增加怪物
function BattleScript:runScriptAddMonster(data)
	local monster = self.monsters[data.id]
	dump(monster)
	monster.pos= cc.p(data.pos)
	MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_MONSTER,{id = tonumber(monster.id) ,pos = cc.p(monster.pos)})
	self:next()
end

--移除怪物
function BattleScript:runScriptRemoveMonster(data)

	for _,v in pairs(self.monsters) do
		local monster = self.monsters[data.id]
		monster.id = tonumber(v.id)
		MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.REMOVE_MONSTER,{id = monster.id})
	end
	self:next()

end

return BattleScript

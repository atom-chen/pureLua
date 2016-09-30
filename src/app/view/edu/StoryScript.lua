local CURRENT_MODULE_NAME = ...

-- classes
local LiveNode        = import("..controls.LiveNode", CURRENT_MODULE_NAME)
local ImageLabel      = import("..fragment.ImageLabel", CURRENT_MODULE_NAME)
local TotalImageLabel = import("..fragment.EduFragment.TotalImageLabel", CURRENT_MODULE_NAME)
local AnimationNode   = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local GridView        = import("..controls.GridView", CURRENT_MODULE_NAME)

-- singleton
local resMgr          = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local musicMgr        = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws              = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder       = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()

local SelectBannerNode = class("SelectBannerNode",AnimationNode)

function SelectBannerNode.create(params)
	local param = {}
	param.pb = params
	param.csbName = "nodes/talk/bt_choice.csb"
	return SelectBannerNode.new(param)
end

function SelectBannerNode:ctor(params)
	SelectBannerNode.super.ctor(self,params)
    self:enableNodeEvents()
	-- Helpers:dumpNode(self)
	self:mapUiElements({"contentText"})
end

function SelectBannerNode:onEnter()
	SelectBannerNode.super.onEnter(self)
	self:runAnimation("in")
end

function SelectBannerNode:setString(str)
	self.contentText:setString(str)
end

function SelectBannerNode:onClicked(func)
	self:onButtonClicked("imageButton", func)
end


local StoryScript = class("StoryScript",import(".ScriptMachine", CURRENT_MODULE_NAME))

local s_inst        = nil

function StoryScript:getInstance()
	if nil == s_inst then
		s_inst = StoryScript.new()
	end
	return s_inst
end

StoryScript.Z_GILR     = 2000
StoryScript.Z_TALK     = 3000
StoryScript.Z_SELECT   = 4000
StoryScript.Z_START    = 5000

StoryScript.SelectItem = {{3},{2,4},{1,3,5}}

function StoryScript:initGirls(data)
	for k,v in pairs(data) do
		if self.girls[k] == nil then
			self.girls[k] = {}
			self.girls[k].node = LiveNode.load(resMgr:getResPath(v))
			self.girls[k].node:addTo(self.root, self.Z_GILR)
			self.girls[k].node:hide()
		end
	end
	self.talksNode = AnimationNode.seek(self.root, "girlsTalkNode")
	self.talksNode:setLocalZOrder(self.Z_TALK)
	self.talks = TotalImageLabel.seek(self.talksNode, "totaTalkNode")
	self.talksStar = AnimationNode.seek(self.talks, "starNode")
	self.talksStar:runAnimation("loop", true)

	self.thinksNode = AnimationNode.seek(self.root, "girlsThinkNode")
	self.thinksNode:setLocalZOrder(self.Z_TALK)
	self.thinks = TotalImageLabel.seek(self.thinksNode, "totaThinkNode")
	self.thinksStar = AnimationNode.seek(self.thinks, "starNode")
	self.thinksStar:runAnimation("loop", true)

	self.girls["ME"] = {}
	self.girls["ME"].talkNode = AnimationNode.seek(self.root, "heroTalkNode")
	self.girls["ME"].talkNode:hide()
	self.girls["ME"].talkNode:setLocalZOrder(self.Z_TALK)
	self.girls["ME"].talk = ImageLabel.seek(self.girls["ME"].talkNode, "talkNode")
	self.girls["ME"].talkStar = AnimationNode.seek(self.girls["ME"].talk, "starNode")
	self.girls["ME"].talkStar:runAnimation("loop", true)

	self.girls["ME"].thinkNode = AnimationNode.seek(self.root, "heroThinkNode")
	self.girls["ME"].thinkNode:hide()
	self.girls["ME"].thinkNode:setLocalZOrder(self.Z_TALK)
	self.girls["ME"].think = ImageLabel.seek(self.girls["ME"].thinkNode, "thinkNode")
	self.girls["ME"].thinkStar = AnimationNode.seek(self.girls["ME"].think, "starNode")
	self.girls["ME"].thinkStar:runAnimation("loop", true)

	self.girls["PB"] = {}
	self.girls["PB"].talkNode = AnimationNode.seek(self.root, "paibaiTalkNode")
	self.girls["PB"].talkNode:hide()
	self.girls["PB"].talkNode:setLocalZOrder(self.Z_TALK)
	self.girls["PB"].talk = ImageLabel.seek(self.girls["PB"].talkNode, "pangbaiNode")
	self.girls["PB"].talkStar = AnimationNode.seek(self.girls["PB"].talk, "starNode")
	self.girls["PB"].talkStar:runAnimation("loop", true)

	local view = AnimationNode.seek(self.root, "selectPanel")
	local viewRect = view:getBoundingBox()
	viewRect.height = viewRect.height * 1.2
	self.selectItems = {}
	for i,v in ipairs(self.SelectItem[3]) do
		local selectItem = SelectBannerNode.create():addTo(self.root,self.Z_SELECT)
		selectItem:setPosition(viewRect.x + viewRect.width / 2,viewRect.y + viewRect.height / 4 * i)
		self.selectItems[self.SelectItem[3][table.nums(self.SelectItem[3]) - i + 1]] = selectItem
	end

	for i,v in ipairs(self.SelectItem[2]) do
		local selectItem = SelectBannerNode.create():addTo(self.root,self.Z_SELECT)
		selectItem:setPosition(viewRect.x + viewRect.width / 2,viewRect.y + viewRect.height / 3 * i)
		self.selectItems[self.SelectItem[2][table.nums(self.SelectItem[2]) - i + 1]] = selectItem
	end
	self:reset()
end

function StoryScript:runScriptEnter(data, next)
	local next = next or true
	for _,v in ipairs(data) do
		local gl = self.girls[v.id]

		gl.image = self.root:seek("girlNode_"..v.pos)
		-- temp top fix
		local imagePos = girl.fixNodePosition(gl.image:getPositionX(),gl.image:getPositionY())
		gl.node:show()
		gl.node:setPosition(imagePos.x,imagePos.y)
		gl.pos = v.pos

		gl.talkNode = AnimationNode.seek(self.root, "girlTalkNode_"..v.pos)
		gl.talkNode:hide()
		gl.talkNode:setLocalZOrder(self.Z_TALK)
		gl.talk = ImageLabel.seek(gl.talkNode, "talkNode")
		gl.talk:runAnimation(v.pos)
		gl.talkStar = AnimationNode.seek(gl.talk, "starNode")
		gl.talkStar:runAnimation("loop", true)

		gl.thinkNode = AnimationNode.seek(self.root, "girlThinkNode_"..v.pos)
		gl.thinkNode:hide()
		gl.thinkNode:setLocalZOrder(self.Z_TALK)
		gl.think = ImageLabel.seek(gl.thinkNode, "thinkNode")
		gl.think:runAnimation(v.pos)
		gl.thinkStar = AnimationNode.seek(gl.think, "starNode")
		gl.thinkStar:runAnimation("loop", true)

	end
	if next then
		self:next()
	end
end

function StoryScript:runScriptExit(data, next)
	local next = next or true
	for _,v in ipairs(data) do
		self.girls[v.id].node:hide()
	end
	if next then
		self:next()
	end
end

function StoryScript:runActions(data)
	for _,v in ipairs(data.id) do
		-- print(">>>>:",v,"|action:",data.action,"|expression:",data.expression)
		if data.action then
			self.girls[v].node:runRandomMotion(data.action, 3)
		end
		if data.expression then
			self.girls[v].node:runExpression(data.expression)
		end
	end
end

function StoryScript:runScriptTalk(data)
	self:reset()

	if #data.id > 1 then
		self.talksNode:show()
		local ids = {}
		for _,v in ipairs(data.id) do
			table.insert(ids, self.girls[v].pos)
		end
		self.talks:setString(ids, data.talk)
		self.talksNode:runAnimation("in", false, function()
			self:next()
		end)
	else
		self.girls[data.id[1]].talkNode:show()
		self.girls[data.id[1]].talk:setString(data.talk)
		self.girls[data.id[1]].talkNode:runAnimation("in", false , function()
			self:next()
		end)
	end

	self:runActions(data)

end

function StoryScript:runScriptThink(data)
	self:reset()

	if #data.id > 1 then
		self.thinksNode:show()
		local ids = {}
		for _,v in ipairs(data.id) do
			table.insert(ids, self.girls[v].pos)
		end
		self.thinks:setString(ids, data.talk)
		self.thinksNode:runAnimation("in", false, function()
			self:next()
		end)
	else
		self.girls[data.id[1]].thinkNode:show()
		self.girls[data.id[1]].think:setString(data.talk)
		self.girls[data.id[1]].thinkNode:runAnimation("in", false , function()
			self:next()
		end)
	end

	self:runActions(data)

end

function StoryScript:runScriptPlayBgm(data)
	musicMgr:play(data)
	self:next()
end

function StoryScript:runScriptPlaySound(data)
	musicMgr:play(data)
	self:next()
end

function StoryScript:runScriptChangeBg(data)
	print("fun:StoryScript:runScriptChangeBg")
	self.root.bgImage:refresh(data)
	self:next()
end

function StoryScript:runScriptChangePos(data)
	self:runScriptExit(data, false)
	self:runScriptEnter(data, false)
	self:next()
end

function StoryScript:runScriptSelect(data)
	self:reset()
	self:enableTouch(false)
	for i,v in ipairs(data) do
		self.selectItems[self.SelectItem[#data][i]]:show()
		self.selectItems[self.SelectItem[#data][i]]:setString(v.choice)
		self.selectItems[self.SelectItem[#data][i]]:onClicked(function()
			self:enableTouch(true)
			self:setIndex(v.go)
			self:next()
		end)
	end
end

function StoryScript:runScriptDo(data)
	-- dump(data)
	local pb    = pbBuilder:build({
		  proto = "data/pb/interface/projectSelect.pb",
		  desc  = "interface.projectSelect.Request",
		  input ={ soul_id = data.girlId, select_id = data.doId } })

	ws:send( "PROJECT_SELECT", pb, function(resultCode, des, data)
		if resultCode == 0 then
			-- 选择选项
			self:next()
		end
	end)
end

function StoryScript:reset()
	for _,v in pairs(self.girls) do
		if v.talkNode then
			v.talkNode:hide()
		end
		if v.thinkNode then
			v.thinkNode:hide()
		end
	end
	self.talksNode:hide()
	self.thinksNode:hide()

	for _,v in pairs(self.selectItems) do
		v:hide()
	end
end

return StoryScript

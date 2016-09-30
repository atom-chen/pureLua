local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")


--
local infoMgr 	= import("....data.information.InfoManager"):getInstance()
local resMgr 	= import("....data.information.ResManager"):getInstance()

local StoryBannerNode = class("StoryBannerNode",AnimationNode)


function StoryBannerNode.create(params)
	local param = {}
	param.pb = params
	param.csbName = "nodes/edu/storyBanner.csb"
	return StoryBannerNode.new(param)
end

function StoryBannerNode:ctor(params)
	-- dump(params)
	StoryBannerNode.super.ctor(self,params)
    self:enableNodeEvents()

    self:mapUiElements({"bgSprite", "titleText","contentText","newNode","itemNode","itemSprite","itemCountText"})

	self.pb = params.pb
	self.pb.info  = infoMgr:findInfo("projects","class_id",self.pb.class_id)
	dump(self.pb)
    self:refresh(self.pb)
end

function StoryBannerNode:onEnter()
    StoryBannerNode.super.onEnter(self)
end

function StoryBannerNode:onExit()
    StoryBannerNode.super.onExit(self)
end

function StoryBannerNode:refresh(pb)

	local function _writeState(state)
		if state == 2 then
			self:runAnimation("lock")
		else
			self:runAnimation("unlock")
		end
		if state == 3 then
			self.newNode:show()
		else
			self.newNode:hide()
		end
	end

	local function _writeType(type)
		if type == 1 then
			self.bgSprite:hide()
		else
			self.bgSprite:show()
		end
	end

	local function _writeTitle(title)
		self.titleText:setString(title)
	end

	local function _writeContent(content)
		self.contentText:setString(content)
	end

	local function _writeNeedItem(id, count)
		-- self.contentText:setString(content)
		if count > 0 then
			self.itemNode:show()
			self.itemSprite:setTextureByPlist(resMgr:getResPath(id))
			self.itemCountText.setString(count)
		else
			self.itemNode:hide()
		end
	end

	if pb.state then
		_writeState(pb.state)
	end
	if pb.type then
		_writeType(pb.type)
	end
	if pb.info then
		_writeTitle(pb.info.class_id)
		_writeContent(pb.info.name)
		if pb.info.needId > 0  then
			local prop = infoMgr:findInfo("materials","class_id",pb.info.needId)
			_writeNeedItem(prop.resId, pb.info.needCount)
		end
	end

end

return StoryBannerNode

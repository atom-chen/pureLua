local CURRENT_MODULE_NAME = ...
local AnimationNode    = import("...controls.CocostudioNode")
--
local infoMgr 	= import("....data.information.InfoManager"):getInstance()
local resMgr 	= import("....data.information.ResManager"):getInstance()

local GiftNode = class("GiftNode",AnimationNode)


function GiftNode.create()
	local params = {}
	params.csbName = "nodes/edu/gift.csb"
	return GiftNode.new(params)
end

function GiftNode:ctor(params)
	GiftNode.super.ctor(self,params)
    self:enableNodeEvents()

	self:mapUiElements({"itemSprite", "countText" ,"newNode","bd_item_2"})
end

function GiftNode:onEnter()
    GiftNode.super.onEnter(self)
end

function GiftNode:onExit()
    GiftNode.super.onExit(self)
end

function GiftNode:refresh(pb)

	if not pb then
		self:runAnimation("no")
	else
		--add by Jason
		self.pb = pb
		self:runAnimation("have")
		local info = infoMgr:findInfo("devProps", "class_id", pb.class_id)
		local function _writeCount(count)
			if count > 1 then
				self.countText:setString("x"..count)
			else
				self.countText:setString("")
			end
		end
		local function _writeIcon(iconId)
			self.itemSprite:setTexture(resMgr:getResPath(iconId))
		end

		if pb.count then
			_writeCount(pb.count)
		end

		if info then
			_writeIcon(info.resId)
		end
	end
end

function GiftNode:getRect()
	return self.bd_item_2:getCascadeBoundingBox()
end

return GiftNode

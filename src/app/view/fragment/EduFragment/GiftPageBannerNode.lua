local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("...controls.CocostudioNode")
local GiftShopNode  = import(".GiftShopNode", CURRENT_MODULE_NAME)
local BuyGiftNode   = import(".BuyGiftNode", CURRENT_MODULE_NAME)

-- singleton
local infoMgr 	    = import("....data.information.InfoManager"):getInstance()
local resMgr 	    = import("....data.information.ResManager"):getInstance()

local GiftBannerNode = class("GiftBannerNode",AnimationNode)


function GiftBannerNode.create()
	local params = {}
	params.csbName = "nodes/edu/giftShopBanner.csb"
	return GiftBannerNode.new(params)
end

function GiftBannerNode:ctor(params)
	GiftBannerNode.super.ctor(self,params)
    self:enableNodeEvents()

	for i=1,10 do
		self:mapUiElement(i, function()
			return GiftShopNode.seek(self, "itemNode"..i)
		end)
		self[i]:hide()
	end

end

function GiftBannerNode:onEnter()
    GiftBannerNode.super.onEnter(self)

	girl.addTouchEventListener(self,{swallow = false,
	onBegan = function(touch, event)
		local touchPos = touch:getLocation()
		for i=1,10 do
			if self.pb[i] ~= nil and cc.rectContainsPoint(self[i]:getCascadeBoundingBox(), touchPos) then
				self.touchEventIndex = i
			end
		end
		return true
	end,
	onEnded = function(touch, event)
		local touchPos = touch:getLocation()
		for i=1,10 do
			if 	self.pb[i] ~= nil and
			 	cc.rectContainsPoint(self[i]:getCascadeBoundingBox(), touchPos) then
		-- 		dump(self.pb[i])
				if self.touchEventIndex == i then
					BuyGiftNode.create({type = 1, class_id = self.pb[i].class_id}):addTo(self)
				end
			end
		end
	end})
end

function GiftBannerNode:onExit()
    GiftBannerNode.super.onExit(self)
end

function GiftBannerNode:refresh(pb)
	-- dump(pb)
	self.pb = pb
	for i,v in ipairs(pb) do
		self[i]:show()
		self[i]:refresh(v)
	end
end

return GiftBannerNode

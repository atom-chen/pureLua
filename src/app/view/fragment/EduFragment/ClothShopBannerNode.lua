local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("...controls.CocostudioNode")
local ClothNode  	= import(".ClothNode", CURRENT_MODULE_NAME)
local BuyGiftNode   = import(".BuyGiftNode", CURRENT_MODULE_NAME)
-- singleton
local infoMgr 	    = import("....data.information.InfoManager"):getInstance()
local resMgr 	    = import("....data.information.ResManager"):getInstance()

local ClothShopBannerNode = class("ClothShopBannerNode",AnimationNode)


function ClothShopBannerNode.create()
	local params = {}
	params.csbName = "nodes/edu/clothShopBanner.csb"
	return ClothShopBannerNode.new(params)
end

function ClothShopBannerNode:ctor(params)
	ClothShopBannerNode.super.ctor(self,params)
    self:enableNodeEvents()

	for i=1,5 do
		self:mapUiElement(i, function()
			return ClothNode.seek(self,"item"..i)
		end)
		self[i]:hide()
	end

	girl.addTouchEventListener(self,{swallow = false,
	onBegan = function(touch,event)
		return true
	end,
	onEnded = function(touch, event)
		local touchPos = touch:getLocation()
		for i=1,5 do
			if cc.rectContainsPoint(self[i]:getCascadeBoundingBox(), touchPos) then
				if self.pb[i] then
					local buyNode = BuyGiftNode.create({class_id = self.pb[i].class_id,type = 2})
					buyNode:addTo(self,10)
					-- dump(self:getCascadeBoundingBox())
					buyNode:setPositionY(-self:getPositionY()+self[i]:getCascadeBoundingBox().height/2)
				end
			end
		end
	end})
end

function ClothShopBannerNode:onEnter()
    ClothShopBannerNode.super.onEnter(self)
end

function ClothShopBannerNode:onExit()
    ClothShopBannerNode.super.onExit(self)
end

function ClothShopBannerNode:refresh(pb)
	dump(pb)
	self.pb = pb
	for i,v in ipairs(pb) do
		dump(v)
		self[i]:show()
		self[i]:refresh(v)
	end
end

return ClothShopBannerNode

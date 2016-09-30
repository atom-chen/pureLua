local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("...controls.CocostudioNode")

-- singleton
local infoMgr 	    = import("....data.information.InfoManager"):getInstance()
local resMgr 	    = import("....data.information.ResManager"):getInstance()

local GiftShopNode  = class("GiftShopNode",AnimationNode)

GiftShopNode.csb = "nodes/edu/giftShopItem.csb"

function GiftShopNode.create()
	local params = {}
	params.csbName = GiftShopNode.csb
	return GiftShopNode.new(params)
end

function GiftShopNode.seek(parentNode,nodeName)
    return GiftShopNode.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        csbName    = GiftShopNode.csb
    })
end

function GiftShopNode:ctor(params)
	GiftShopNode.super.ctor(self,params)
    self:enableNodeEvents()

    self:mapUiElements({"itemSprite", "goldCountText"})
end

function GiftShopNode:onEnter()
    GiftShopNode.super.onEnter(self)
end

function GiftShopNode:onExit()
    GiftShopNode.super.onExit(self)
end

function GiftShopNode:refresh(pb)
    local info = infoMgr:findInfo("devProps", "class_id", pb.class_id)
    -- dump(info)
    local function _writePrice(price)
        self.goldCountText:setString(tostring(price))
    end

    local function _writeIcon(iconId)
        self.itemSprite:setTexture(resMgr:getResPath(iconId))
    end

    if info then
        _writePrice(info.price)
        _writeIcon(info.resId)
    end

end

return GiftShopNode

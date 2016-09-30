local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode       = import("...controls.CocostudioNode")

-- singleton
local infoMgr 	          = import("....data.information.InfoManager"):getInstance()
local resMgr 	          = import("....data.information.ResManager"):getInstance()
local playerMgr 	      = import("....data.PlayerDataManager") :getInstance()
local ws                  = import("....extra.NetWebSocket", CURRENT_MODULE_NAME) :getInstance()
local pbBuilder           = import("....extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()

local BuyGiftNode = class("BuyGiftNode",AnimationNode)


function BuyGiftNode.create(params)

    if params.type == 1 then
        params.csbName = "nodes/edu/buyGift.csb"
    else
        params.csbName = "nodes/edu/buyCloth.csb"
    end
	return BuyGiftNode.new(params)
end

function BuyGiftNode:ctor(params)
	BuyGiftNode.super.ctor(self,params)
    self:enableNodeEvents()

    self:mapUiElements({"iconSprite", "needGoldText", "messageText", "titleText", "haveGoldText", "confimNode", "cancelNode", "rootImage"})

    if params.type == 1 then
        self:mapUiElements({"needGoldTopText", "buyCountText"})
    end

    girl.addTouchEventListener(self,{swallow = true})

    self.classId  = params.class_id
    self.type     = params.type
    self.buyCount = 1

    self:refresh(self.classId)
    self.rootImage:setLocalZOrder(2)
end

function BuyGiftNode:onEnter()
    BuyGiftNode.super.onEnter(self)
    local mask = display.newLayer(cc.c4b(0,0,0,255*0.8)):addTo(self, 1)
    mask:setTouchEnabled(false)
    mask:align(cc.p(0.5, 0.5), -display.size.width / 2, -display.size.height / 2)
    self:runAnimation("in")

    -- 这个是取消
    self.cancelNode:onButtonClicked("confirmButton", function()
        self:removeSelf()
    end)

    -- 这个是确定
    self.confimNode:onButtonClicked("cancelButton", function()

		if self.type == 1 then
	        local pb    = pbBuilder:build({
	              proto = "data/pb/interface/buyDevProp.pb",
	              desc  = "interface.buyDevProp.Request",
	              input = { devProp_id = self.classId,
	                        count = self.buyCount } })
	        ws:send("BUY_GIFT", pb, function(resultCode, des, data)
	            if resultCode == 0 then
	                self:removeSelf()
                else
                    -- lost error message box
                    self:removeSelf()
	            end
	        end)
		else
			local pb    = pbBuilder:build({
	              proto = "data/pb/interface/buyFashion.pb",
	              desc  = "interface.buyFashion.Request",
	              input = { fashion_id = self.classId} })
	        ws:send("BUY_FASHION", pb, function(resultCode, des, data)
	            if resultCode == 0 then
	                self:removeSelf()
                    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.CLOTH_SHOP_REFRESH)
                else
                    -- lost error message box
                    self:removeSelf()
	            end
	        end)
		end

    end)

	if self.type == 1 then
		self:onButtonClicked("addButton", function()
			self.buyCount = self.buyCount + 1
			self:refresh()
		end)

		self:onButtonClicked("subButton", function()
			if self.buyCount > 1 then
				self.buyCount = self.buyCount - 1
				self:refresh()
			end
		end)
	end

end

function BuyGiftNode:refresh(class_id)

	local classId = class_id or self.classId

    -- dump(info)
    local function _writePrice(price)
        self.needGoldText:setString(tostring(self.buyCount * price))
        if self.type == 1 then
           self.needGoldTopText:setString(tostring(price))
        end
    end

    local function _writeIcon(iconId,soulId)
        -- dump(iconId)
        if self.type == 1 then
            self.iconSprite:setTexture(resMgr:getResPath(iconId))
        else
            if iconId~=0 then
                self.iconSprite:setTexture(resMgr:getResPath(iconId))
            else
                self.iconSprite:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_CLOTH,soulId,classId))
            end
        end
    end

    local function _writeTitle(title)
        self.titleText:setString(title)
    end

    local function _writeInstruction(instruction)
        self.messageText:setString(instruction)
    end

    local function _writeHaveGold(gold)
        self.haveGoldText:setString(gold)
    end

	local function _writeBuyCount(count)
        self.buyCountText:setString(count)
    end

    local info
    if self.type == 1 then
        info = infoMgr:findInfo("devProps", "class_id", classId)
    	if self.buyCount then
            _writeBuyCount(self.buyCount)
       	end

		if info then
			_writeIcon(info.resId)
		end
    else
        info = infoMgr:findInfo("fashions", "class_id", classId)
        -- dump(info)
		if info then
			_writeIcon(info.resId, info.soulId)
		end
    end

    if info then
        _writePrice(info.price)
        _writeTitle(info.name)
        _writeInstruction(info.instruction)
    end

    if playerMgr then
        _writeHaveGold(playerMgr.status.gold)
    end

end

return BuyGiftNode

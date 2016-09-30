local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode  = import("..controls.CocostudioNode")
local infoMgr        = import("...data.information.InfoManager",CURRENT_MODULE_NAME):getInstance()
local resMgr         = import("...data.information.ResManager" ,CURRENT_MODULE_NAME):getInstance()
local ws             = import("...extra.NetWebSocket",          CURRENT_MODULE_NAME):getInstance()
local pbBuilder      = import("...extra.ProtobufBuilder",       CURRENT_MODULE_NAME):getInstance()
local playerMgr      = import("...data.PlayerDataManager",      CURRENT_MODULE_NAME):getInstance()
local musicManager   = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local BagItemNode  = class("BagItemNode", AnimationNode)



function BagItemNode.create(param)

  
    
    return BagItemNode.new({csbName = "nodes/bag/bag_info_anima.csb",index = param.index,id = param.id,type = param.type,count = param.count})

end



function BagItemNode:ctor(params)

     self.index = params.index
     self.id    = params.id
     self.type  = params.type
     self.count = params.count

     -- print(self.id)
     -- print(self.type)
     -- print(self.count)

     self.typeTable = {"props","materials","assemblages"}

     self.info = infoMgr:findInfo(self.typeTable[self.type],"class_id",self.id)

     --dump(self.info)

     BagItemNode.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"CheckBox_1","itemNameText","itemCountText","priceText","sliderNode","itemIconSprite","instructionText","text",
     	                 "girlIcon_1","equipIcon_1","changeStateNode","changeText","minusButton","plusButton","confirmButton","buttonNode"})

     --Helpers:dumpNode(self)

     self.sell      = false
     self.sellCount = 1
end

function BagItemNode:onEnter()
    --按钮名改为使用
	self.text            :setString("使用")
    print(self.type)
    --如果物品不是消耗品，则隐藏使用按钮
    if self.type ~= 1 then
       self.buttonNode:setVisible(false)
    end
	--设置物品名字，数量，描述，单价
    self.itemNameText    :setString(self.info.name)

    self.itemCountText       :setString(self.count)
    self.instructionText :setString(self.info.instruction)
    self.priceText       :setString(self.info.price)

    --物品的品质颜色框
    self.equipIcon_1 :runAnimation(string.format(self.info.quality))
    --物品的ICON图标
    --local sprite = cc.Sprite:create(resMgr:getResPath(self.info.resId))
    self.itemIconSprite:setTexture(resMgr:getResPath(self.info.resId))

    --复选框响应事件--------------------------------------------------------
    local function selectedEvent(sender,eventType)
        musicManager:play(girl.UiMusicId.BAG_CHOOSE)
        if eventType == ccui.CheckBoxEventType.selected then
           self.sliderNode:runAnimation("in",false)
           self.sell = true
           self.changeText:setString(self.sellCount)
           self:refreshLoadingBarAndcountText()
           self:sendMessages("new")
           --新增了一样出售的东西
        elseif eventType == ccui.CheckBoxEventType.unselected then
           self.sliderNode:runAnimation("out",false)
           
           self:sendMessages("cancel")
           self.sellCount = 1
           --复选框取消后讲count清1
        end
    end  

    self.CheckBox_1:addEventListener(selectedEvent)  
    --复选框响应事件--------------------------------------------------------


    ------加数量和减数量按钮事件---------------------------------------------
    self.plusButton:onClicked(function()
         musicManager:play(girl.UiMusicId.BAG_COUNT_CHANGE)
         if self.sellCount >= self.count then
         	print("达到最大数量")
         	return
         end
         self.sellCount = self.sellCount + 1
         --刷新loadingbar和countText
         self:refreshLoadingBarAndcountText()
         self:sendMessages("+")
    end)

    self.minusButton:onClicked(function()
       musicManager:play(girl.UiMusicId.BAG_COUNT_CHANGE)
    	 if self.sellCount <= 1 then
         	print("数量为一")
         	return
         end
         self.sellCount = self.sellCount - 1
         --刷新loadingbar和countText
         self:refreshLoadingBarAndcountText()
         self:sendMessages("-")
    end)

    self.confirmButton:onClicked(function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        local pb = pbBuilder:build({
        proto = "data/pb/interface/useProp.pb",
        desc  = "interface.useProp.Request",
        input = { class_id = self.id}
        })
        ws:send( "USE_PROP", pb, function(resultCode, des)
           print("USE_PROP:", resultCode,des)

           if resultCode == 0 then
            dump(playerMgr.props)
            self.count = 0
              for k,v in pairs(playerMgr.props) do
                  --self.count = 0
                  if self.id == v.class_id then
                     self.count = v.count
                     break
                  end
              end
              self:sendUseMessage()
              print(self.count)
              if self.count  then
                self.itemCountText:setString(self.count)
              end

           end
        end)
    end)

    


end

function BagItemNode:sendMessages(operate)
	if operate == "+" then
	   MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.SELLPRICE_CHANGE,
	   	                         {price = 0 + self.info.price,index = self.index,count = self.sellCount,new = false})
	elseif operate == "-" then
	   MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.SELLPRICE_CHANGE,
	   	                         {price = 0 - self.info.price,index = self.index,count = self.sellCount,new = false})
	elseif operate == "new" then
	   MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.SELLPRICE_CHANGE,
	   	                         {price = 0 + self.info.price,index = self.index,count = self.sellCount,new = true})
	else
	   MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.SELLPRICE_CHANGE,
	   	                         {price = 0 - self.sellCount * self.info.price,index = self.index,count = 0,new = false})
	end

end

function BagItemNode:sendUseMessage()
   print("sendMessages", self.count)
    MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.USE_PROP,{count = self.count})

end


function BagItemNode:refreshLoadingBarAndcountText()
    --self.loadingBar:setPercent(self.sellCount/self.count*100)
    self.changeText:setString(self.sellCount)
end


function BagItemNode:changeSellState()
    self.changeStateNode:runAnimation("sell",false)

end

function BagItemNode:changeUseState()
    self.changeStateNode:runAnimation("bag",false)
    if self.type ~= 1 then
       self.buttonNode:setVisible(false)
    end

end



return BagItemNode

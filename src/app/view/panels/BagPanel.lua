
local CURRENT_MODULE_NAME = ...
-- classes
local BagItemNode         = import("..fragment.BagItemNode",CURRENT_MODULE_NAME)
local PanelBase           = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode       = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local HeroShow            = import("..fragment.HeroPanelFragment.HeroShow", CURRENT_MODULE_NAME)
local HeroInfo            = import("..fragment.HeroPanelFragment.HeroInfo", CURRENT_MODULE_NAME)
local HeroEquipment       = import("..fragment.HeroPanelFragment.HeroEquipment", CURRENT_MODULE_NAME)
local Hero 			      = import("..battle.Hero", CURRENT_MODULE_NAME)
-- singleton
local panelFactory        = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr           = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr             = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr              = import("...data.information.ResManager" , CURRENT_MODULE_NAME):getInstance()
local ws                  = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder           = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local musicManager        = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

-- local cocos = import("cocos2d");

-- local listerner = cc.EventListenerCustom:create()
-- cocos.createCustomEventListerner(EVENT_NAME, function(){

--   });

--
-- 背包
--
local BagPanel = class("BagPanel", PanelBase)

function BagPanel.create(id)
    return BagPanel.new({ csbName = "layers/Bag.csb" }, id)
end

function BagPanel:ctor(params, id)
    BagPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self.id         = id
    self:mapUiElements({"ListView_1","allNode","materialNode","drawingNode","stoneNode","consumablesNode","sellNode","calculateNode"
    	                ,"sellAllButton","finalPriceText"})

    --初始化背包信息数据（数据整合在self.bagTable 表中）
    self:initBagData()

    --注册总出售价格变化监听
    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.SELLPRICE_CHANGE,handler(self, self.changeFinalPriceText))
    --注册使用物品事件监听
    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.USE_PROP,handler(self, self.useProp))
    --初始化总出售价格为0
    self.finalPrice = 0

    --初始化要卖出的物品表
    --镜像表
    self.sellTable = {}
    --最终传给服务器的表
    self.finalSellTable = {}

    self.typeTable = {"PROP","MATERIAL","ASSEMBLAGE"}


    self.lastSelect = 1
    self.currSelect = 1

    self.groupCount = 1   --listView 动态加载数据，每次滑动到底部时候加载20组，self.groupCount计数+1
end

function BagPanel:onEnter()
	print("BagPanel:onEnter")
    local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
    bg:setLocalZOrder(-100)
	  BagPanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})


    self:runAnimation("in",false,function()
       -- for i=1,#self.bagTable do
       --     self["banner"..i] :runAnimation("in", false)
       -- end
    end)
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)


    self.parentNode = {self.allNode,self.materialNode,self.drawingNode,self.stoneNode,self.consumablesNode}
    local animationTable = {"quanbu","cailiao","tuzhi","xiaohaopin","linhunshi"}


    for i=1,5 do
       --local item =  AnimationNode.seek(self.parentNode[i], "Text_1")
       --local item1 =  AnimationNode.seek(self.parentNode[i], "Text_1_0")
       --item:setString(text[i])
       --item1:setString(text[i])
       self.parentNode[i]:runAnimation(animationTable[i].."On",false)
       self["funcButton"..i] = AnimationNode.seek(self.parentNode[i], "Button_9")
    end

    self.allNode:runAnimation("quanbuOff", false)
    self.lastSelect = 1


    for i=1,5 do
        self["funcButton"..i]:setTag(i)
        self["funcButton"..i]:onClicked(function(event)
            musicManager:play(girl.UiMusicId.BUTTON_CLICK)
            print(event.target:getTag())
            self.parentNode[self.lastSelect]:runAnimation(animationTable[self.lastSelect].."On", false)
            self.currSelect = event.target:getTag()
            self.parentNode[self.currSelect]:runAnimation(animationTable[self.currSelect].."Off", false)
            self:initListView(self.currSelect)
            self.lastSelect = self.currSelect
            self.groupCount = 1
        end)
    end
    self:onButtonClicked("sell",function()
      musicManager:play(girl.UiMusicId.BUTTON_CLICK)

    	self.sellNode:runAnimation("return_in",false)
    	self.calculateNode:runAnimation("in",false)
        self:showFinalPriceText()
        --item条切换成售卖状态
        print(#self.funTable[self.currSelect])

        local itemTbale = self.ListView_1:getItems()
        for i=1,#itemTbale do
          self["banner"..i]:changeSellState()
        end


    end)

    self:onButtonClicked("return",function()
      musicManager:play(girl.UiMusicId.BUTTON_CLICK)

    	self.sellNode:runAnimation("sell_in",false)
    	self.calculateNode:runAnimation("out",false)
        --item条切换成使用状态

      local itemTbale = self.ListView_1:getItems()
        for i=1,#itemTbale do
          self["banner"..i]:changeUseState()
        end

        -- --将总价格清0
        -- self.finalPrice = 0
    end)

    -- 批量出售按钮
    self:onButtonClicked("sellAllButton",function()
      musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        print("sellAllButton")
        local pb = pbBuilder:build({
        proto = "data/pb/interface/sellItem.pb",
        desc  = "interface.sellItem.Request",
        input = { items = self.finalSellTable}
        })
        ws:send( "SELLITEM", pb, function(resultCode, des)
           print("SELLITEM:", resultCode,des)

           if resultCode == 0 then
              self:reload()
              musicManager:play(girl.UiMusicId.BAG_SELL)
           end
        end)
    end)


    self:initListView(1)

    self.ListView_1:onEvent(function(event)
       --dump(event)
       --print(event.target:getCurSelectedIndex())
       local parentItem = event.target:getChildByTag(event.target:getCurSelectedIndex()+1)
    end)

   -- local function scrollViewEvent(sender, eventType)
   -- print("11111111111")
   -- dump(eventType)
   --      if eventType == ccui.ScrollviewEventType.scrollToBottom then
   --          print("滑到了底部")
   --      elseif eventType == ccui.ScrollviewEventType.scrolling then
   --         print("onScroll")
   --      end

   --  end

   --  self.ListView_1:addEventListener(scrollViewEvent)









    self.ListView_1:onScroll(function(event)

      if event.name == "BOUNCE_BOTTOM" then
        for i=20*self.groupCount+1,#self.funTable[self.lastSelect] do
            -- print(i)
            if i >= 20*(self.groupCount+1)+1 then
               --print(i)
               print("超过了%d个",20*(self.groupCount+1)+1)
               break
            end
        self["banner"..i] = BagItemNode.create({index = i,id = self.funTable[self.lastSelect][i].class_id,type = self.funTable[self.lastSelect][i].type,count = self.funTable[self.lastSelect][i].count})
        local custom_item = ccui.Layout:create()
        custom_item:setTouchEnabled(true)
        custom_item:setContentSize(cc.size(self["banner"..i]:getCascadeBoundingBox().width,self["banner"..i]:getCascadeBoundingBox().height))
        self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
        custom_item:addChild(self["banner"..i])
        custom_item:setTag(i)
        self.ListView_1:pushBackCustomItem(custom_item)
        end
        self.groupCount = self.groupCount+1
      end
       --print("onScroll")
       --print(self.ListView_1:getInnerContainer():getPositionY())
       -- print(self.ListView_1:scrollListener(event))



    end)


end

function BagPanel:initBagData()
    self.keyProps = {}
    --dump(playerMgr.props)
    for k,v in girl.pairsByKeys(playerMgr.props) do
       table.insert(self.keyProps,v)
    end
    --自定义一个背包表结构
    self.bagTable = {}

    self.props = {}
    for k,v in pairs(self.keyProps) do
        table.insert(self.props,{id = v.class_id,class_id = v.class_id ,type = 1,count = v.count,order = k})
    end
    dump(self.props)
    for k,v in pairs(self.props) do
        table.insert(self.bagTable,v)
    end
    --消耗品表

    --材料表
    self.keyMaterials = {}
    --dump(playerMgr.props)
    for k,v in girl.pairsByKeys(playerMgr.materials) do
       table.insert(self.keyMaterials,v)
    end

    self.materials = {}
    for k,v in pairs(self.keyMaterials) do
        table.insert(self.materials,{id = v.class_id,class_id = v.class_id ,type = 2,count = v.count,order = k + #self.props})
    end
    dump(self.materials)
    for k,v in pairs(self.materials) do
        table.insert(self.bagTable,v)
    end

    --元魂配件表
     self.keyAssemblages = {}
    --dump(playerMgr.props)
    for k,v in girl.pairsByKeys(playerMgr.assemblages) do
       table.insert(self.keyAssemblages,v)
    end

    self.assemblages = {}
    for k,v in pairs(self.keyAssemblages) do
        table.insert(self.assemblages,{id = v.id,class_id = v.class_id ,type = 3,count = 1,order = k + #self.props + #self.materials })
    end
    dump(self.assemblages)
    for k,v in pairs(self.assemblages) do
        table.insert(self.bagTable,v)
    end

    dump(self.bagTable)

    self.stones = {}

end

function BagPanel:showFinalPriceText()
   self.finalPriceText:setString(self.finalPrice)
end


function BagPanel:useProp(body,layer,msg,data)
    if data.count == 0 then
       self:initBagData()
       self:initListView(self.lastSelect)
    end
    --self:initListView(self.lastSelect)
    --self:getParent().topPanel:reload()
end

function BagPanel:changeFinalPriceText(body,layer,msg,data)
   -- print(data.price)
   -- print(data.index)
   -- print(data.count)
   -- print(data.new)
   -- print(self.finalPrice)
   self.finalPrice = self.finalPrice + data.price
   self:showFinalPriceText()

   if data.count == 0 then
      for k,v in pairs(self.sellTable) do
          if v.order == data.index then
             table.remove(self.sellTable,k)
             table.remove(self.finalSellTable,k)
             -- print("remove")
          end
      end
   else
      if data.new then
         local tb = clone(self.bagTable[data.index])
         table.insert(self.sellTable,     {id = tb.id,class_id = tb.class_id ,type = tb.type,count = data.count,order = tb.order})
         table.insert(self.finalSellTable,{id = tb.id,class_id = tb.class_id ,type = self.typeTable[tb.type],count = data.count})
      else
         for k,v in pairs(self.sellTable) do
            if v.order == data.index then
               self.sellTable[k].count = data.count
               self.finalSellTable[k].count = data.count
               -- print("change Count")
            end
         end
      end
   end
   --dump(self.sellTable)
   --dump(self.finalSellTable)
   --dump(self.bagTable)

end



function BagPanel:initListView(func)

  -- local itemTbale = self.ListView_1:getItems()
  -- for i=1,3 do
  --    itemTbale[i],
  -- end
   self.ListView_1:removeAllItems()
   self.funTable = {self.bagTable,self.materials,self.assemblages,self.props,self.stones}

   for i=1,#self.funTable[func] do
        if i >= 21 then
           print("超过了20个")
           break
        end
        self["banner"..i] = BagItemNode.create({index = i,id = self.funTable[func][i].class_id,type = self.funTable[func][i].type,count = self.funTable[func][i].count})
        local custom_item = ccui.Layout:create()
        custom_item:setTouchEnabled(true)
        custom_item:setContentSize(cc.size(self["banner"..i]:getCascadeBoundingBox().width,self["banner"..i]:getCascadeBoundingBox().height))
        self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
        custom_item:addChild(self["banner"..i])
        custom_item:setTag(i)
        self.ListView_1:pushBackCustomItem(custom_item)
    end

    for i=1,#self.funTable[func] do
        if i >= 21 then
           print("超过了20个")
           break
        end
        self["banner"..i] :runAnimation("in", false)
    end
end


function BagPanel:reload()
     --初始化要卖出的物品表
     --镜像表
     self.finalPrice = 0
     self.sellTable = {}
     --最终传给服务器的表
     self.finalSellTable = {}
     self:showFinalPriceText()
     --self.ListView_1:removeAllItems()
     self:initBagData()
     self:initListView(self.lastSelect)
     self.groupCount = 1
     self.sellNode:runAnimation("sell_in",false)
     self.calculateNode:runAnimation("out",false)
     --self:getParent().topPanel:reload()
end

function BagPanel:changeTypeRefreshList()

   print("changeTypeRefreshList")

end

function BagPanel:onShowEvents( events, params )


end

function BagPanel:onEquipmentEvents( events, params )


end

function BagPanel:onExit()

    BagPanel.super.onExit(self)
    MessageManager.removeMessageByLayerName(girl.MessageLayer.UI,girl.UiMessage.SELLPRICE_CHANGE)
    MessageManager.removeMessageByLayerName(girl.MessageLayer.UI,girl.UiMessage.USE_PROP)
end


return BagPanel

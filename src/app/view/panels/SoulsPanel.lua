local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GirlsCardNode = import("..fragment.GirlsCardNode",CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()

local SoulsPanel = class("SoulsPanel", PanelBase)

function SoulsPanel.create()
    return SoulsPanel.new({ csbName = "layers/girls/GirlsList.csb"})
end

function SoulsPanel:ctor(params)
    SoulsPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"listView","showAllNode","strengthenNode","advancedNode","composeNode","assembleNode","soulNumText"})

    self.fatherTable = {self.showAllNode,self.strengthenNode,self.advancedNode,self.composeNode,self.assembleNode}
    self.buttonTable = {self.showAllButton,self.strengthenButton,self.advancedButton,self.composeButton,self.assembleButton}
    self.textTable   = {"yilan","qianghua","jinhua","hecheng","zhuangpei"}
    self.childTable  = {self.showAll,self.strengthen,self.advanced,self.compose,self.assemble}
    print(self.textTable[1])

    for i=1,5 do
        self.childTable[i]  = AnimationNode.seek(self.fatherTable[i],"ProjectNode_2")
        self.buttonTable[i] = AnimationNode.seek(self.childTable[i],"Button_9")
        self.childTable[i]:runAnimation(self.textTable[i].."On")
    end

    self.souls = {}

    for k,v in girl.pairsByKeys(playerMgr.souls) do
        table.insert(self.souls,k)
    end
    --dump(self.souls)

    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.SOUL_RELOAD,handler(self, self.reload))
    print("=====================================")
   
end

function SoulsPanel:onEnter()

    local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
    bg:setLocalZOrder(-100)
    SoulsPanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})

    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.SOUL_RELOAD,handler(self, self.reload))

    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
    self:runAnimation("in", false,function()
       
    end)

    --dump(playerMgr.souls)
    -- print(#playerMgr.souls)
    self.soulNumText:setString(string.format("%d/50",#self.souls))

    self:refreshListView(true)

    local function onPanelClosed(reason)
        self:runAnimation("in")
        --self:refreshListView(false)
        self:show()
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
    end

    self.listView:onEvent(function(event)
        -- dump(event)
        --local num  =  # self.num
        --print(event.target:getCurSelectedIndex())
        local index = event.target:getCurSelectedIndex()+1

        if event.name == "ON_SELECTED_ITEM_END" then
            print(index)
            if self.lastSelect == 4 then
                return
            end

            if playerMgr.souls[self.souls[index]].star >=6 and self.lastSelect == 3 then
                print("已经满星")
                --return
            end

            --MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)

            for i=1,#self.souls do
                self["banner"..i]:hide()
            end
            if self.lastSelect == 1 then
                MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
            end
            self:runAnimation("out",false,function()
                if self.lastSelect == 1 then
                    panelFactory:createPanel(panelFactory.Panels.EduPanel,onPanelClosed,{id = self.souls[index],soulPanel = true}):addTo(self)
                elseif self.lastSelect == 2 then
                    panelFactory:createPanel(panelFactory.Panels.SoulsUpgradePanel,nil,{id = self.souls[index],edu = false }):addTo(self)
                elseif self.lastSelect == 3 then
                    panelFactory:createPanel(panelFactory.Panels.SoulsAdvancePanel,nil,{id = self.souls[index],edu = false }):addTo(self)
                elseif self.lastSelect == 5 then
                    panelFactory:createPanel(panelFactory.Panels.SoulsPeijianPanel,nil,{id = self.souls[index],edu = false }):addTo(self)
                end
            end)
        end
    end)

  ---功能按钮，listView中的Banner底部显示内容切换
  ---刚进Soul页面默认选择一览功能，INDEX为1
    self.lastSelect = 1

    self.childTable[1]:runAnimation("yilanOff",false)

    for i=1,5 do
        self.buttonTable[i]:setTag(i)
        self.buttonTable[i]:onClicked(function(event)

            if self.lastSelect == event.target:getTag() then
                print("两次一样 直接Return")
                return

            end

            if self.lastSelect == 5  then
                --self.listView:removeAllItems()
                self:refreshListView(true)
            end

            -- print(event.target:getTag())
            self.childTable[self.lastSelect]:runAnimation(self.textTable[self.lastSelect].."On",false)
            self.curSelect = event.target:getTag()
            self.childTable[self.curSelect]:runAnimation(self.textTable[self.curSelect].."Off",false)
            --if self.curSelect <= 4 then

            if self.curSelect == 4 then
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,
                          {message = girl.Message.FUNC_NOTOPEN,
                          code = girl.MessageCode.FUNC_NOTOPEN})
                          :addTo(self,100)
            end

            for i=1,#self.souls do
                if self.lastSelect == 5  then
                    --传去true代表这次的LIST是新加载的
                    self["banner"..i]:show()
                    self["banner"..i]:refreshFunc(self.saveSelect,self.curSelect,true)
                    if self.curSelect == 4 then
                       self["banner"..i]:hide()
                    end
                else
                    self["banner"..i]:show()
                    self["banner"..i]:refreshFunc(self.lastSelect,self.curSelect)
                    if self.curSelect == 4 then
                       self["banner"..i]:hide()
                    end
                end
            end

            if self.curSelect == 5 then
                --self.listView:removeAllItems()
                self:refreshListView(false)
                self.saveSelect = self.lastSelect
            end
            self.lastSelect = self.curSelect
        end)
    end
end

function SoulsPanel:reloadSoulAtk(soulId)

      for i=1,#self.souls do
         if self.souls[i] == soulId then
             self["banner"..i]:refreshAttack()
         end
      end
end



function SoulsPanel:reload(body,layer,msg,data)
  --dump(self.souls)


      for i=1,#self.souls do
         self["banner"..i]:show()
      end 

      if data.func == 1 then
         self:refreshTimes(data.id)
         self:reloadSoulAtk(data.id)
      elseif data.func == 2 then
         self:refreshFragments(data.id)
         self:reloadSoulAtk(data.id)
      elseif data.func == 3 then
         self:refreshSlots(data.id)
         --self:reloadSoulAtk(data.id)
      end

      --self:reloadSoulAtk(data.id)


end




function SoulsPanel:show()
      for i=1,#self.souls do
         self["banner"..i]:show()
      end
end

function SoulsPanel:refreshSlots(id)
      for i=1,#self.souls do
        --if self.souls[i] == id then
         self["banner"..i]:showSlotsInfo()
        -- print(id)
         --print(i)
        --end
      end
end

function SoulsPanel:refreshFragments(id)
      for i=1,#self.souls do
         if self.souls[i] == id then
         self["banner"..i]:refreshFragments()
        
         end
      end
end

function SoulsPanel:refreshTimes(id)
      for i=1,#self.souls do
         if self.souls[i] == id then
         self["banner"..i]:refreshTimes()
        
         end
      end
end

function SoulsPanel:reloadLoveLv(id)

      for i=1,#self.souls do
         if self.souls[i] == id then
            self["banner"..i]:refreshLoveLv()
         end
      end
end




function SoulsPanel:onExit()

    SoulsPanel.super.onExit(self)
    MessageManager.removeMessageByLayerName(girl.MessageLayer.UI,girl.UiMessage.SOUL_RELOAD)

end


function SoulsPanel:refreshListView(bool)
      self.listView:removeAllItems()

      for i=1,#self.souls do
         self["banner"..i] = GirlsCardNode.create({ id = self.souls[i], assemble = bool})
         local custom_item = ccui.Layout:create()
         custom_item:setTouchEnabled(true)
         custom_item:setContentSize(cc.size( self["banner"..i]:getCascadeBoundingBox().width, self["banner"..i]:getCascadeBoundingBox().height))
         self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
         custom_item:addChild(self["banner"..i])
         custom_item:setTag(i)
         self.listView:pushBackCustomItem(custom_item)
      end


      
end

return SoulsPanel

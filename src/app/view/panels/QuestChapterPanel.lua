local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local StatesButton  = import("..fragment.StatesButton", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()


local QuestChapterPanel = class("QuestChapterPanel", PanelBase)

function QuestChapterPanel.create()
  return QuestChapterPanel.new({ csbName = "layers/quest/Quest_chapter.csb"})
end

function QuestChapterPanel:ctor(params)
  QuestChapterPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"storyNode","activeNode","bossNode","resouceNode","ListView_1"})


   for i=1,3 do
      self["chapter"..i] = infoMgr:findInfo("chapters","class_id",i)
    
      self["resName"..i] = resMgr:getIconPath(resMgr.IconType.CHAPTER,i)

   end

  self.aniIndex = 1

end

function QuestChapterPanel:onEnter()
  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  musicManager:play(girl.BGM.CHAPTER)
	self:getParent().chapterPanel = true
  MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
	QuestChapterPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

   local function onPanelClosed(reason)
      if reason == "part" then
           --print("52312454124")
           self:runAnimation("in",false,function()
          --self.storyNode:runAnimation("loop", true)
           for i=1,3 do
               local node = "custom_item"..i
               local move =  cc.MoveBy:create(0.5,cc.p(-100,0))
               local fadeIn = cc.FadeIn:create(0.5)
               local action  = cc.Spawn:create(move,fadeIn)
               self[node]:runAction(action)
             end
             self.parentNode[self.lastSelect]:runAnimation("loop", true)
         end)
      end
   end




   self.parentNode = {self.storyNode,self.activeNode,self.bossNode,self.resouceNode}
   local btnName    = {"storyBtn","activeBtn","bossBtn","resouceBtn"}
   local stateName  = {"gushi","huodong","shijieboss","ziyuanzhan"}



    for i=1,4  do

    self:mapUiElement(btnName[i], function()
        return StatesButton.seek(self.parentNode[i], "typeNode", stateName[i])
    end)

    end

    --local btn = {self.storyBtn,self.activeBtn,self.bossBtn,self.resouceBtn}
     print(self["resName"..1])
     print(self["resName"..2])
     print(self["resName"..3])

    --  for i=1,3 do
    --     self["event_banner"..i]    = AnimationNode.load("nodes/quest/chapter.csb")
  
    --     local picSprite       = AnimationNode.seek(self["event_banner"..i],"chapterPicSprite")
    --     local chapterNameText = AnimationNode.seek(self["event_banner"..i],"nameText")

    --     local sprite = cc.Sprite:create(self["resName"..i])
    --     picSprite:setTextureByPlist(sprite:getTexture())
    --     chapterNameText:setString(self["chapter"..i].chapter_name)

    --     -- local picSprite    = AnimationNode.seek(event_banner,"chapterPicSprite")
    --     -- picSprite:setTextureByPlist()

    --     local node = "custom_item"..i

    --     self[node] = ccui.Layout:create()
    
    --     self[node]:setTouchEnabled(true)
        
    --     self[node]:setContentSize(cc.size( self["event_banner"..i]:getCascadeBoundingBox().width, self["event_banner"..i]:getCascadeBoundingBox().height))
    --     self["event_banner"..i]:setPosition(cc.p(0, self[node]:getContentSize().height /2.0))
    --     self[node]:addChild(self["event_banner"..i])
    --     self[node]:setCascadeOpacityEnabled(true)
    --     --self[node]:setPositionX(self[node]:getPositionX()+100)
    --     self.ListView_1:pushBackCustomItem(self[node])
        
    

    --     -- self.custom_item..i = ccui.Layout:create()
    --     -- self.custom_item..i:setTouchEnabled(true)
    --     -- self.custom_item:setContentSize(cc.size( event_banner:getCascadeBoundingBox().width, event_banner:getCascadeBoundingBox().height))
    --     -- event_banner:setPosition(cc.p(0, self.custom_item:getContentSize().height / 2.0))
    --     -- self.custom_item:addChild(event_banner)
    --     -- self.ListView_1:pushBackCustomItem(self.custom_item)
    -- end

    -- self:runAnimation("in",false,function()
    --   for i=1,3 do
    --       self["custom_item"..i]:setPositionX(self["custom_item"..i]:getPositionX()+100)
    --   end


    --     local function oneByone(index)
    --         self.aniIndex = index + 1
    --         if self["custom_item"..self.aniIndex] then
    --           local move    =  cc.MoveBy:create(0.2,cc.p(-100,0))
    --           local fadeIn  =  cc.FadeIn:create(0.2)
    --           local action  =  cc.Spawn:create(move,fadeIn)
    --           local func    =  cc.CallFunc:create(function()
    --                               oneByone(self.aniIndex)
    --                            end)
    --            local action1 = cc.Sequence:create(action,func,nil)
    --            self["custom_item"..self.aniIndex]:runAction(action1)
    --         end
            
    --     end

    --   local move    =  cc.MoveBy:create(0.2,cc.p(-100,0))
    --   local fadeIn  =  cc.FadeIn:create(0.2)
    --   local action  =  cc.Spawn:create(move,fadeIn)
    --   local func    =  cc.CallFunc:create(function()
    --                       oneByone(self.aniIndex)
    --                    end)
    --   local action1 = cc.Sequence:create(action,func,nil)
    --    self["custom_item"..1]:runAction(action1)
      
    --   -- for i=1,3 do

    --   --      local node = "custom_item"..i

    --   --      self[node]:setPositionX(self[node]:getPositionX()+100)
    --   --      local move =  cc.MoveBy:create(0.5,cc.p(-100,0))
    --   --      local fadeIn = cc.FadeIn:create(0.5)
    --   --      local action  = cc.Spawn:create(move,fadeIn)
    --   --      self[node]:runAction(action)
    --   -- end

    --     -- local function oneByone(index)
    --     --     if self["event_banner"..index] then
    --     --       self["event_banner"..index]:runAnimation("in", false, function()
    --     --       if self["event_banner"..index+1] then
    --     --          self["event_banner"..index+1]:runAnimation("in", false, function()
    --     --             oneByone(index+2)
    --     --           end)
    --     --       end
    --     --       end)
    --     --     end
            
    --     -- end
    --     -- oneByone(1)
   
    --  end)



    -- local itemTbale = self.ListView_1:getItems()
    -- local textTable = {"第一章","第二章","第三章","第四章","第五章","第六章","第七章","第八章","第九章","第十章"}
    -- for i=1,3 do

    -- local banner =  AnimationNode.seek(itemTbale[i], "numberText")
    -- banner:setString(textTable[i])
    -- end


    -- local lock =  AnimationNode.seek(itemTbale[1],   "lockSprite")
    -- lock:hide()


    -- local mask =  AnimationNode.seek(itemTbale[1],   "Image_2")
    -- mask:hide()

      self.lastSelect = 1

    

    self:runAnimation("in",false,function()
      self:reloadListView(1)
    end)

   self.parentNode[1]:runAnimation("loop", true)

     for i=1,4 do
        self[btnName[i]]:setButtonTag(i)
        self[btnName[i]]:onClicked(function(event)
        musicManager:play(6000004)
      
        self.curSelect = event.target:getTag()
        if self.curSelect == self.lastSelect then
            return
        end
        self.parentNode[self.lastSelect]:runAnimation("off", false)
        self.parentNode[self.curSelect]:runAnimation("loop", true)
        self:reloadListView(self.curSelect)
        self.lastSelect = event.target:getTag()
        end)
   end




     self.ListView_1:onEvent(function(event)
      dump(event)

      print(event.target:getCurSelectedIndex())

      local item = event.target:getChildByTag(event.target:getCurSelectedIndex()+1)


       if event.target:getCurSelectedIndex()+1 == 1 and event.name == "ON_SELECTED_ITEM_END" then



       for i=1,3 do
          local node = "custom_item"..i
          local move =  cc.MoveBy:create(0.5,cc.p(100,0))
          local fadeOut = cc.FadeOut:create(0.5)
          local action  = cc.Spawn:create(move,fadeOut)
          self[node]:runAction(action)
        end

        local delay  = cc.DelayTime:create(0.1)
        local outAction = cc.CallFunc:create(function()
            MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
            self:runAnimation("out", false, function()

             panelFactory:createPanel(panelFactory.Panels.QuestPartPanel,onPanelClosed,{ id = 1}):addTo(self)
          end)

        end)

        self:runAction(cc.Sequence:create(delay,outAction))






       end

    end)

    self.ListView_1:onScroll(function(event)

    end)





end

function QuestChapterPanel:reloadListView(chapterType)
     
      -- for i=1,3 do
      --     self["event_banner"..i]:runAnimation("out", false)
      -- end
      self.ListView_1:removeAllItems()
      self.aniIndex = 1

     if chapterType == 1 then
        for i=1,3 do
        self["event_banner"..i]    = AnimationNode.load("nodes/quest/chapter.csb")
        --event_banner:runAnimation("in", false)
        local picSprite       = AnimationNode.seek(self["event_banner"..i],"chapterPicSprite")
        local chapterNameText = AnimationNode.seek(self["event_banner"..i],"nameText")

        picSprite:setTextureByPlist(self["resName"..i])
        chapterNameText:setString(self["chapter"..i].chapter_name)

        local node = "custom_item"..i

        self[node] = ccui.Layout:create()
        self[node]:setTouchEnabled(true)
        self[node]:setContentSize(cc.size( self["event_banner"..i]:getCascadeBoundingBox().width, self["event_banner"..i]:getCascadeBoundingBox().height))
        self["event_banner"..i]:setPosition(cc.p(0, self[node]:getContentSize().height / 2.0))
        --self["event_banner"..i]:setOpacity(125)
        self[node]:addChild(self["event_banner"..i])
        self[node]:setCascadeOpacityEnabled(true)
        --self[node]:setPositionX(self[node]:getPositionX()+100)
        self["event_banner"..i]:hide()
        self.ListView_1:pushBackCustomItem(self[node])

        end

      --   local function oneByone(index)
      --       self.aniIndex = index + 1
      --       if self["custom_item"..self.aniIndex] then
      --         local move    =  cc.MoveBy:create(0.1,cc.p(-100,0))
      --         local fadeIn  =  cc.FadeIn:create(0.1)
      --         local action  =  cc.Spawn:create(move,fadeIn)
      --         local func    =  cc.CallFunc:create(function()
      --                             oneByone(self.aniIndex)
      --                          end)
      --          local action1 = cc.Sequence:create(action,func,nil)
      --          self["custom_item"..self.aniIndex]:runAction(action1)
      --       end
            
      --   end

      -- local move    =  cc.MoveBy:create(0.1,cc.p(-100,0))
      -- local fadeIn  =  cc.FadeIn:create(0.1)
      -- local action  =  cc.Spawn:create(move,fadeIn)
      -- local func    =  cc.CallFunc:create(function()
      --                     oneByone(self.aniIndex)
      --                  end)
      -- local action1 = cc.Sequence:create(action,func,nil)
      --  self["custom_item"..1]:runAction(action1)


        local function oneByone(index)
            
            if self["event_banner"..index] then
               self["event_banner"..index]:show()
               self["event_banner"..index]:runAnimation("in", false, function()
                    self.aniIndex = index + 1
                    oneByone(self.aniIndex)

               end)
            end
            
        end
        oneByone(1)
        -- self["event_banner"..1]:runAnimation("in", false, function()
        --      --oneByone(1)

        -- end)
       


        
        local itemTbale = self.ListView_1:getItems()
        local textTable = {"第一章","第二章","第三章","第四章","第五章","第六章","第七章","第八章","第九章","第十章"}
        for i=1,3 do

        local banner =  AnimationNode.seek(itemTbale[i], "numberText")
        banner:setString(textTable[i])
        end


        local lock =  AnimationNode.seek(itemTbale[1],   "lockNode")
        lock:hide()
        --lock:runAnimation("in", false)

     else
        local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,
                          {message = girl.Message.FUNC_NOTOPEN,
                          code = girl.MessageCode.FUNC_NOTOPEN})
                          :addTo(self,100)


     end

end

return QuestChapterPanel

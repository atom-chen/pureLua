local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local Soul          = import("..battle.Soul", CURRENT_MODULE_NAME)
local Hero          = import("..battle.Hero", CURRENT_MODULE_NAME)
local GirlsCellNode = import("..fragment.QuestTeamPanelFragment.GirlsCellNode",CURRENT_MODULE_NAME)
local HerosCellNode = import("..fragment.QuestTeamPanelFragment.HerosCellNode",CURRENT_MODULE_NAME)

--单例
local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()


local QuestTeamPanel = class("QuestTeamPanel", PanelBase)


function QuestTeamPanel.create(params)
     -- 创建出战选择界面的时候将前面一级章节选择界面的GateId传入
     return QuestTeamPanel.new({csbName = "layers/quest/Quest_team.csb",gateId = params.gateId})
end

function QuestTeamPanel:ctor(params)

  QuestTeamPanel.super.ctor(self, params)
  self:enableNodeEvents()
  self.gateId = params.gateId  --章节选择的gateId

  self:mapUiElements({"listview","soulNode1","soulNode2","soulNode3","heroNode","button","mapBackButton",
                      "yellowLight","soulPos1","soulPos2","soulPos3","heroPos","removeButton1","removeButton2","removeButton3",
                      "soulCountText","heroNameText","heroLvText","heroExpLoadingBar"})

  
   ---------3个元魂Node节点
   local nodeTable        = { self.soulNode1, self.soulNode2, self.soulNode3 }
   ---------3个元魂的删除按钮
   self.removeButtonTable = { self.removeButton1, self.removeButton2, self.removeButton3 }
   
   ---------3个元魂节点的加号
   for i=1,3 do
       local button        = "buttonSoul"..i 
       self[button]        = AnimationNode.seek(nodeTable[i],  "Button_1")
       self["addSoul"..i]  = AnimationNode.seek(nodeTable[i],  "addSoul")
   end

   --英雄的一些要显示数据的UI
   self.buttonHero         = AnimationNode.seek(self.heroNode,  "heroButton")
   self.heroNameText       = AnimationNode.seek(self.heroNode,  "heroNameText")
   self.heroLvText         = AnimationNode.seek(self.heroNode,  "heroLvText")
   self.heroExpLoadingBar  = AnimationNode.seek(self.heroNode,  "heroExpLoadingBar")
   self.heroStagePanel     = AnimationNode.seek(self.heroNode,  "heroStagePanel")
   self["blue"..4]         = AnimationNode.seek(self.heroNode,  "heroblueLight")

   ---------英雄节点的加号    
   self["addHero"]         = AnimationNode.seek(self.heroNode, "addHero")

   ---------蓝光
   for i=1,3 do
       self["blue"..i]     = AnimationNode.seek(self["soulNode"..i], "blueLight")
   end

   ---------3个元魂的位置节点，用来addTo spine
   for i=1,3 do
       --self["soulPos"..i]           = AnimationNode.seek(self["soulPos"..i],  "posNode")
       self["soulNameText"..i]      = AnimationNode.seek(self["soulNode"..i], "soulNameText")
       self["soulStage"..i]         = AnimationNode.seek(self["soulNode"..i], "stagePanel")
       self["soulExpLoadingBar"..i] = AnimationNode.seek(self["soulNode"..i], "soulExpLoadingBar")
       self["starCountText"..i]     = AnimationNode.seek(self["soulNode"..i], "Text_19")
       self["soulLvText"..i]        = AnimationNode.seek(self["soulNode"..i], "Text_18_0")
       self["soulTypeNode"..i]      = AnimationNode.seek(self["soulNode"..i], "icon_girls_fangyu")
   end

    self.whichNode  = 1  --黄光位置在哪里选中哪一个SoulNode对应 1，2，3
    self.lastBanner = 1  --左边ListView Banner的选中状态，上一个选择的和这一次选择的，刚进页面默认选择列表第一个
    self.currBanner = 0 

    self.whichList  = 0  --0代表当前显示的是元魂列表，1代表当前显示英雄列表

    self.order1 = 0      --初始化的时候，3个元魂位置对应的元魂在listView中的Index，开始3个都为0
    self.order2 = 0
    self.order3 = 0

   --初始化一些要用到的数据，playerMgr.souls用来加载左边listView数据，playerMgr.teams用来显示上次选择的队伍
   self.num          = {}    
   self.soulTable    = {}
   self.teams        = {}
   self.lastTimeTeam = {}
   self.herosList    = {}
   
   --------按顺序取得playerMgr.souls 里的每一个K，k为创建元魂时所需要的ID（不等于classID）
   for k,v in girl.pairsByKeys(playerMgr.souls) do
       table.insert(self.num,k)
   end

    -- dump(playerMgr.souls)
    -- dump(self.num)

   for k,v in girl.pairsByKeys(playerMgr.heros) do
       table.insert(self.herosList,k)
   end
   -- dump(self.herosList)


    if playerMgr.teams == nil then
        self.soul1 = nil
        self.soul2 = nil 
        self.soul3 = nil 
     else   
        print("服务器给我上次出阵数据")
        dump(playerMgr.teams)
        if playerMgr.goTeams == nil then
           for _,v in ipairs(playerMgr.teams) do
              if v.type == "STORY" then
                  for _,vM in ipairs(v.member) do
                      print("find team!")
                      if vM.type =="SOUL" then
                      print(vM.id, vM.type, vM.order)
                      table.insert(self.lastTimeTeam, {id = vM.id, order = vM.order} )
                      end
                  end
              end
           end
        else
            for k,v in pairs(playerMgr.goTeams) do
                table.insert(self.lastTimeTeam, {id = v.id, order = v.order} )
            end
           
        end
        
     end



end

function QuestTeamPanel:onEnter()

   local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel,onPanelClosed):addTo(self)      
   bg:setLocalZOrder(-100)  --背景图

   QuestTeamPanel.super.onEnter(self)
   girl.addTouchEventListener(self, {swallow = true})

   self:runAnimation("in", false,function()
       MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
    end)

   self.yellowLight:runAnimation("in", false)


   --左下角显示已拥有的元魂数量
   self.soulCountText:setString(string.format("%d/50",#self.num))

   --开始先设置元魂Banner的名字和状态都没有，等加载上次元魂以后再刷新
     for i=1,3 do
         self["soulNameText"..i]:setString("")
         self["soulStage"..i]:hide() 
     end

    --加载上次选择的队伍
    local soulNum = #self.lastTimeTeam

    for i=1,soulNum do
         self["soul"..self.lastTimeTeam[i].order] = Soul.createOnUiWithId(self.lastTimeTeam[i].id)
         self["soul"..self.lastTimeTeam[i].order]:setCascadeOpacityEnabled(true)
         local fadein = cc.FadeIn:create(1.0)
         self["soul"..self.lastTimeTeam[i].order]:runAction(fadein)

         self["soul"..self.lastTimeTeam[i].order]:addTo(self["soulPos"..self.lastTimeTeam[i].order]) 
         self.removeButtonTable[self.lastTimeTeam[i].order]:setVisible(true)
         self:reloadSoulNode(self.lastTimeTeam[i].order,self.lastTimeTeam[i].id)
         table.insert(self.teams,{id = self.lastTimeTeam[i].id, type = "SOUL", order = self.lastTimeTeam[i].order}  )
         self["addSoul"..self.lastTimeTeam[i].order]:setVisible(false)

         for k,v in ipairs(self.num) do

               if self.lastTimeTeam[i].id == v then
                  self["order"..self.lastTimeTeam[i].order] = k
                  --self["banner"..k]:setInTeam() 
                  print("取到上次选择的Team的ORDER位置的元魂是我现在左边soul listview里面的第几个，并标记为已出战")
               end
         end
      end
       
    print(self["order"..1])
    print(self["order"..2])
    print(self["order"..3])
    self.whichNode  = 1

    local index =  1 

    local function checkOrderHasSoul(index)
          if index == 4 then
             return false
          end
          if self["soul"..index] == nil then
             print("这个位置是空的")
            return false
          else
             print("这个位置有元魂了")
             return true
          end
    end

    while(checkOrderHasSoul(index))
    do
      print("value of index:",index)
      index = index+1
    end
    print("最终 index:",index)
    if index == 4 then
      self.whichNode  = 1
    else
      self.whichNode  = index
    end
   
     --加载左边元魂LIST数据
     self:initSoulList()
     --listView事件
     self.listview:onEvent(function(event)
        --print(event.target:getCurSelectedIndex())
         if event.name == "ON_SELECTED_ITEM_END" then
           local index = event.target:getCurSelectedIndex()+1
           print("currBanner",index)
           self.currBanner = index
           print("lastBanner",self.lastBanner)
           if self.currBanner == self.lastBanner then
              --self.lastBanner = self.currBanner 
              print("两次一样")
              return
           end
           if self.whichList == 0 and self.currBanner > #self.num or self.whichList == 1 and self.currBanner > #self.herosList then
              print("空白位置")
              return
           end
           self["banner"..self.currBanner]:changeSelected()
           self["banner"..self.lastBanner]:changeNormal()

           if self.whichList == 0 and self["soul"..self.whichNode] then
               for i=1,3 do
                   print("orderi",self["order"..i])
                   print("index",index)
                   if self["order"..i] == index then
                       print("这个元魂已经在出战队列里了")
                       self.lastBanner = self.currBanner 
                      return
                   end
               end
               print("setOutTeam",self.lastBanner)
               print("setInTeam",self.currBanner)

                self["soul"..self.whichNode]:removeFromParent()
                self["banner"..self["order"..self.whichNode]]:setOutTeam()
                self["soul"..self.whichNode] = Soul.createOnUiWithId(self.num[index])
                self["banner"..self.currBanner]:setInTeam()
                self["soul"..self.whichNode]:addTo(self["soulPos"..self.whichNode]) 
                self:reloadSoulNode(self.whichNode,self.num[index])
                self["order"..self.whichNode] = index

                  for i=1,#self.teams do
                    --dump(self.teams)
                    print("次数次数次数")
                    if self.teams[i].order == self.whichNode then
                    self.teams[i] = { id = self.num[index], type = "SOUL", order = self.whichNode}
                    break
                    end
                  end
              
           end
           self.lastBanner = self.currBanner 
          
         end
    end)


    self:refreshYellowLight(0,self.whichNode)   --黄光一开始的默认位置在第一个，两个参数第一个1为上一次黄光的位置，第二个1为这一次点击的黄光位置

    self.heroNum = {}
    for k,v in girl.pairsByKeys(playerMgr.heros) do
       table.insert(self.heroNum,k)
    end

    self.hero = Hero.createOnUiWithId(self.heroNum[1]):addTo(self.heroPos)
    self["addHero"]:setVisible(false)
    table.insert(self.teams,{id = self.heroNum[1], type = "HERO", order = 4})

     -- dump(playerMgr.heros[self.heroNum[1]])

     self.heroBaseInfo  = infoManager:findInfo("roles","class_id",playerMgr.heros[self.heroNum[1]].level)
     dump(self.heroBaseInfo)
     self.upLevelExp = self.heroBaseInfo.upLevelExp

     self.heroExpLoadingBar:setPercent(playerMgr.heros[self.heroNum[1]].exp/self.upLevelExp*100)
     --self.expText:setString(string.format("%d/%d",self.pb.exp,self.upLevelExp))

    self.heroNameText     :setString(playerMgr.heros[self.heroNum[1]].info.name)
    self.heroLvText       :setString(playerMgr.heros[self.heroNum[1]].level)
    --self.heroExpLoadingBar:setString("")
----================================================减号按钮======================================================  

   self.removeButton1:onClicked(function()
      if self.whichList  == 1  then
         print("此时为英雄列表")
         return
      end
      
      if self.soul1 then
         self.soul1:removeFromParent()
         self.soul1 = nil
         self["banner"..self["order"..1]]:setOutTeam()
         self["order"..1] = 0
         for i=1,#self.teams do
          dump(self.teams)
          print("次数次数次数")
            if self.teams[i].order == 1 then
              table.remove(self.teams,i)
              break
            end
          end
         self.removeButton1:setVisible(false)
         self["addSoul"..1]:setVisible(true)
         self["soulNameText"..1]:setString("")
         self["soulStage"..1]:hide()
         self:reloadSoulListSelect()
         self:yellowLightAI(self.whichNode)
      end
     
   end)

    self.removeButton2:onClicked(function()
        if self.whichList  == 1  then
          print("此时为英雄列表")
          return
        end
    
        if self.soul2 then
         self.soul2:removeFromParent()
         self.soul2 = nil
         self["banner"..self["order"..2]]:setOutTeam()
         self["order"..2] = 0
         for i=1,#self.teams do
            if self.teams[i].order == 2 then
               table.remove(self.teams,i)
              break
            end
          end
          print("order,order,order",self["order"..2])
          self.removeButton2:setVisible(false)
          self["addSoul"..2]:setVisible(true)
          self["soulNameText"..2]:setString("")
          self["soulStage"..2]:hide()
          self:reloadSoulListSelect()
          self:yellowLightAI(self.whichNode)
      end
       
   end)

  self.removeButton3:onClicked(function()
      if  self.whichList  == 1  then
          print("此时为英雄列表")
          return
      end
      if self.soul3 then
          self.soul3:removeFromParent()
          self.soul3 = nil
          self["banner"..self["order"..3]]:setOutTeam()
          self["order"..3] = 0
          for i=1,#self.teams do
            if self.teams[i].order == 3 then
                table.remove(self.teams,i)
                break
            end
          end
          self.removeButton3:setVisible(false)
          self["addSoul"..3]:setVisible(true)
          self["soulNameText"..3]:setString("")
          self["soulStage"..3]:hide()
          self:reloadSoulListSelect()
          self:yellowLightAI(self.whichNode)
      end
       
  end)


--------============================soulNode按钮and HeroNode按钮==================================


   self.buttonSoul1:onClicked(function()
        --self.lastIndex
        self:refreshYellowLight(self.whichNode,1)
   end)

   self.buttonSoul2:onClicked(function()
        self:refreshYellowLight(self.whichNode,2)
   end)

   self.buttonSoul3:onClicked(function()
        self:refreshYellowLight(self.whichNode,3)
   end)

   self.buttonHero:onClicked(function()
        self:refreshYellowLight(self.whichNode,4)

   end)
---=============================出击按钮===============================================
    self.button:onClicked(function()
        print("出击出击出击")
        self.button:setTouchEnabled(false)
        musicManager:play(girl.UiMusicId.TEAM_GOBATTLE)
        --dump(self.teams)
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT,{callback = function()

            local load = panelFactory:createPanel(panelFactory.Panels.LoadingPanel,nil)
            :addTo(self:getParent(),2000)
            self.button:setTouchEnabled(true)
            dump(self.teams)
            playerMgr:setGoTeam(self.teams)

            local pb = pbBuilder:build({
            proto = "data/pb/interface/enterBattle.pb",
            desc  = "interface.enterBattle.Request",
            input = { gate_id = self.gateId, 
                    story_team = {type = "STORY", member = self.teams  } }
                   })
                  ws:send("ENTERBATTLE", pb, function(resultCode, des, data)
                      dump(resultCode)
                      dump(des)
                      print(resultCode)
                      load:close()
                      
                      if resultCode == 0 then
                          
                          self.yellowLight:setVisible(false)
                          
                          for i=1,3 do
                            if self["soul"..i] then
                               self["soul"..i]:removeFromParent()
                               self.removeButtonTable[i]:setVisible(false)
                            end
                          end
                          self.hero:removeFromParent()

                          --self:runAnimation("go",false,function( )
                                self.battle = panelFactory:createPanel(panelFactory.Panels.BattlePanel,onPanelClosed,{gateId = self.gateId}):addTo(self:getParent())
                                self.battle:setLocalZOrder(200)
                                self.enter = 0
                                self:close()
                          --end)
                      else
                          MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
                          local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = des,code = 999})
                          :addTo(self:getParent(),200)

                      end
               end)
        end})
    end)

    self.mapBackButton:onClicked(function()
        self.hero:removeFromParent()
        for i=1,3 do
          if self["soul"..i] then
             self["soul"..i]:removeFromParent()
             self.removeButtonTable[i]:setVisible(false)
          end
        end
        self:runAnimation("out",false,function()
        self.yellowLight:setVisible(false)
        self:getParent():reloadGates()
        self:close()
        end)
    end)

end

function QuestTeamPanel:onExit()
    QuestTeamPanel.super.onExit(self,"QuestTeamPanel1")
end

function QuestTeamPanel:reloadSoulListSelect()
       self["banner"..self.lastBanner]:changeNormal()
       -- if max then
       --    self["banner"..index]:changeSelected()
       -- end


       local index =  1 
        local function checkInTeam(index)
             for k,v in pairs(self.teams) do
               if self.num[index] == v.id then
                  return true
               end
             end
             return false
        end

        while(checkInTeam(index))
        do
           print("value of index:",index)
           index = index+1
        end
           print("最终 index:",index)
           self["banner"..index]:changeSelected()
           self.lastBanner = index

end

function QuestTeamPanel:reloadSoulNode(whichNode,soulId)
    
  self["soulNameText"..whichNode]:setString(playerMgr.souls[soulId].info.name)   
  self["soulStage"..whichNode]:show()
  self["starCountText"..whichNode]:setString(playerMgr.souls[soulId].star)
  self["soulLvText"..whichNode]:setString(string.format(playerMgr.souls[soulId].level))
  self["soulTypeNode"..whichNode]:runAnimation(string.format(playerMgr.souls[soulId].info.type..playerMgr.souls[soulId].info.color))
  local expSoul = infoManager:findInfo("expSouls","class_id",playerMgr.souls[soulId].level)
  
  self["soulExpLoadingBar"..whichNode]:setPercent(playerMgr.souls[soulId].exp/expSoul.upLevelExp*100)

end

function QuestTeamPanel:yellowLightAI(num)

   local index =  1 
   local function checkOrderHasSoul(index)
          if index == 4 then
             return false
          end
          if self["soul"..index] == nil then
             print("这个位置是空的")
            return false
          else
             print("这个位置有元魂了")
             return true
          end
   end

    while(checkOrderHasSoul(index))
    do
      print("value of index:",index)
      index = index+1
    end
    print("最终 index:",index)
    if index == 4 then
      self.whichNode  = 1
    else
      self.whichNode  = index
    end

    self["blue"..num]:setVisible(true)
    self["blue"..self.whichNode]:setVisible(false)
    self.yellowLight:setPosition(self["soulNode"..self.whichNode]:getPosition())
   
end

function QuestTeamPanel:refreshYellowLight(which,num)

  if which == num then
     print("同一个不响应")
     if num <=3 and self["soul"..num]== nil then

     for i=1,3 do
      self.reult = 0
       if self["order"..i] == self.lastBanner then
          self.reult = i
          break
       end
     end
         if self.reult~=0 then
                      self["soul"..self.reult]:removeFromParent()
                      self["soul"..self.reult] = nil

                      self["order"..self.reult] = 0
                      self["addSoul"..self.reult]:setVisible(true)
                      self["removeButton"..self.reult]:setVisible(false)

                      self["soul"..num] = Soul.createOnUiWithId(self.num[self.lastBanner])
                      self["soul"..num]:addTo(self["soulPos"..num])   
                      self["order"..num] = self.lastBanner
                      self["soulNameText"..self.reult]:setString("")
                      self["soulStage"..self.reult]:hide()

                      for j=1,#self.teams do
                         --dump(self.teams)
                          print("次数次数次数")
                          if self.teams[j].order == self.reult then
                             self.teams[j] = { id = self.num[self.lastBanner], type = "SOUL", order = num}
                          break
                          end
                      end

                      self.removeButtonTable[num]:setVisible(true)
                      self["addSoul"..num]:setVisible(false)
                      self:reloadSoulNode(num,self.num[self.lastBanner])
                      print(self.lastBanner)
                      --出战图标
                      self["banner"..self.lastBanner]:setInTeam()
                      print("插入了一个新元魂")
        else
        self["soul"..num] = Soul.createOnUiWithId(self.num[self.lastBanner])
        self["soul"..num]:addTo(self["soulPos"..num])   
        self["order"..num] = self.lastBanner
        table.insert(self.teams,{id = self.num[self.lastBanner], type = "SOUL", order = num}  )
        self.removeButtonTable[num]:setVisible(true)
        self["addSoul"..num]:setVisible(false)
        self:reloadSoulNode(num,self.num[self.lastBanner])
        print(self.lastBanner)
        --出战图标
        self["banner"..self.lastBanner]:setInTeam()
        print("插入了一个新元魂")
        end
        
        if self["soul"..1] and self["soul"..2] and self["soul"..3]  then
           print("元魂选满了不用刷新左边LIST蓝色状态，也不用刷新黄光位置")
           return
        end
        self:yellowLightAI(num)
        self:reloadSoulListSelect()
     end
     return  --不用变换黄光位置
  end

   if which ==0 then
      self["blue"..num]:setVisible(false)
   else
      self["blue"..which]:setVisible(true)
      self["blue"..num]:setVisible(false)
   end

   if num == 4 then
      --self.whichNode = num
      self.whichList = 1 
      --self:changeListView()
      self.yellowLight:setPosition(self["heroNode"]:getPosition())
   else
      if which == 4 then
         self.whichNode = num
         self.whichList = 0
         self:initSoulList()
        
      end
      self.yellowLight:setPosition(self["soulNode"..num]:getPosition())
   end

  
   --self.yellowLight:setPosition(self["soulNode"..num]:getPosition())
   --self.whichNode = num
   self.whichNode = num
   if self["soul"..1] and self["soul"..2] and self["soul"..3]  then
        print(self.whichNode)
      if self.whichNode ==4 then
         print("切换到了英雄列表")
         self.saveIndex = which
         return
      else
         print(self.saveIndex)
         if self.saveIndex then
            self["banner"..self["order"..self.saveIndex]]:changeNormal()
            self.saveIndex = nil
         else
             if which ~= 0 then
                self["banner"..self["order"..which]]:changeNormal()
             end
         end
         self["banner"..self["order"..self.whichNode]]:changeSelected()
      end
    
   end
   

end


function QuestTeamPanel:changeListView()

    self.listview:removeAllItems()
    self.lastBanner = 1
    dump(playerMgr.heros)

    local count  =  # self.herosList
    for i=1,count do

         self["banner"..i] = HerosCellNode.create({ id = self.herosList[i]})
         local custom_item = ccui.Layout:create()
         custom_item:setTouchEnabled(true)
         custom_item:setContentSize(cc.size( self["banner"..i]:getCascadeBoundingBox().width, self["banner"..i]:getCascadeBoundingBox().height))
         self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
         custom_item:addChild(self["banner"..i])
         custom_item:setTag(i)
         self.listview:pushBackCustomItem(custom_item)

     end

     if count < 5 then
      for i=1+count ,5 do

          self["banner"..i] = HerosCellNode.create({ id = 0})
          local custom_item = ccui.Layout:create()
          custom_item:setTouchEnabled(true)
          custom_item:setContentSize(cc.size( self["banner"..i]:getCascadeBoundingBox().width, self["banner"..i]:getCascadeBoundingBox().height))
          self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
          custom_item:addChild(self["banner"..i])
          custom_item:setTag(i)
          self.listview:pushBackCustomItem(custom_item)
      end
        
     end

     if count>0 then
        self["banner"..1]:runAnimation("2")
     end

end

function QuestTeamPanel:closeSelf()
   -- self.battle = panelFactory:createPanel(panelFactory.Panels.BattlePanel,onPanelClosed,{gateId = self.gateId}):addTo(self:getParent():getParent())
   -- self.battle:setLocalZOrder(200)
   -- local onBattleStart = panelFactory:createPanel(panelFactory.Panels.PrepareFightPanel,onPanelClosed):addTo(self:getParent():getParent())
   -- onBattleStart:setLocalZOrder(220)
   -- self.enter = 0
   -- self:close()
end


function QuestTeamPanel:initSoulList()
   
     self.listview:removeAllItems()
     self.lastBanner = 1

     local count  =  # self.num
     for i=1,count do

         self["banner"..i] = GirlsCellNode.create({ id = self.num[i]})
         local custom_item = ccui.Layout:create()
         custom_item:setTouchEnabled(true)
         custom_item:setContentSize(cc.size( self["banner"..i]:getCascadeBoundingBox().width, self["banner"..i]:getCascadeBoundingBox().height))
         self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
         custom_item:addChild(self["banner"..i])
         custom_item:setTag(i)
         self.listview:pushBackCustomItem(custom_item)

         for k,v in pairs(self.teams) do
            if v.id == self.num[i] then
            self["banner"..i]:setInTeam() 
            print("标记为已出战")
            end
         end

     end

     if count < 5 then
      for i=1+count ,5 do

          self["banner"..i] = GirlsCellNode.create({id = 0})

          local custom_item = ccui.Layout:create()
          custom_item:setTouchEnabled(true)
          custom_item:setContentSize(cc.size( self["banner"..i]:getCascadeBoundingBox().width, self["banner"..i]:getCascadeBoundingBox().height))
          self["banner"..i]:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
          custom_item:addChild(self["banner"..i])
          custom_item:setTag(i)
          self.listview:pushBackCustomItem(custom_item)
      end
        
     end

     if count>0 then
        dump(self.teams)
        if self["soul"..1] and self["soul"..2] and self["soul"..3]  then
          print(self.whichNode)
           self["banner"..self["order"..self.whichNode]]:changeSelected()
           self.lastBanner = self["order"..self.whichNode]
           --return
        else
           self:reloadSoulListSelect()
        end

     end


     


   

    -- self.listview:onEvent(function(event)
      
    --   dump(event)
    --   local num  =  # self.num

    --   print(event.target:getCurSelectedIndex())
    --   local index = event.target:getCurSelectedIndex()+1

    --   if event.name == "ON_SELECTED_ITEM_END" then
    --     self.currBanner = index
    --       if num < 5 and  index >= (1+num) then
    --          return
    --       end
    --       if self.lastBanner ==0 then
    --          self["banner"..self.currBanner]:runAnimation("2")

    --          self.lastBanner = self.currBanner
    --          if self["order"..self.whichNode] == self.currBanner  then
    --                 print(self["order"..self.whichNode])
    --                 print(self.currBanner)
    --                 print("该位置的元魂与点击元魂为同一个REturn")
    --                return
    --          end
    --       else

    --          if self.lastBanner == self.currBanner then
    --             self["banner"..self.currBanner]:runAnimation("1")
                
    --             local temp = self.currBanner 
    --             self.lastBanner = 0
    --             self.currBanner = 0
    --             if self["order"..self.whichNode] == temp then
    --                 print("该位置的元魂与点击元魂为同一个REturn")
    --                 return
    --             end
                
    --          else
               
    --             self["banner"..self.lastBanner]:runAnimation("1")
               
    --             self["banner"..self.currBanner]:runAnimation("2")

    --             self.lastBanner = self.currBanner
    --             if self["order"..self.whichNode] == self.currBanner  then
    --                 print("该位置的元魂与点击元魂为同一个REturn")
    --                 return
    --             end
    --          end
    --       end
    --      -- self["banner"..index]:runAnimation("2")

    --       if self["soul"..self.whichNode] then
    --            for i=1,3 do
    --                if self["order"..i] == index then
    --                    print("这个元魂已经在出战队列里了")
    --                   return
    --                end
    --            end
    --             self["soul"..self.whichNode]:removeFromParent()
    --             self["soul"..self.whichNode] = Soul.createOnUiWithId(self.num[index])
    --             self["soul"..self.whichNode]:addTo(self["soulPos"..self.whichNode]) 
    --             self["order"..self.whichNode] = index

    --               for i=1,#self.teams do
    --                 --dump(self.teams)
    --                 print("次数次数次数")
    --                 if self.teams[i].order == self.whichNode then
    --                 self.teams[i] = { id = self.num[index], type = "SOUL", order = self.whichNode}
    --                 break
    --                 end
    --               end

    --             -- self.teams[self.whichNode] = { id = self.num[index], type = "SOUL", order = self.whichNode}
    --             -- print("换了新选择的元魂")

    --       else

    --            for i=1,3 do
    --                if self["order"..i] == index then
    --                  print("这个元魂已经在出战队列里了")
    --                  self["soul"..i]:removeFromParent()
    --                  self["soul"..i] = nil
    --                  self["order"..i] = 0
    --                  self["addSoul"..i]:setVisible(true)
    --                  self["removeButton"..i]:setVisible(false)
    --                  self["addSoul"..self.whichNode]:setVisible(false)
    --                  self["removeButton"..self.whichNode]:setVisible(true)

    --                  self["soul"..self.whichNode] = Soul.createOnUiWithId(self.num[index])
    --                  self["soul"..self.whichNode]:addTo(self["soulPos"..self.whichNode]) 
    --                  self["order"..self.whichNode] = index
    --                      for j=1,#self.teams do
    --                      --dump(self.teams)
    --                       print("次数次数次数")
    --                       if self.teams[j].order == i then
    --                          self.teams[j] = { id = self.num[index], type = "SOUL", order = self.whichNode}
    --                       break
    --                      end
    --                      end


    --                    return
    --                end
    --            end
    --            self["soul"..self.whichNode] = Soul.createOnUiWithId(self.num[index])
    --            self["soul"..self.whichNode]:addTo(self["soulPos"..self.whichNode])   
    --            -- self.teams = 
    --            self["order"..self.whichNode] = index
    --            table.insert(self.teams,{id = self.num[index], type = "SOUL", order = self.whichNode}  )
    --            -- self.teams[self.whichNode] = { id = self.num[index], type = "SOUL", order = self.whichNode}
    --            self.removeButtonTable[self.whichNode]:setVisible(true)
    --            self["addSoul"..self.whichNode]:setVisible(false)
    --            print("插入了一个新元魂")
    --       end
         
    --   end


    -- end)
          
        
end



return QuestTeamPanel

local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()


local QuestPartGetPanel = class("QuestPartGetPanel", PanelBase)


function QuestPartGetPanel.create(params)
  return QuestPartGetPanel.new({ csbName = "layers/quest/quest_get.csb",partInfo = params.partInfo,starNum = params.starNum,rewardInfo = params.info})
end

function QuestPartGetPanel:ctor(params)

  QuestPartGetPanel.super.ctor(self, params)
  self:enableNodeEvents()
  self:mapUiElements({"closeButton","loadingBar","rewardNode","gotStarText","boxNode1","boxNode2","boxNode3","boxNode4","boxNode5"})

  self.rewardInfo = params.rewardInfo
  self.starNum    = params.starNum
  self.partInfo   = params.partInfo

  print(self.starNum)
  print(self.partInfo.star)
  dump(self.rewardInfo)


  -- dump(playerMgr.stageRewards)
  
  -- dump(self.stageRewards)

  --self.get


  for i=1,5 do
     self["openButton"..i] = AnimationNode.seek(self["boxNode"..i],"openButton")
     self["openButton"..i]:setTag(i)
     self["needStarText"..i] = AnimationNode.seek(self["boxNode"..i],"needStarText")
  end

  self.twoBoxTable = {self.boxNode1,self.boxNode5}

 end

function QuestPartGetPanel:onEnter()

   QuestPartGetPanel.super.onEnter(self)
   girl.addTouchEventListener(self, {swallow = true})

   self:runAnimation("in", false)
   self.loadingBar:setPercent(self.starNum/self.partInfo.star*100)
   

   self.rewardNode:runAnimation(string.format(# self.rewardInfo))

   self.gotStarText:setString(string.format(self.starNum))
   
   if # self.rewardInfo == 2 then
     self:twoBoxFunc()
   end

  self.closeButton:onClicked(function()
       musicManager:play(girl.UiMusicId.BUTTON_CLICK)
       print(girl.UiMusicId.BUTTON_CLICK)
       self:getParent():reloadShowRewardNode()
       self:close()
  end)  

end

function QuestPartGetPanel:twoBoxFunc()
   
    self.stageRewards = {}
    for k,v in pairs(playerMgr.stageRewards) do
         dump(v)
    table.insert(self.stageRewards,v)
    end
    dump(self.stageRewards)
    dump(self.rewardInfo)


    self["needStarText"..1]:setString(self.rewardInfo[1][1].starNumber)
    self["needStarText"..5]:setString(self.rewardInfo[2][1].starNumber)

    print("self.starNum="..self.starNum)

    for i=1,#self.rewardInfo do

        if self.starNum >= self.rewardInfo[i][1].starNumber then
           print("第%d个箱子可以领奖励了",i)
           self.twoBoxTable[i]:runAnimation("tobe_loop", true)
           self["gotBox"..i] = false
        end
      --    for k,v in pairs(self.stageRewards) do
      --     print(v.reward_id[i])
      --     print(self.rewardInfo[1][1].class_id)
      --     if v.reward_id[i] == self.rewardInfo[1][1].class_id then
      --         print("这个箱子已经领过了1111111")
      --         self.twoBoxTable[1]:runAnimation("got", true)
      --         self["gotBox"..1] = true
      --     elseif v.reward_id[i] == self.rewardInfo[2][1].class_id then
      --           print("这个箱子已经领过了222222222")
      --         self.twoBoxTable[2]:runAnimation("got", true)
      --         self["gotBox"..2] = true
      --     end
      -- end
        for k,v in pairs(self.stageRewards) do

           if #v.reward_id == 1 then
              if v.reward_id[1] == self.rewardInfo[1][1].class_id then
                 print("第一个箱子领过了")
                 self.twoBoxTable[1]:runAnimation("got", true)
                 self["gotBox"..1] = true
              elseif v.reward_id[1] == self.rewardInfo[2][1].class_id then
                 print("第二个箱子领过了")
                 self.twoBoxTable[2]:runAnimation("got", true)
                 self["gotBox"..2] = true
             
              end
           elseif #v.reward_id == 2 and v.reward_id[1]== self.rewardInfo[1][1].class_id or v.reward_id[1]== self.rewardInfo[2][1].class_id then
            self.twoBoxTable[1]:runAnimation("got", true)
            self["gotBox"..1] = true
            self.twoBoxTable[2]:runAnimation("got", true)
            self["gotBox"..2] = true  
           end
         end



    end
  




   self["openButton"..1]:onClicked(function()
         
         if self.starNum < self.rewardInfo[1][1].starNumber then
             print("星星不够")
             panelFactory:createPanel(panelFactory.Panels.QuestPartBoxInfoPanel,nil,{info = self.rewardInfo[1]})
             :addTo(self)
             self:runAnimation("out", false)
             return
         end
         if self["gotBox"..1] then
            -- panelFactory:createPanel(panelFactory.Panels.GetMultPanel,nil,{info = self.rewardInfo[1]})
            -- :addTo(self,100) 
            --self:runAnimation("out", false)
            return
         end
         print(self.partInfo.class_id)

         local rewardId = tonumber(string.format(self.partInfo.class_id.."01"))
         self:sendGetRewardQuest(rewardId,1)

        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self["boxNode"..1]:runAnimation("boxopen",false)
    end)

    self["openButton"..5]:onClicked(function()

         if self.starNum < self.rewardInfo[2][1].starNumber then
            print("星星不够")
            panelFactory:createPanel(panelFactory.Panels.QuestPartBoxInfoPanel,nil,{info = self.rewardInfo[2]})
            :addTo(self) 
            self:runAnimation("out", false)
            return
        end
         if self["gotBox"..2] then
            print("领过")
           
            --self:runAnimation("out", false)
            return
         end

        local rewardId = tonumber(string.format(self.partInfo.class_id.."02"))
       
        self:sendGetRewardQuest(rewardId,2)

        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self["boxNode"..5]:runAnimation("boxopen",false)
    end)          
  
    

end

function QuestPartGetPanel:sendGetRewardQuest(rewardId,boxIndex)
    print(rewardId)

    local pb = pbBuilder:build({
         proto = "data/pb/interface/receiveStage.pb",
         desc  = "interface.receiveStage.Request",
         input = { id  = rewardId}
         })

     ws:send( "RECEIVESTAGE", pb, function(resultCode, des,data)
       print("RECEIVESTAGE:", resultCode,des,data)
       --self["gotBox"..boxIndex] = true
       if resultCode == 0 then
         self["gotBox"..boxIndex] = true
         musicManager:play(girl.UiMusicId.ITEM_GET)
         panelFactory:createPanel(panelFactory.Panels.GetMultPanel,nil,{info = self.rewardInfo[boxIndex]})
            :addTo(self,100) 
       end

     end)

end


return QuestPartGetPanel

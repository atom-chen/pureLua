local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GateButtonNode= import("..fragment.GateButtonNode",CURRENT_MODULE_NAME)


local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local QuestPartPanel = class("QuestPartPanel", PanelBase)


function QuestPartPanel.create(params)
  return QuestPartPanel.new({ csbName = "layers/quest/Quest_part.csb",id = params.id})
end

function QuestPartPanel:ctor(params)

    QuestPartPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self:mapUiElements({"pageView","mapBackButton","starText","partNumLabel","partNameText","mapEnterLNode",
                        "mapEnterRNode","starText","mapEnterButton","mapEnterBackButton","showRewardButton",
                        "leftArrowNode","rightArrowNode","showRewardNode","gateIdText","gateInfoText","bd_boss_2",
                         "head_boss01_3","Text_6_1","Text_6","Text_6_0","goldText","expText"}) --boss头像，等级，名字
    --读取该章的节ID

    self.id = params.id

    self.selectGateId = 0
    self.whichPart = 1


    self.stagesIdInt    = {}
    self.gatesIdInt     = {}
    self.gatesIconTable = {}


    self:readPartsInfo()    -- self.stagesInfoTable 所有的话信息

    for i=1,#self.stagesInfoTable do
       self:readPartsRewardsInfo(i)   -- 暂时先只做第一话的奖励测试功能
    end                               -- self.partRewardInfoTable

    -- dump(self.stagesInfoTable)

    for i=1,#self.stagesInfoTable do                       --# self.stagesInfoTable
      self:readGatesInfo(i)            -- i相当于part Id的作用，但是不等于part的class_id

    end                                -- self["gatesIdTable"..partIndex] 每一话包含的所有GATEId 用来创建GateButton
    --两个箭头按钮
    self.rightArrowBtn = AnimationNode.seek(self["rightArrowNode"],"arrowButton")
    self.leftArrowBtn  = AnimationNode.seek(self["leftArrowNode"],"arrowButton")

    self.openGateInfo = false   --左右弹出的关卡信息界面

    self.runingScript = false
end

function QuestPartPanel:readPartsInfo()

    local chapter = infoMgr:findInfo("chapters","class_id",self.id)

    self.stagesIdStr = string.split(chapter.stages_id,"#")
    -- dump(self.stagesIdStr)


    for i,v in ipairs(self.stagesIdStr) do
       local stageId = tonumber(v)
       table.insert(self.stagesIdInt,stageId)
    end
    -- dump(self.stagesIdInt)


    self.stagesInfoTable = {}
    for i,v in ipairs(self.stagesIdInt) do

        local stageInfo = infoMgr:findInfo("stages","class_id",v)
        table.insert(self.stagesInfoTable,stageInfo)
    end
    -- dump(self.stagesInfoTable)

end


function QuestPartPanel:readPartsRewardsInfo(partIndex)

    self.partRewardIdStr = string.split(self.stagesInfoTable[partIndex].chapterAwardId,"#")
    -- dump(self.partRewardIdStr)
    self.partRewardIdInt = {}
    for i,v in ipairs(self.partRewardIdStr) do
        v = tonumber(v)
        table.insert(self.partRewardIdInt,v)
    end
    -- dump(self.partRewardIdInt)
    self["partRewardInfoTable"..partIndex] = {}
    for i,v in ipairs(self.partRewardIdInt) do
        local rewardInfo = infoMgr:findInfos("rewards","class_id",v)
        table.insert(self["partRewardInfoTable"..partIndex],rewardInfo)
    end
    -- dump(self["partRewardInfoTable"..partIndex])
end

function QuestPartPanel:readGatesInfo(partIndex)

    local gatesIdStr = string.split(self.stagesInfoTable[partIndex].gates_id,"#")
    --dump(gatesIdStr)
    local gatesIdInt = {}
    self["gatesIdTable"..partIndex] = {}

    for i,v in ipairs(gatesIdStr) do
        local gateId = tonumber(v)
        table.insert(gatesIdInt,gateId)
    end
    self["gatesIdTable"..partIndex] = gatesIdInt
    self["gatesIconTable"..partIndex] = {}

    for i,v in ipairs(gatesIdInt) do

        local gate = infoMgr:findInfo("gates","class_id",v)

        table.insert(self["gatesIconTable"..partIndex],gate.icon_id)
    end
    print(partIndex)
    -- dump(self["gatesIconTable"..partIndex])
    local stagePosStr = string.split(self.stagesInfoTable[partIndex].position,"#")
    local gatePosStr = {}
    for i,v in ipairs(stagePosStr) do
        self["gatePosStr"..i] = string.split(v,",")
        table.insert(gatePosStr,self["gatePosStr"..i])
    end
    self["gatePos"..partIndex] = {}

    for i,v in ipairs(gatePosStr) do
        local x = tonumber(v[1])
        local y = tonumber(v[2])

        local pos = cc.p(x,y)

        table.insert(self["gatePos"..partIndex],pos)
    end
     -- dump(self["gatePos"..partIndex])
end


function QuestPartPanel:onEnter()

    QuestPartPanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})
    self:runAnimation("in", false)
    self.partNumLabel:setString("1")
    -- for _,v in ipairs(playerMgr.stages) do
    --    print(v.class_id, v.currentStar)
    -- end
    self.mapEnterLNode:setVisible(false)

    self.leftPosX  = self.mapEnterLNode:getPositionX()
    self.leftPosY  = self.mapEnterLNode:getPositionY()
    self.rightPosX = self.mapEnterRNode:getPositionX()
    self.rightPosY = self.mapEnterRNode:getPositionY()

    self:initShowRewardButton()
    self:reloadGates()
    self:reloadShowRewardNode()

    local function pageViewEvent(sender, eventType)
        -- dump(eventType)
        if eventType == ccui.PageViewEventType.turning then
            local pageView = sender
            local pageInfo = string.format("%d" , pageView:getCurPageIndex() + 1)
            if self.whichPart ~= pageView:getCurPageIndex() + 1 then
               musicManager:play(girl.UiMusicId.PAGE_SLIDE)
               print("不同才播放划动的声音")
            end
            self.whichPart = pageView:getCurPageIndex() + 1
            --print("pagepagepage",self.whichPage)
            --musicManager:play(girl.UiMusicId.PAGE_SLIDE)
            self.partNumLabel:setString(pageInfo)
            self.partNameText:setString(self.stagesInfoTable[self.whichPart].name)
            self.currentPartId = self.stagesInfoTable[self.whichPart].class_id
            self:reloadShowRewardNode()
            self:refreshArrowNode(self.whichPart)

            if self.openGateInfo then
                self.mapEnterRNode:runAnimation("out",false,function()
                self.mapEnterRNode:hide()
                self.openGateInfo = false
                end)
            end

        end
    end

    self.pageView:addEventListener(pageViewEvent)


    self.rightArrowBtn:onClicked(function()
        -- print("1111111self.whichPart",self.whichPart)
        if self.runingScript  then
           return
        end
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.pageView:scrollToPage(self.whichPart+1-1)
        self.whichPart =  self.whichPart + 1
        self:refreshArrowNode(self.whichPart)
         if self.openGateInfo then
                  self.mapEnterRNode:runAnimation("out",false,function()
                  self.mapEnterRNode:hide()
                  self.openGateInfo = false
              end)
         end
    end)

    self.leftArrowBtn:onClicked(function()
      -- print("1111111self.whichPart",self.whichPart)
        if self.runingScript  then
           return
        end
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.pageView:scrollToPage(self.whichPart-1-1)
        self.whichPart =  self.whichPart - 1
        self:refreshArrowNode(self.whichPart)
         if self.openGateInfo then
                  self.mapEnterRNode:runAnimation("out",false,function()
                  self.mapEnterRNode:hide()
                  self.openGateInfo = false
              end)
         end
    end)

    self.mapEnterButton:onClicked(function()

        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.pageView:removeAllPages()
        self.mapEnterRNode:hide()
        self.mapEnterRNode:runAnimation("out", false)
        local questTeam = panelFactory:createPanel(panelFactory.Panels.QuestTeamPanel1,onPanelClosed,{gateId = self.selectGateId})
                         :addTo(self)
        questTeam:setLocalZOrder(100)
        self.savePartIndex = self.whichPart
    end)

    self.mapEnterBackButton:onClicked(function()
        musicManager:play(girl.UiMusicId.WINDOW_CLOSE)
        -- print("mapEnterBackButton")
        self.mapEnterRNode:runAnimation("out",false,function()
           self.mapEnterRNode:hide()
        end)
    end)

    self.mapBackButton:onClicked(function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)

        self:runAnimation("out",false,function()
            self:close("part")
        end)
    end)
end

function QuestPartPanel:reloadShowRewardNode()
    self.showRewardNode:runAnimation("single1",false)
    self.stageRewards = {}
    -- dump(playerMgr.stageRewards)
    for k,v in pairs(playerMgr.stageRewards) do
        -- dump(v)
        table.insert(self.stageRewards,v)
    end
    --dump(self.stageRewards)

    if #self["stageOfgates"..self.whichPart] == 0 then
        -- print("这一话是新的")
        self.starText:setString(string.format("%d/%d",0,self.stagesInfoTable[self.whichPart].star))
        return
    end

    self.starText:setString(string.format("%d/%d",self.stages[self.whichPart].currentStar,self.stagesInfoTable[self.whichPart].star))
    --dump(self["partRewardInfoTable"..self.whichPart])

    for i=1,#self["partRewardInfoTable"..self.whichPart] do  --根据一话有多少个奖励的个数来循环
        print(self.whichPart)
        if self.stages[self.whichPart].currentStar >= self["partRewardInfoTable"..self.whichPart][1][1].starNumber and self.stages[self.whichPart].currentStar < self["partRewardInfoTable"..self.whichPart][2][1].starNumber then
            print("星星达到了领取条件")
            self.showRewardNode:runAnimation("loop",true)

            for k,v in pairs(self.stageRewards) do
                if #v.reward_id ==1 then
                    if v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][1][1].class_id then
                        print("已经领过了")
                        print(v.reward_id[i])
                        self.showRewardNode:runAnimation("single1",false)
                    elseif v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][2][1].class_id then
                        print("只领了第二个，第一个没有领")
                        self.showRewardNode:runAnimation("loop",true)
                    end
                elseif #v.reward_id == 2  then
                    if v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][1][1].class_id or v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][2][1].class_id then
                        print("已经领过了")
                        print(v.reward_id[i])
                        self.showRewardNode:runAnimation("single1",false)

                    end
                end
          end
        elseif self.stages[self.whichPart].currentStar >= self["partRewardInfoTable"..self.whichPart][2][1].starNumber then
            self.showRewardNode:runAnimation("loop",true)

            for k,v in pairs(self.stageRewards) do
                if #v.reward_id ==1 then
                    if v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][1][1].class_id or v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][2][1].class_id then
                        --self.showRewardNode:runAnimation("loop",true)
                        print("星星满了但是只有一个奖励数据，说明还有一个没领完")
                    end
                elseif #v.reward_id == 2  then
                    if v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][1][1].class_id or v.reward_id[1] == self["partRewardInfoTable"..self.whichPart][2][1].class_id then
                        print("已经领过了")
                        print(v.reward_id[i])
                        self.showRewardNode:runAnimation("single1",false)
                    end
                end
            end
        end
    end
end

function QuestPartPanel:reloadGates()

    --self.showRewardNode:runAnimation("loop",true)
    self.pageView:removeAllPages()
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
    self.stages = {}
    for k,v in girl.pairsByKeys(playerMgr.stages) do
        table.insert(self.stages,v)
    end

    table.sort(self.stages, function ( a,b )
        return a.class_id < b.class_id
    end)

    self.gates = {}
    for k,v in girl.pairsByKeys(playerMgr.gates) do
        table.insert(self.gates,v)
    end

    table.sort(self.gates, function ( a,b )
        return a.class_id < b.class_id
    end)

    for i=1,#self.stagesInfoTable do
        self["stageOfgates"..i] = {}
    end

    for i=1,#self.gates do
        for j=1,#self.stagesInfoTable do
            if math.floor(self.gates[i].class_id/100) == self.stagesInfoTable[j].class_id then
                table.insert(self["stageOfgates"..j],self.gates[i])
            end
        end
    end

    -- for i=1,#self.stagesInfoTable do
    --     dump(self["stageOfgates"..i])
    -- end

    --判断当前是否第一次玩游戏，是否有新话可以开锁，pageView默认锁定最新一话的位置
    if #self.stages == 0 then
        self.starText:setString(string.format("%d/%d" , 0,self.stagesInfoTable[1].star))
        self.stagesCount  = 1
    else
        print(#self["stageOfgates"..#self.stages])
        print( #self["gatesIdTable"..#self.stages])
        if #self["stageOfgates"..#self.stages]  == #self["gatesIdTable"..#self.stages] and self.gates[#self.gates].starRecord >= 0 then
            print("=============",#self.stagesInfoTable)
            if #self.stages == #self.stagesInfoTable then
                print("这一章所有话都打完了")
                self.newStage = false
                self.stagesCount  = #self.stages
                self.allPass      = true
            else
                self.allPass      = false
                self.newStage     = true
                self.stagesCount  = #self.stages+1
            end
            self.starText:setString(string.format("%d/%d",0,self.stagesInfoTable[self.stagesCount].star))
       else
          print("1234gfdfgh34bgfgf")
          self.allPass      = false
          self.newStage     = false
          self.stagesCount  = #self.stages
          self.starText:setString(string.format("%d/%d",self.stages[self.stagesCount].currentStar,self.stagesInfoTable[self.stagesCount].star))
       end

    end

    --判断当前是否有新关卡可以开锁

    if #self.gates == 0 then
        self.newGame = true             --表示玩家第一次玩游戏，只有关卡1可以打
    else
        if self.gates[1].starRecord == -1 then
            self.newGame = true
        else
            self.newGame = false
        end
        if self.gates[#self.gates].starRecord >= 0 and  self.allPass == false then
            print("表里的最后一关都打赢了，下一关可以解锁")
            self.newGate = true
            --self.gatesCount = #self.gates + 1
        else
            self.newGate = false
            --self.gatesCount = #self.gates
        end
    end
    -- print(self.stagesCount)
    for i = 1,self.stagesCount do

        local layout = ccui.Layout:create()
        layout:setContentSize(cc.size(display.width, display.height))

        local imageView = ccui.ImageView:create()
        imageView:setTouchEnabled(true)
        imageView:setScale9Enabled(false)
        imageView:loadTexture(resMgr:getIconPath(resMgr.IconType.CHAPTER_PART,self.id,i))
        imageView:setContentSize(cc.size(960, 640))
        imageView:setPosition(cc.p(layout:getContentSize().width/2, layout:getContentSize().height/2))

        if self.newGame then
            self.gCount = 1
        else
            if i == self.stagesCount then
                if self.newGate then
                   self.gCount = #self["stageOfgates"..i]+1
                else
                   self.gCount = #self["stageOfgates"..i]
                end
            else
                self.gCount = #self["stageOfgates"..i]
            end
        end
        for j=1,self.gCount do
            -- print(i)
            -- print(j)
            local gateButtonNode = GateButtonNode.create({ gateId = self["gatesIdTable"..i][j],
                                                    type   = self["gatesIconTable"..i][j]}):addTo(imageView)
            if  self.newGame then
                --gateButtonNode:setRank(string.format(0))
                gateButtonNode:setRank(0)
                gateButtonNode.newNode:setVisible(true)
                gateButtonNode.newNode:runAnimation("loop",true)
                gateButtonNode:showArrow()
                gateButtonNode:runAnimation("new",false)
                musicManager:play(girl.UiMusicId.GATE_NEW)
                -- print("newGame")
            else

                if j < self.gCount then
                    -- print(j)
                    -- print(self.gates[j].starRecord)
                    gateButtonNode:setRank(string.format(self["stageOfgates"..i][j].starRecord))
                    gateButtonNode.newNode:setVisible(false)
                    gateButtonNode:hideArrow()
                    -- print("比J小")
                else
                    if i == self.stagesCount and self.allPass == false then
                        gateButtonNode:setRank(0)
                        gateButtonNode.newNode:setVisible(true)
                        gateButtonNode:runAnimation("new",false)
                        musicManager:play(girl.UiMusicId.GATE_NEW)
                        gateButtonNode.newNode:runAnimation("loop",true)
                        gateButtonNode:showArrow()
                        -- print("最后一个")
                    else
                        gateButtonNode:setRank(string.format(self["stageOfgates"..i][j].starRecord))
                        gateButtonNode.newNode:setVisible(false)
                        gateButtonNode:hideArrow()
                        -- print("比J小")
                    end
                end
            end
            gateButtonNode:setPosition(self["gatePos"..i][j])
            -- print(self["gatePos"..i][j])
            gateButtonNode.gateButton:onClicked(function(event)
                   musicManager:play(girl.UiMusicId.WINDOW_OPEN)
                   -- print("gatePos",self["gatePos"..i][j].x)
                   -- print("gatePos",self["gatePos"..i][j].y)

                   -- print(gateButtonNode.gateId)
                   self.selectGateId = gateButtonNode.gateId

                    if gateButtonNode.type == 1 then
                        self:enterStroyGate()
                        self.pageView:removeAllPages()
                    else
                        if self["gatePos"..i][j].x <= 480 then
                            self.mapEnterRNode:setPosition(self.rightPosX,self.rightPosY)
                            self.mapEnterRNode:runAnimation("in")
                            self.mapEnterRNode:show()
                            self.bd_boss_2:setVisible(true)
                            self.Text_6:setVisible(true)
                            self.head_boss01_3:setVisible(true)
                            local gate = infoMgr:findInfo("gates","class_id",self.selectGateId)
                            self.goldText:setString(string.format("+%d",gate.gold))
                            self.expText:setString(string.format("+%d",gate.soulExp))
                            if gateButtonNode.type == 3 and gate.success_condition >30000  then
                                self:showBossInfo(gate.success_condition)
                            else
                                --self.bd_boss_2:setVisible(false)
                                self.head_boss01_3:setVisible(false)
                                self.Text_6:setVisible(false)
                                self.Text_6_1:setString(gate.gateLv)
                                self.Text_6_0:setString("普通")
                            end
                        else
                            -- dump(self.rightPos)
                            self.mapEnterRNode:setPosition(self.leftPosX,self.leftPosY)
                            self.mapEnterRNode:runAnimation("in")
                            self.mapEnterRNode:show()
                            self.bd_boss_2:setVisible(true)
                            self.Text_6:setVisible(true)
                            self.head_boss01_3:setVisible(true)
                            local gate = infoMgr:findInfo("gates","class_id",self.selectGateId)
                            self.goldText:setString(string.format("+%d",gate.gold))
                            self.expText:setString(string.format("+%d",gate.soulExp))
                            if gateButtonNode.type == 3 and gate.success_condition >30000  then
                                self:showBossInfo(gate.success_condition)
                            else
                                self.head_boss01_3:setVisible(false)
                                self.Text_6:setVisible(false)
                                self.Text_6_1:setString(gate.gateLv)
                                self.Text_6_0:setString("普通")
                            end
                        end
                        local gate = infoMgr:findInfo("gates","class_id",self.selectGateId)
                        --dump(gate)
                        self.gateInfoText:setString(gate.describe)
                        -- local str  = string.format(self.selectGateId)
                        -- local num1 = tonumber(string.sub(str,2,2))
                        -- local num2 = tonumber(string.sub(str,-2))
                        -- self.gateIdText:setString(string.format("%d-%d",num1,num2))
                        self.gateIdText:setString(gate.name)
                        self.openGateInfo = true
                    end
                   -- self.mapEnterRNode:runAnimation("in")
                   -- self.mapEnterRNode:show()
               end)
            -- print("循环结束")
        end
        layout:addChild(imageView)
        self.pageView:addPage(layout)
    end

    -- print("self.stagesCount",self.stagesCount-1)

    if self.newStage then
        self.pageView:scrollToPage(self.stagesCount-1)
        self.whichPart = self.stagesCount
    else


    end

    if self.savePartIndex then
        if self.newStage then
            self.pageView:scrollToPage(self.stagesCount-1)
            self.whichPart = self.stagesCount
        else
            self.pageView:scrollToPage(self.savePartIndex-1)
            self.whichPart = self.savePartIndex
        end
    else
        self.pageView:scrollToPage(self.stagesCount-1)
        self.whichPart = self.stagesCount
    end
    self:refreshArrowNode(self.whichPart)
end

function QuestPartPanel:showBossInfo(bossId)

    local bossInfo = infoMgr:findInfo("monsters","class_id",bossId)
    --local  id  = bossId
    -- dump(bossInfo)
    local str  = string.format(bossId)
    local num1 = tonumber(string.sub(str,1,3))
    self.head_boss01_3:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.BOSS_HEAD,num1))
    self.Text_6_1:setString(string.format("Lv.%d", bossInfo.level ))
    self.Text_6  :setString(bossInfo.name)
    self.Text_6_0:setString("BOSS")

end



function QuestPartPanel:refreshArrowNode()

    self.leftArrowNode:hide()
    self.rightArrowNode:hide()
    if self.whichPart == 1 then
        if self.stagesCount ~=1 then
            self.rightArrowNode:show()

        end
    elseif self.whichPart == self.stagesCount then
        self.leftArrowNode:show()
    else
        self.leftArrowNode:show()
        self.rightArrowNode:show()
    end
end


function QuestPartPanel:initShowRewardButton()

    self.showRewardButton:onClicked(function()
        -- print(girl.UiMusicId.BUTTON_CLICK)
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)

        if #self["stageOfgates"..self.whichPart] == 0 then
            panelFactory:createPanel(panelFactory.Panels.QuestPartGetPanel,onPanelClosed,
            {partInfo = self.stagesInfoTable[self.whichPart],starNum = 0,info = self["partRewardInfoTable"..self.whichPart]})
            :addTo(self)
        else
            -- dump(self.stages[1])
            -- print(self.stages[1].currentStar)
            panelFactory:createPanel(panelFactory.Panels.QuestPartGetPanel,onPanelClosed,
            {partInfo = self.stagesInfoTable[self.whichPart],starNum = self.stages[self.whichPart].currentStar,info = self["partRewardInfoTable"..self.whichPart]})
            :addTo(self)
        end
    end)
end


function QuestPartPanel:enterStroyGate()
    -- dump(self.gates)

    self.runingScript = true   --进入剧情模式，禁用左右两个箭头按钮

    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)

    local function onLoadClose()
        print("temp test!")

        local function onPanelClosed()
             self:reloadGates()
             self:reloadShowRewardNode()

        end


        local gate = infoMgr:findInfo("gates","class_id",self.selectGateId)
        local script = panelFactory:createPanel(panelFactory.Panels.StoryScriptPanel,onPanelClosed):addTo(self)
        self.savePartIndex = self.whichPart

        script:runScript(resMgr:getResPath(gate.story_id), function()
            -- print("runScript end")
            print("self.selectGateId :",self.selectGateId)
            -- dump(self.gates)
            local pb = pbBuilder:build({
            proto = "data/pb/interface/resultBattle.pb",
            desc  = "interface.resultBattle.Request",
            input =  { gate_id = self.selectGateId,
                       star = 0,
                       victory =true }
                     })
            ws:send( "RESULTBATTLE", pb, function(resultCode, des, data)
                  -- print("resultCode"..resultCode)
                  -- print("des"..des)
                  -- dump(data)
                  if resultCode >= 10000 then
                            print("close11111")
                            script:close()
                            self.runingScript = false
                            self:reloadShowRewardNode()
                            self:reloadGates()
                            print("close22222")
                            musicManager:play(girl.UiMusicId.CHAPTER_BGM)
                  elseif resultCode == 0 then
                           local rep = pbBuilder:decode({ proto = "data/pb/interface/resultBattle.pb",
                                       desc  = "interface.resultBattle.Response",
                                       input = data})

                            script:close()
                            self.runingScript = false
                            self:reloadShowRewardNode()
                            self:reloadGates()
                            print("close22222")
                            musicManager:play(girl.UiMusicId.CHAPTER_BGM)
                  end
             end)
        end, true, true, gate)
    end

    self.load = panelFactory:createPanel(panelFactory.Panels.LoadingPanel,onLoadClose)
                     :addTo(self,100)

    -- dump(playerMgr.goTeam)
    self.teams = {{id = 2, type = "HERO", order = 4}}

    if playerMgr.goTeams then
        for k,v in pairs(playerMgr.goTeams) do
            table.insert(self.teams, {id = v.id,type = "SOUL",order = v.order} )
        end
    end


    dump(self.teams)

    local pb = pbBuilder:build({
                   proto = "data/pb/interface/enterBattle.pb",
                   desc  = "interface.enterBattle.Request",
                   input = { gate_id    = self.selectGateId,
                             story_team = {type = "STORY", member = self.teams }}
                            })
    ws:send( "ENTERBATTLE", pb, function(resultCode, des, data)
          -- dump(resultCode)
          -- dump(des)
          -- print(resultCode)
          if resultCode == 0 or resultCode == 301 then
             self.load:close()
             -- dump(self.gates)
          end
    end)
end

function QuestPartPanel:changePart()

end



return QuestPartPanel

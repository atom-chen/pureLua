
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase     = import("..controls.PanelBase")
local AnimationNode = import("..controls.CocostudioNode")
local Hero 		      = import("..battle.Hero", CURRENT_MODULE_NAME)

-- singleton
local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory"):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local playerManager = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local battleManager = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
--
--
local ResultPanel = class("ResultPanel", PanelBase)

function ResultPanel.create( params )

  if params.result == true then
    return ResultPanel.new({csbName = "layers/result/Result_win.csb"  ,items = params.items,heroExpTable = params.heroExpTable,soulExpTable =  params.soulExpTable, id = params.id,result = true,lastPanel = params.lastPanel})

  else
    return ResultPanel.new({csbName = "layers/result/Result_loss.csb" , id = params.id,heroExpTable = params.heroExpTable,result = false,lastPanel = params.lastPanel})
  end

end

function ResultPanel:ctor(params)
  ResultPanel.super.ctor(self, params)
  self:enableNodeEvents()
  self.lastPanel = params.lastPanel
  self.result = params.result
  self.heroExpTable = params.heroExpTable
  self.id = params.id
  if params.result then
       
    self:mapUiElements({"playAgainButton","nextStepButton","soulNode1","soulNode2","soulNode3",
                               "boxNode1","boxNode2","boxNode3","heroLvText","heroExpText","ProjectNode_6","ProjectNode_6_0",
                               "heroLoadingBar","goldText","levelupNode","pickHeroNameText","Image_520","Image_6"})
    self.pickHeroNameText:setString("业")
          --先取一些要用到的UI控件
    for i=1,3 do
      self["boxButton"..i]     = AnimationNode.seek(self["boxNode"..i],"boxButton")
      self["itemInBoxNode"..i] = AnimationNode.seek(self["boxNode"..i],"itemInBoxNode")
      self["itemNameText"..i]  = AnimationNode.seek(self["boxNode"..i],"getItemNameText")
      self["itemCountText"..i] = AnimationNode.seek(self["boxNode"..i],"getItemCountText")
      self["itemIcon"..i]      = AnimationNode.seek(self["itemInBoxNode"..i],"itemIconSprite")
      print("get box")
    end

    for i=1,#playerManager.goTeams do
      print("get it")
      self["girlExpLoadingBar"..i]     = AnimationNode.seek(self["soulNode"..i],"girlExpLoadingBar")
      self["girlHeadSprite"..i]        = AnimationNode.seek(self["soulNode"..i],"head_girl01_11")
      self["girlNameText"..i]          = AnimationNode.seek(self["soulNode"..i],"girlNameText")
      self["girlHeadNode"..i]          = AnimationNode.seek(self["soulNode"..i],"girlHeadNode")
      self["girlLvText"..i]            = AnimationNode.seek(self["soulNode"..i],"girlLvText")
      self["girlExpText"..i]           = AnimationNode.seek(self["soulNode"..i],"girlExpText")
      self["girlPlusExpText"..i]       = AnimationNode.seek(self["soulNode"..i],"girlPlusExpText")
      self["girlPlusLoveText"..i]      = AnimationNode.seek(self["soulNode"..i],"girlPlusLoveText")
      self["girllvUpNode"..i]          = AnimationNode.seek(self["soulNode"..i],"lvUpNode")
      self["girlLoveLevelText"..i]     = AnimationNode.seek(self["soulNode"..i],"girlLoveLevelText")
      self["girlLoveExpLoadingBar"..i] = AnimationNode.seek(self["soulNode"..i],"girlLoveExpLoadingBar")
      self["girlLoveExpText"..i]       = AnimationNode.seek(self["soulNode"..i],"girlLoveExpText")
    end

    self.items        = params.items
    self.soulExpTable = params.soulExpTable
    dump(self.soulExpTable)

    self.id = params.id
    self.index = 0
    self.openBox =0
    self.getTable = {}

    for i=1,#playerManager.goTeams do
      --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_BANNER,playerManager.goTeams[i].id))
      self["girlHeadSprite"..i]:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_BANNER,playerManager.goTeams[i].id))
      local info  = infoManager:findInfo("souls","class_id",playerManager.goTeams[i].id)
      self["girlNameText"..i]:setString(info.name)
      self["girlHeadNode"..i]:runAnimation(string.format(playerManager.souls[playerManager.goTeams[i].id].star),false)

      self["girlLoveExpLoadingBar"..i]:setPercent(playerManager.souls[playerManager.goTeams[i].id].currentLove/60*100)
      self["girlLoveLevelText"..i]    :setString(playerManager.souls[playerManager.goTeams[i].id].loveLevel)
      self["girlLoveExpText"..i]      :setString(playerManager.souls[playerManager.goTeams[i].id].currentLove)
    end

  else
    self.index = 9
    self:mapUiElements({"playAgainButton","nextStepButton","rankNode","countFont","YesButton","NoButton",
                             "heroLvText","heroExpText","heroLoadingBar","goldText","levelupNode","Image_520","Image_6"})
  end
end

function ResultPanel:onEnter()

  ResultPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})
  self.Image_520:setScale9Enabled(true)
  self.Image_6:setScale9Enabled(true)


  if self.result then
     musicManager:play(girl.UiMusicId.BATTLE_WIN)
     --检查出战魂状态信息
    if #self.soulExpTable == 1 then
     self["soulNode"..1]:setVisible(true)
     --self["soulNode"..3]:setVisible(false)
    elseif #self.soulExpTable == 2 then
      self["soulNode"..1]:setVisible(true)
      self["soulNode"..2]:setVisible(true)

    elseif #self.soulExpTable == 3 then
      self["soulNode"..1]:setVisible(true)
      self["soulNode"..2]:setVisible(true)
      self["soulNode"..3]:setVisible(true)
    end
    --self:runAction(cc.DelayTime:create(0.1))
          
    self.ProjectNode_6_0:runAnimation("loop", true)
    self.ProjectNode_6:runAnimation("loop", true)
    --关闭战斗场景
    --self.lastPanel:close()
    print("=====================关闭战斗场景========================")
    self.heroGetExp = self.heroExpTable[1].getExp
    self.heroLevel = self.heroExpTable[1].lastLevel

    self.heroExpText:setString(string.format("+%d",self.heroExpTable[1].getExp))
    self.heroLvText:setString(string.format("Lv.%d",self.heroExpTable[1].lastLevel))
    self.goldText:setString(string.format("+%d",self.heroExpTable[1].getGold))
    local heroSoul = infoManager:findInfo("roles","class_id",self.heroExpTable[1].lastLevel)
    dump(heroSoul)
    self.heroUpLevelExp = heroSoul.upLevelExp
    print(self.heroUpLevelExp)
    self.heroLoadingBar:setPercent(self.heroExpTable[1].lastExp/self.heroUpLevelExp*100)
    if #self.soulExpTable >=1 then
        self.soulGetExp = self.soulExpTable[1].getExp
    end

    for i=1,#self.soulExpTable do

        self["soulLevel"..i] = self.soulExpTable[i].lastLevel
        self["soulExp"..i]   = self.soulExpTable[i].lastExp

        self["girlLvText"..i]:setString(string.format("%d/99",self.soulExpTable[i].lastLevel))
        self["girlExpText"..i]:setString(string.format("%d",self.soulExpTable[i].lastExp))
        self["girlPlusExpText"..i]:setString(string.format("+%d",self.soulExpTable[i].getExp))
        self["girlPlusLoveText"..i]:setString(string.format("+%d",0))

        local expSoul = infoManager:findInfo("expSouls","class_id",self.soulExpTable[i].lastLevel)
        dump(expSoul)
        self["soulLevelExp"..i]= expSoul.upLevelExp
        self["girlExpLoadingBar"..i]:setPercent(self.soulExpTable[i].lastExp/self["soulLevelExp"..i]*100)
    end

    self:runAnimation("in", false,function()
      self.lastPanel:close()
      if #playerManager.goTeams ==0 then
         print("没有元魂")
      else
         self.soulSchedule = self:scheduleEx(handler(self, self.soulUpdate))
      end
      self.heroSchedule = self:scheduleEx(handler(self, self.heroUpdate))
      musicManager:play(girl.UiMusicId.NUMBER_UP)
      musicManager:play(girl.UiMusicId.PROGRESS_UP)
    end)

    self.nextStepButton:onClicked(function()
        print("下一步")
        --dump(self.items)
        if self.index ==0 then
            self.nextStepButton:setTouchEnabled(false)
            self.nextStepButton:hide()
            self.playAgainButton:hide()
            self.index = 1+self.index
            self:winShowGetList()
            self:unscheduleEx(self.soulSchedule)
            self:unscheduleEx(self.heroSchedule)
        else
            self.nextStepButton:setTouchEnabled(false)
            self:runAnimation("2out", false,function ()
                self.nextStepButton:setTouchEnabled(true)
                self:getParent():reloadGates()
                self:getParent():reloadShowRewardNode()
                musicManager:play(girl.BGM.CHAPTER)
                self:close()
            end)
        end
    end)

    self.playAgainButton:onClicked(function()
        print("重来重来")
    end)

    self["boxButton"..1]:onClicked(function()
        musicManager:play(girl.UiMusicId.BOX_GET)
        print("box1")
        self.openBox = self.openBox+1
        if self.openBox == 3 then
            self.nextStepButton:show()
            self.nextStepButton:setTouchEnabled(true)
        end
        self["boxButton"..1]:setTouchEnabled(false)
        self.boxNode1:runAnimation("in",false,function()
            self.boxNode1:runAnimation("loop",true)
        end)
    end)

    self["boxButton"..2]:onClicked(function()
        
        musicManager:play(girl.UiMusicId.BOX_GET)
        self.openBox = self.openBox+1
        if self.openBox == 3 then
            self.nextStepButton:show()
            self.nextStepButton:setTouchEnabled(true)
        end
        self["boxButton"..2]:setTouchEnabled(false)
        self.boxNode2:runAnimation("in",false,function()
            self.boxNode2:runAnimation("loop",true)

        end)

    end)

    self["boxButton"..3]:onClicked(function()
      musicManager:play(girl.UiMusicId.BOX_GET)
      self.openBox = self.openBox+1
        if self.openBox == 3 then
          self.nextStepButton:show()
          self.nextStepButton:setTouchEnabled(true)
        end
      self["boxButton"..3]:setTouchEnabled(false)
      self.boxNode3:runAnimation("in",false,function()
          self.boxNode3:runAnimation("loop",true)
      end)
   end)

 else
    --测试处理待大表哥评分系统:失败Ｄ
    self.rankNode:runAnimation("0",false)
    self.heroExpText:setString(string.format("+%d",self.heroExpTable[1].getExp))
    self.heroLvText:setString(string.format("Lv.%d",self.heroExpTable[1].lastLevel))
    self.goldText:setString("+0")
    local heroSoul = infoManager:findInfo("roles","class_id",self.heroExpTable[1].lastLevel)
    self.heroUpLevelExp = heroSoul.upLevelExp
    self.heroLoadingBar:setPercent(self.heroExpTable[1].lastExp/self.heroUpLevelExp*100)
    self:runAnimation("in", false,function()
        self:scheduleEx(handler(self, self.loseUpdate),1)
        self.YesButton:onClicked(function()
            -- print("YES")
            battleManager.hero:addHp(battleManager.hero.topHp)
            battleManager.battleResultCode=-1
            battleManager.hero:changeStatus(Hero.statusType.STATUS_MOVE,1)
            self:unscheduleEx()
            self.lastPanel:resumeAll()
            self:close()
        end)
        self.NoButton:onClicked(function()
            -- print("No")
            self:lose2InEvent()
        end)
    end)
  end
end

function ResultPanel:winShowGetList()

    dump(self.items)

    --self.typeTable = {"props" = ,"souls","","","","","","props","materials","assemblages"}

    --self.info = infoManager:findInfo(self.typeTable[self.type],"class_id",self.id)

    for k,v in ipairs(self.items) do

      print(v.type,v.id,v.class_id,v.count)

            if v.type == "PROP" then
                local info = infoManager:findInfo("props","class_id",v.class_id)
                self:initGetItem(k,info,v.count)

            elseif v.type == "SOUL" then
                print("SOUL")

            elseif v.type == "GOLD" then
                self["itemInBoxNode"..k]:runAnimation("item", false)
                self["itemIcon"..k]:setTexture(resMgr:getIconPath(resMgr.IconType.GOLD))
                self["itemNameText"..k] :setString("金币")
                self["itemCountText"..k]:setString(v.count)

            elseif v.type == "DIMOND" then
                self["itemInBoxNode"..k]:runAnimation("item", false)
                self["itemIcon"..k]:setTexture(resMgr:getIconPath(resMgr.IconType.DIMOND))
                self["itemNameText"..k] :setString("钻石")
                self["itemCountText"..k]:setString(v.count)
            elseif v.type == "EQUIP" then
                print("EQUIP")

            elseif v.type == "HERO" then
                print("HERO")

            elseif v.type == "ASSEMBLAGE" then
                local info = infoManager:findInfo("assemblages","class_id",v.class_id)
                self:initGetItem(k,info,v.count)
            elseif v.type == "FRAGMENT" then
                print("FRAGMENT")

            elseif v.type == "MATERIAL" then
                local info = infoManager:findInfo("materials","class_id",v.class_id)
                self:initGetItem(k,info,v.count)

            elseif v.type == "DECORATION" then
                print("DECORATION")
            end

    end
    self:runAnimation("2in", false)
end


function ResultPanel:onExit()
    ResultPanel.super.onExit(self)
end



function ResultPanel:initGetItem(k,info,count)

  self["itemInBoxNode"..k]:runAnimation(info.quality,false)
  self["itemNameText"..k] :setString(info.name)
  self["itemCountText"..k]:setString(string.format("X%d",count))
  self["itemIcon"..k]     :setTexture(resMgr:getResPath(info.resId))
  --self["itemIcon"..k]     :setTextureByPlist(resMgr:getIconPath(resMgr.IconType.MATERIAL,info.class_id))
end

function ResultPanel:heroUpdate()

  local dp = 100/self.heroUpLevelExp

  self.heroLoadingBar:setPercent(self.heroLoadingBar:getPercent()+dp)

  if self.heroLoadingBar:getPercent() == 100 then
    self.levelupNode:runAnimation("in",false)

    self.heroLevel =  self.heroLevel +1

    local newUpExp = infoManager:findInfo("expSouls","class_id",self.heroLevel)
    self.heroUpLevelExp = newUpExp.upLevelExp

    self.heroLvText:setString(string.format("Lv.%d",self.heroLevel))

    self.heroLoadingBar:setPercent(0)


  end

  self.heroGetExp = self.heroGetExp-1

  if self.heroGetExp <= 0 then
    self:unscheduleEx(self.heroSchedule)
  end

end


function ResultPanel:soulUpdate()

  for i=1,#self.soulExpTable do

    local dp = 100/self["soulLevelExp"..i]
    self["girlExpLoadingBar"..i]:setPercent(self["girlExpLoadingBar"..i]:getPercent()+dp)

    self["soulExp"..i] = self["soulExp"..i]+1
    self["girlExpText"..i]:setString(string.format("%d",self["soulExp"..i]))

    if self["girlExpLoadingBar"..i]:getPercent() == 100 then

       self["girllvUpNode"..i]:runAnimation("in",false)

       self["soulLevel"..i] =  self["soulLevel"..i] +1

       local newUpExp = infoManager:findInfo("expSouls","class_id",self["soulLevel"..i])
       self["soulLevelExp"..i]  = newUpExp.upLevelExp

       self["girlLvText"..i]:setString(string.format("%d/99",self["soulLevel"..i]))

       self["girlExpLoadingBar"..i]:setPercent(0)
       self["soulExp"..i] = 0
    end

  end

  self.soulGetExp = self.soulGetExp-1
  if self.soulGetExp  <= 0 then
      self:unscheduleEx(self.soulSchedule)
  end

end

function ResultPanel:loseUpdate()

  self.countFont:setString(string.format(self.index))
  self.index = self.index -1

  if self.index < 0 then
      self.index =0
      self:lose2InEvent()
  end
end

--关闭当前结算界面
function ResultPanel:outClose()
  self.lastPanel:close()
  self:getParent():reloadGates()
  self:getParent():reloadShowRewardNode()
  musicManager:play(girl.BGM.CHAPTER)
  self:close()
  musicManager:play(girl.UiMusicId.CHAPTER_BGM)
  MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
end

--失败2in事件处理
function ResultPanel:lose2InEvent()
  self:unscheduleEx()
  self:runAnimation("2in", false,function()
      self.nextStepButton:onClicked(function()
          print("下一步")
          self:outClose()
      end)
      self.playAgainButton:onClicked(function()
          print("重来重来")
      end)
  end)
end

return ResultPanel


local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase             = import("..controls.PanelBase")
local AnimationNode         = import("..controls.CocostudioNode")

-- singleton
local panelFactory          = import("..controls.PanelFactory"):getInstance()
local playerManager         = import("...data.PlayerDataManager"):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local battleManager         = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
local resMgr                = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
--
--
--
local UIBattlePanel = class("UIBattlePanel", PanelBase)

function UIBattlePanel.create( params )
    return UIBattlePanel.new({ csbName = "layers/battle/Battle.csb", cb = params.cb})
end

local ANIMATIONS = {
    ENTER   = "in",
    EXIT    = "out"
}

UIBattlePanel.Events = table.enumTable
{
    -- 返回按键
    "ON_BUTTON_BACK",
    "ON_SKILL_SOUL",
}

function UIBattlePanel:ctor(params)
    UIBattlePanel.super.ctor(self, params)
    self:enableNodeEvents()
    self.cb = params.cb
 
    self:mapUiElements({"souls", "soul_1", "soul_2", "soul_3","hp_text","sp_text","hp_bar","sp_bar","box_text","comboNode","comboNumText","bossHpNode","hp_bar0","hp_bar1",
      "bossHeadIcon","lv_text","xxNumNode","bossName","masterNode","addHpNumText","addHpEff"})
end

function UIBattlePanel:callfunc(params)
    if self.cb then
        self.cb(params)
    end
end

function UIBattlePanel:onEnter()
    -- 进入动画
    UIBattlePanel.super.onEnter(self)
    
    self.comboNode:setVisible(true)

    -- print("UIBattlePanel:onEnter()")
    --返回响应
    self.num ={}

    -- dump(playerManager.goTeams)

    for k,v in girl.pairsByKeys(playerManager.goTeams) do
       table.insert(self.num,k)

    end

    self:runAnimation("in")
    self.curBarHp = 0
    -- 头像技能响应
    local touchTag = 1
    for i=1,table.nums(playerManager.goTeams) do
        local v = playerManager.goTeams[i]
        local node = "soul_"..self.num[i]
        self[node]:runAnimation(string.format(playerManager.souls[v.id].star),false)
        self[node]:setTag(self.num[i])
        
        local aoyiNode  = "aoyi"..self.num[i]
        self[aoyiNode]  = AnimationNode.seek(self[node],"aoyiNode")
        self[aoyiNode]:runAnimation("loop", true)
        self[aoyiNode]:hide()
        self[aoyiNode]:retain()

        self["aoyiBar"..self.num[i]]  = AnimationNode.seek(self[node],"aoyiLoadingBar")
        self["skillBar"..self.num[i]] = AnimationNode.seek(self[node],"skillLoadingBar")
        self["aoyiMax"..self.num[i]]  = AnimationNode.seek(self[node],"aoyiMax")
        self["skillMax"..self.num[i]] = AnimationNode.seek(self[node],"skillMax")
        self["aoyiOnceEff"..self.num[i]] = AnimationNode.seek(self[node],"aoyiOnceEff")
        self["aoyiParticle"..self.num[i]] = AnimationNode.seek(self[node],"aoyiParticle")
        self["masterNode"..self.num[i]]= AnimationNode.seek(self[node],"masterNode")
        self["masterNode"..self.num[i]]:runAnimation(string.format(playerManager.souls[v.id].info.type..playerManager.souls[v.id].info.color))
          
        local recTouchPos = cc.p(0,0)
        girl.addTouchEventListener(self[node], {
            swallow = true,
            onBegan = function(touch, event)
        
                  recTouchPos = touch:getLocation()
                  touchTag = 1
                  local rt = self[node]:getCascadeBoundingBox()
                  if self:onTouchCollide(rt,recTouchPos) then
                      return true
                  end
            end,

            onMoved = function( touch, event )
                  local touchedLoc = touch:getLocation()
                  if math.abs(touchedLoc.y -recTouchPos.y)>100 then
                    touchTag =2
                    self:callfunc({ event = self.Events.ON_SKILL_SOUL, tag = event:getCurrentTarget():getTag(),touchType = "onMoved"})
                  end
            end,
            
            onEnded = function(touch, event )
                   if touchTag == 1 then
                      self:callfunc({ event = self.Events.ON_SKILL_SOUL, tag = event:getCurrentTarget():getTag(),touchType = "onTap"})
                   end
            end
      })
     end

    local function onPanelClosed(reason)

         if reason == "resume" then
            print("resume resume!")
            self:getParent():resumeAll()
        
         -- elseif reason == "back" then
         --   print("back onClosed!")
         --    --self.ui:close()
         --    --self:close()
         --    self:callfunc({ event = self.Events.ON_BUTTON_BACK})
         end
     end
    --------------------战斗界面右上角暂停按钮----------------------------------
    self:onButtonClicked("buttonBack", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        local pause = panelFactory:createPanel(panelFactory.Panels.PausePanel,onPanelClosed):addTo(self)
        pause:setLocalZOrder(200)
        self:getParent():pauseAll()
        pause:resumeAll()
    end)

end


function UIBattlePanel:onExit()
    UIBattlePanel.super.onExit(self)
    for i=1,table.nums(playerManager.goTeams) do
        local aoyiNode  = "aoyi"..self.num[i]
        self[aoyiNode]:release()
    end
    printInfo("UIBattlePanel:onExit()")
end
function UIBattlePanel:onTouchCollide(rect,pt)

    return cc.rectContainsPoint(rect, pt) 

end

function UIBattlePanel:reload(  )

end


function UIBattlePanel:setSoulsNumber(num)
    -- self.souls:runAnimation(num)
    if num == 0 then
        self.soul_1:setVisible(false)
        self.soul_2:setVisible(false)
        self.soul_3:setVisible(false)
    elseif num == 1 then
        self.soul_2:setVisible(false)
        self.soul_3:setVisible(false)
    elseif num == 2 then
        self.soul_3:setVisible(false)
    elseif num == 3 then
        self.soul_1:setVisible(true)
        self.soul_2:setVisible(true)
        self.soul_3:setVisible(true)
    end
end

function UIBattlePanel:setSoulsIcon(params)

    for i=1,table.nums(params) do
        local node = "soul_"..self.num[i]
        local icon = AnimationNode.seek(self[node],"head_girl01_11")
        if self["sprite11"..i] == nil then
            -- dump(resMgr:getIconPath(resMgr.IconType.SOUL_FACE,params[i].pb.class_id,"00"))
            icon:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_FACE,params[i].pb.class_id,"00"))
            self["sprite11"..i] = cc.Sprite:create() -- cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_FACE,params[i].pb.class_id,11))
            self["sprite11"..i]:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_FACE,params[i].pb.class_id,11))
            icon:addChild(self["sprite11"..i])
            self["sprite11"..i]:setAnchorPoint(cc.p(0,0))
        else
            if params[i].isCanExskill then
                self["sprite11"..i]:setVisible(true)
            else
                self["sprite11"..i]:setVisible(false)
            end
        end
    end
end

function UIBattlePanel:setBarInfo(params)

    self.hp_text:setString(params.hpText)
    self.sp_text:setString(params.spText)
    self.hp_bar:setPercent(params.hpPercent)
    self.sp_bar:setPercent(params.spPercent)
    self:updateIconInfo(params)
    self:setSoulsIcon(params.souls)

end

-----加血物效----
function UIBattlePanel:setAddHpEff(params)

    self.addHpNumText:setString(params.addNumText)
    self.addHpEff:show()
    self.addHpEff:runAnimation("plus",false,function()
        self.addHpEff:hide()
    end)

end

---Boss血条信息---
function UIBattlePanel:setBossHpBar(params)
    if battleManager.isAoyiAction then
        return
    end
    self.bossHpNode:setVisible(true)
    if params.status == "NORMAL" then
        self.bossHpNode:runAnimation("in",false)
        self.lv_text:setString("Lv."..params.obj.level)
        self.bossName:setString(params.obj.name)
        self.bossHeadIcon:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.BOSS_HEAD, math.floor(params.obj.info.class_id/100)))

    elseif params.status == "DMG" then
        self.bossHpNode:runAnimation("gehit",false)
    elseif params.status == "DEAD" then
        self.bossHpNode:runAnimation("dead",false,function()
            self.bossHpNode:setVisible(false)
          end)
    end
    local hpLineNum = params.obj.bloodBarNum or 1
    if params.obj then
        local hpMax = math.floor(params.obj.info.hp/hpLineNum)
        local hp = params.obj.curHp%hpMax
        local num = math.floor(params.obj.curHp/hpMax) --目前还有几个血条
        printInfo("~~~~~~~~~ hpNum: %d ,  curHp:%d , curBarHp:%d",num,params.obj.curHp,self.curBarHp)
        --每个血条平均血值&血最大值
        if self.curBarHp <= hp then
            if num == hpLineNum then
                self.xxNumNode:runAnimation("x"..hpLineNum,false)
            else
                self.xxNumNode:runAnimation("x"..num+1,false)
            end
            
            if self.hp_bar0.isEnd then
                self.hp_bar0.isEnd = false
                self.hp_bar1.isEnd = true
                if num>0 then
                    self.hp_bar1:loadTexture(resMgr:getIconPath(resMgr.IconType.BOSS_HP,num),1)
                end
            else
                self.hp_bar0.isEnd = true
                self.hp_bar1.isEnd = false
                if num>0 then
                    self.hp_bar0:loadTexture(resMgr:getIconPath(resMgr.IconType.BOSS_HP,num),1)
                end
            end
        end
        self.curBarHp = hp
        if self.hp_bar0.isEnd then
            printInfo("-----self.hp_bar0.isEnd----")
            if num > 0 then
                printInfo("aaaaaaa")
                self.hp_bar0:setPercent(100)
                self.hp_bar0:setLocalZOrder(100)
                self.hp_bar1:setPercent(hp*100.0 / hpMax)
                self.hp_bar1:setLocalZOrder(101)
            else
                printInfo("bbbbbbbb")
                self.hp_bar1:setPercent(hp*100.0 / hpMax)
                self.hp_bar1:setLocalZOrder(101)
                self.hp_bar0:setVisible(false)
            end
        elseif self.hp_bar1.isEnd then
            printInfo("-----self.hp_bar1.isEnd----")
            if num > 0 then
                printInfo("ccccccccc")
                self.hp_bar1:setPercent(100)
                self.hp_bar1:setLocalZOrder(100)
                self.hp_bar0:setPercent(hp*100.0 / hpMax)
                self.hp_bar0:setLocalZOrder(101)
            else
                printInfo("ddddddddd")
                self.hp_bar0:setPercent(hp*100.0 / hpMax)
                self.hp_bar0:setLocalZOrder(101)
                self.hp_bar1:setVisible(false)
            end
        end
    end
end

--动态处理奥义图标状态
function UIBattlePanel:updateIconInfo(params)

    for i,vv in ipairs(playerManager.goTeams) do
        local aoyiNode  = "aoyi"..self.num[i]
        local aoyiMax   = "aoyiMax"..self.num[i]
        local skillMax  = "skillMax"..self.num[i]
        local aoyiOnceEff = "aoyiOnceEff"..self.num[i]
        local aoyiParticle = "aoyiParticle"..self.num[i]
        for _,v in ipairs(params.souls) do
          if v.info.class_id == vv.id  then
            if self[aoyiNode] then
              --奥义点
              if v.exSkillPoint >= v.exSkillPointMax then
                  self[aoyiNode]:show()
                  self[aoyiMax]:show()
                  self[aoyiParticle]:show()
                  if(false == self[aoyiMax].isFullBar) then
                      v.isCanExskill = true
                      self[aoyiMax].isFullBar = true
                      musicManager:play(girl.UiMusicId.EXSKILL_READY)
                      self[aoyiOnceEff]:show()
                      self[aoyiOnceEff]:runAnimation("in",false,function() 
                          self[aoyiOnceEff]:hide()
                        end)
                      self[aoyiMax]:runAnimation("in",false,function()
                          self[aoyiMax]:runAnimation("loop",true)
                        end)
                  end
              else
                  self[aoyiNode]:hide()
                  self[aoyiMax]:hide()
                  self[aoyiParticle]:hide()
                  self[aoyiMax].isFullBar = false
                  v.isCanExskill = false
              end
              --技能点
              if v.skillColdTime >= v.skillColdTimeMax then
                  self[skillMax]:show()
                  if(false == self[skillMax].isFullBar) then
                      self[skillMax].isFullBar = true
                      self[skillMax]:runAnimation("in",false,function()
                          self[skillMax]:runAnimation("loop",true)
                        end)
                  end
              else
                  self[skillMax]:hide()
                  self[skillMax].isFullBar = false
              end
              --loadingbar
              self["aoyiBar"..self.num[i]]:setPercent(100*v.exSkillPoint/v.exSkillPointMax)
              self["skillBar"..self.num[i]]:setPercent(100*v.skillColdTime/v.skillColdTimeMax)
            end
          end
        end
    end
end

return UIBattlePanel

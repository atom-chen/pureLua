local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GirlsCardNode = import("..fragment.GirlsCardNode",CURRENT_MODULE_NAME)

-- singleton
local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()


local SoulsAdvancePanel = class("SoulsAdvancePanel", PanelBase)

function SoulsAdvancePanel.create(params)
  return SoulsAdvancePanel.new({ csbName = "layers/girls/GirlsAdvance.csb",id = params.id,edu = params.edu})
end


function SoulsAdvancePanel:ctor(params)
  SoulsAdvancePanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"mapBackButton","nameText","typeNode","lvText","atkBefore","speedBefore","perBefore","valueBefore","armorBefore",
                      "advanceBtn","atkAfter","speedAfter","perAfter","valueAfter","armorAfter","skillCDText","skillText","star1",
                      "star2","star3","star4","star5","star6","girlCardLSprite","countLoadingBar","countText","headNode","cardNode",
                      "head_girl_sprite","jinjieNode","fragmentPic","headTypeNode","detailButton"})
  self.id  = params.id
  self.edu = params.edu
  print(self.id)

  dump(playerMgr.souls[self.id])



end


function SoulsAdvancePanel:onEnter()

  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  SoulsAdvancePanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  if self.edu then
     MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  end

  self:reload()

  self:runAnimation("in",false,function()

  end)

  -- self.rockGirlSelfNode:runAnimation("rock",true)
  --全身图片
  --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))
  self.girlCardLSprite:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))
  --local sprite1 = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_HEAD,self.id))
  self.head_girl_sprite:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_HEAD,self.id))
  --元魂头像右下角碎片图标
  self.fragmentPic:show()
  self.headTypeNode:hide()

  --type
  self.typeNode:runAnimation(string.format(playerMgr.souls[self.id].info.type..playerMgr.souls[self.id].info.color))

  --名字
  self.nameText:setString(playerMgr.souls[self.id].info.name)

  --等级
  self.lvText:setString(string.format("Lv.%d/100",playerMgr.souls[self.id].level))

  --碎片
  -- print(playerMgr.souls[self.id].count)
  -- print(self.breachInfo1.up_needCount)
  -- self.countLoadingBar:setPercent(playerMgr.souls[self.id].count/self.breachInfo1.up_needCount *100)

  -- --星级
  -- for i=1,playerMgr.souls[self.id].star do
  --     self["star"..i]:setVisible(true)
  -- end

  -- --星阶颜色
  -- self.headNode:runAnimation(string.format(playerMgr.souls[self.id].star))
  -- self.cardNode:runAnimation(string.format(playerMgr.souls[self.id].star))

  -- self.atkBefore  :setString(self.atkValue1)
  -- self.speedBefore:setString(self.breachInfo1.atkSpeed)
  -- self.perBefore  :setString(self.breachInfo1.baoJi)
  -- self.valueBefore:setString(self.breachInfo1.baoJiAtk)
  -- self.armorBefore:setString(self.breachInfo1.poJia)

  -- self.atkAfter   :setString(self.atkValue2)
  -- self.speedAfter :setString(self.breachInfo2.atkSpeed)
  -- self.perAfter   :setString(self.breachInfo2.baoJi)
  -- self.valueAfter :setString(self.breachInfo2.baoJiAtk)
  -- self.armorAfter :setString(self.breachInfo2.poJia)


  self.advanceBtn:onClicked(function()
       print("111111111")
       musicManager:play(girl.UiMusicId.BUTTON_CLICK)
       self.advanceBtn:setTouchEnabled(false)
       local function onPanelClosed(reason)
           MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
       end


       local pb = pbBuilder:build({
        proto = "data/pb/interface/breachSoul.pb",
        desc  = "interface.breachSoul.Request",
        input = { soul_id = self.id }
        })

        ws:send( "SOULADVANCE", pb, function(resultCode, des)
             print("SOULADVANCE:", resultCode,des)
             if resultCode == 0 then
                MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
                panelFactory:createPanel(panelFactory.Panels.SoulsAdvanceResultPanel,onPanelClosed,{id = self.id}):addTo(self)
                musicManager:play(girl.UiMusicId.SOUL_ADVANCED)
             end
             if resultCode then
                self.advanceBtn:setTouchEnabled(true)
             end
        end)

  end)


  self.mapBackButton:onClicked(function()
    musicManager:play(girl.UiMusicId.BUTTON_CLICK)
     if self.edu then
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
        self:close()
     else
     self:runAnimation("out", false, function()
     end)
     self:getParent():runAnimation("in",false,function()

          MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.SOUL_RELOAD,
                               {func = 2,id = self.id})
          self:close()
     end)
     --MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)

  end

  end)

  -- local pb = pbBuilder:build({
  --       proto = "data/pb/interface/breachSoul.pb",
  --       desc  = "interface.breachSoul.Request",
  --       input = { soul_id = self.id }
  --       })

  --     ws:send( "SOULADVANCE", pb, function(resultCode, des)
  --          print("SOULADVANCE:", resultCode,des)

  --          if resultCode == 0 then
  --             dump(playerMgr.souls[self.id])
  --          end
  --    end)
  local function onPanelClosed(reason)

      MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  end

  self.detailButton:onClicked(function()
    musicManager:play(girl.UiMusicId.BUTTON_CLICK)
      panelFactory:createPanel(panelFactory.Panels.SoulsDetailPanel,onPanelClosed,{id = self.id}):addTo(self)
      MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
  end)




end

function SoulsAdvancePanel:reload()

  if playerMgr.soulFragments[self.id] ==nil then
        self.fragmentCount = 0
  else
        self.fragmentCount = playerMgr.soulFragments[self.id].count
  end

  -- if playerMgr.souls[self.id].star == 6 then
  --     self.jinjieNode:runAnimation("no")
  --    self.advanceBtn:setTouchEnabled(false)
  --    --return
  -- end

  for i=1,playerMgr.souls[self.id].star do
      self["star"..i]:setVisible(true)
  end

  local breachId1 = tonumber(self.id.."0"..playerMgr.souls[self.id].star)
  if playerMgr.souls[self.id].star == 6 then
    self.breachId2 = tonumber(self.id.."0"..playerMgr.souls[self.id].star)
  else
    self.breachId2 = tonumber(self.id.."0"..playerMgr.souls[self.id].star+1)
  end


  self.breachInfo1 = infoManager:findInfo("breachs","class_id",breachId1)
  self.breachInfo2 = infoManager:findInfo("breachs","class_id",self.breachId2)

  dump(self.breachInfo1)
  self.skillInfo = infoManager:findInfo("skills","class_id",self.breachInfo1.skill1_id)
  dump(self.skillInfo)

  print("攻击成长值:",self.breachInfo1.atk)

  self.atkValue1 = self.breachInfo1.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack

  self.atkValue2 = self.breachInfo2.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack



  self.headNode:runAnimation("1")
  self.cardNode:runAnimation(string.format(playerMgr.souls[self.id].star))


  --奥义名，奥义描述
  -- self.exSkillInfo = infoManager:findInfo("exSkills","class_id",self.id)
  -- self.exSkillNameText:setString(self.exSkillInfo.exName)
  -- self.exSkillText:setString(self.exSkillInfo.exInstruction)



  self.skillSpeed1 = infoManager:findInfo("skills","class_id",self.breachInfo1.skill0_id)
  self.coldTime1   = self.skillSpeed1.coldTime

  self.skillSpeed2 = infoManager:findInfo("skills","class_id",self.breachInfo2.skill0_id)
  self.coldTime2   = self.skillSpeed2.coldTime



  --强化加成攻击计算
  dump(playerMgr.souls[self.id].intensifys)

  local info = playerMgr.souls[self.id].intensifys

  local upgradeInfo    = {"atkValue",  "speedValue",  "perValue",  "dmgValue",  "armorValue",  "masterValue"}

  self.intensifysTable = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}

  self.baseValueTable1  = {self.atkValue1,self.breachInfo1.atkSpeed,self.breachInfo1.baoJi,self.breachInfo1.baoJiAtk,self.breachInfo1.poJia,self.breachInfo1.skill_master}
  self.baseValueTable2  = {self.atkValue2,self.breachInfo2.atkSpeed,self.breachInfo2.baoJi,self.breachInfo2.baoJiAtk,self.breachInfo2.poJia,self.breachInfo2.skill_master}


  for i=1,6 do
    if self.intensifysTable[i] % 100 ~=0 then
       -- print("%d不等于0",i)
       local valueInfo = nil
       if self.intensifysTable[i] - self.id*100 >= 60 then
          valueInfo = infoManager:findInfo("intensifys","class_id",self.id*100+60)
       else
          valueInfo = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i])
       end
       --local valueInfo        = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i])

       self.baseValueTable1[i] = self.baseValueTable1[i] + valueInfo[upgradeInfo[i]]
       self.baseValueTable2[i] = self.baseValueTable2[i] + valueInfo[upgradeInfo[i]]

    end
  end

  --计算配件的属性加成



    for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
      -- print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self["assemblage"..v.order] = infoManager:findInfo("assemblages","class_id",v.class_id)
    end


    self.curUpgradedAtk      = self.baseValueTable1[1]
    self.curUpgradedSpeed    = self.baseValueTable1[2]
    self.curUpgradedBaoji    = self.baseValueTable1[3]
    self.curUpgradedBaojiAtk = self.baseValueTable1[4]
    self.curUpgradedPojia    = self.baseValueTable1[5]
    self.curUpgradedSkill    = self.baseValueTable1[6]

    self.curUpgradedValueTable = {self.curUpgradedAtk,      self.curUpgradedSpeed, self.curUpgradedBaoji,
                                  self.curUpgradedBaojiAtk, self.curUpgradedPojia, self.curUpgradedSkill}

    self.tarUpgradedAtk      = self.baseValueTable2[1]
    self.tarUpgradedSpeed    = self.baseValueTable2[2]
    self.tarUpgradedBaoji    = self.baseValueTable2[3]
    self.tarUpgradedBaojiAtk = self.baseValueTable2[4]
    self.tarUpgradedPojia    = self.baseValueTable2[5]
    self.tarUpgradedSkill    = self.baseValueTable2[6]

    self.tarUpgradedValueTable = {self.tarUpgradedAtk,      self.tarUpgradedSpeed, self.tarUpgradedBaoji,
                                  self.tarUpgradedBaojiAtk, self.tarUpgradedPojia, self.tarUpgradedSkill}


   self.vSpeed1 = (self.coldTime1 - self.baseValueTable1[2])/1000
   self.vSpeed2 = (self.coldTime2 - self.baseValueTable2[2])/1000

   for i=1,4 do
    --   print("第%d次循环",i)
      if self["assemblage"..i] then
         if self["assemblage"..i].attributeType <= 6 then

           if self["assemblage"..i].attributeType == 2 then
              self.vSpeed1 = self.vSpeed1 * (1-self["assemblage"..i].attributeValue/10000)
              self.vSpeed2 = self.vSpeed2 * (1-self["assemblage"..i].attributeValue/10000)
           else
              self.curUpgradedValueTable[self["assemblage"..i].attributeType] = self.curUpgradedValueTable[self["assemblage"..i].attributeType] * (1+self["assemblage"..i].attributeValue/10000)
              self.tarUpgradedValueTable[self["assemblage"..i].attributeType] = self.tarUpgradedValueTable[self["assemblage"..i].attributeType] * (1+self["assemblage"..i].attributeValue/10000)
           end

        elseif self["assemblage"..i].attributeType ==8 then
             print("攻速")
             self.vSpeed1 = self.vSpeed1 * (1-self["assemblage"..i].attributeValue/10000)
             self.vSpeed2 = self.vSpeed2 * (1-self["assemblage"..i].attributeValue/10000)

        elseif self["assemblage"..i].attributeType ==9 then
             print("暴率暴伤")
            self.curUpgradedValueTable[3] = self.curUpgradedValueTable[3] * (1+self["assemblage"..i].attributeValue/10000)
            self.curUpgradedValueTable[4] = self.curUpgradedValueTable[4] * (1+self["assemblage"..i].attributeValue/10000)

            self.tarUpgradedValueTable[3] = self.tarUpgradedValueTable[3] * (1+self["assemblage"..i].attributeValue/10000)
            self.tarUpgradedValueTable[4] = self.tarUpgradedValueTable[4] * (1+self["assemblage"..i].attributeValue/10000)

        elseif self["assemblage"..i].attributeType ==10 then
             self.curUpgradedValueTable[1] = self.curUpgradedValueTable[1] * (1+self["assemblage"..i].attributeValue/10000)
             self.curUpgradedValueTable[5] = self.curUpgradedValueTable[5] * (1+self["assemblage"..i].attributeValue/10000)

             self.tarUpgradedValueTable[1] = self.tarUpgradedValueTable[1] * (1+self["assemblage"..i].attributeValue/10000)
             self.tarUpgradedValueTable[5] = self.tarUpgradedValueTable[5] * (1+self["assemblage"..i].attributeValue/10000)


        end
     else
        -- print("没有第%d个配件",i)
     end



  end


  self.valueTable1       = {math.floor(self.curUpgradedValueTable[1]),
                           string.format("%.2f秒",self.vSpeed1),
                           string.format("%.2f%%",self.curUpgradedValueTable[3]/100),
                           string.format("%.2f%%",self.curUpgradedValueTable[4]/100),
                           string.format("%.2f%%",self.curUpgradedValueTable[5]/100),
                           string.format("%.2f%%",self.curUpgradedValueTable[6]/100)}

  self.valueTable2      = {math.floor(self.tarUpgradedValueTable[1]),
                           string.format("%.2f秒",self.vSpeed2),
                           string.format("%.2f%%",self.tarUpgradedValueTable[3]/100),
                           string.format("%.2f%%",self.tarUpgradedValueTable[4]/100),
                           string.format("%.2f%%",self.tarUpgradedValueTable[5]/100),
                           string.format("%.2f%%",self.tarUpgradedValueTable[6]/100)}



  if playerMgr.souls[self.id].info.skill_type == 3 then
      self.skillCDText:setString(string.format("减少%.2f%%技能冷却时间",self.tarUpgradedValueTable[6]/100))
  elseif playerMgr.souls[self.id].info.skill_type == 1 then
      self.skillCDText:setString(string.format("增加%.2f%%技能威力",self.tarUpgradedValueTable[6]/100))
  end

  self.skillInfo = infoManager:findInfo("skills","class_id",self.breachInfo2.skill1_id)
  self.skillText:setString(self.skillInfo.skillInstruction)



  self.atkBefore  :setString(self.valueTable1[1])
  self.speedBefore:setString(self.valueTable1[2])
  self.perBefore  :setString(self.valueTable1[3])
  self.valueBefore:setString(self.valueTable1[4])
  self.armorBefore:setString(self.valueTable1[5])

  self.atkAfter   :setString(self.valueTable2[1])
  self.speedAfter :setString(self.valueTable2[2])
  self.perAfter   :setString(self.valueTable2[3])
  self.valueAfter :setString(self.valueTable2[4])
  self.armorAfter :setString(self.valueTable2[5])

  self.countText:setString(string.format("%d/%d",self.fragmentCount,self.breachInfo1.up_needCount))

  self.countLoadingBar:setPercent(self.fragmentCount/self.breachInfo1.up_needCount *100)

  if self.fragmentCount < self.breachInfo1.up_needCount or playerMgr.souls[self.id].star == 6 then
     self.jinjieNode:runAnimation("no")
     self.advanceBtn:setTouchEnabled(false)
  else
     self.jinjieNode:runAnimation("yes")
     self.advanceBtn:setTouchEnabled(true)
  end

end









return SoulsAdvancePanel

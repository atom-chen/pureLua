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


local SoulsDetailPanel = class("SoulsDetailPanel", PanelBase)

function SoulsDetailPanel.create(params)
  return SoulsDetailPanel.new({ csbName = "layers/girls/GirlsDetail.csb",id = params.id})
end


function SoulsDetailPanel:ctor(params)
  SoulsDetailPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"mapBackButton","girl_01_1","documentButton","rockGirlSelfNode",
                     "detailTypeNode","detailNameText","detailLvText","allNameText","skillNameText","expLoadingBar",
                     "skillText","exSkillNameText","exSkillText","slotNode1","slotNode2","slotNode3","slotNode4",
                     "starNode1","starNode2","starNode3","starNode4","starNode5","starNode6","expLoadingBar","starBgSprite",
                     "posNode","loopNode","heroPos","atkText","perText","armorText","speedText","dmgText","detailExpText",
                     "skillValueText","intimacyText","fatigueText","noSlotNode1","noSlotNode2","noSlotNode3","noSlotNode4",
                     "bgstarNode1","bgstarNode2","bgstarNode3","bgstarNode4","bgstarNode5","bgstarNode6"})
  self.id = params.id
  print(self.id)

  local breachId = tonumber(self.id.."0"..playerMgr.souls[self.id].star)
  self.breachInfo = infoManager:findInfo("breachs","class_id",breachId)
  dump(self.breachInfo)

  self.skillSpeed = infoManager:findInfo("skills","class_id",self.breachInfo.skill0_id)
  self.coldTime   = self.skillSpeed.coldTime

   for i=1,4 do
       self["iconSprite"..i]= AnimationNode.seek(self["slotNode"..i],"itemIconSprite")
   end

   --初始化配件id表，0代表没有穿，-1代表没有解锁
   self.idTable = {0,-1,-1,-1}


end


function SoulsDetailPanel:onEnter()

  -- local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  -- bg:setLocalZOrder(-100)
  SoulsDetailPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  --local bgSprite = cc.Sprite:create(string.format("studio/textures/ui/draw/bg_cj_%d.png",playerMgr.souls[self.id].star))

  --self.starBgSprite:setTextureByPlist(string.format("studio/textures/ui/draw/bg_cj_%d.png",playerMgr.souls[self.id].star))


  self.starBgSprite:runAnimation(string.format(playerMgr.souls[self.id].star), false)
  self:runAnimation("l_in",false,function()

  end)

  self.rockGirlSelfNode:runAnimation("rock",true)
  --全身图片
  --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.id))
  self.girl_01_1:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.id))

  --type
  print(playerMgr.souls[self.id].color)
  self.detailTypeNode:runAnimation(string.format(playerMgr.souls[self.id].info.type..playerMgr.souls[self.id].info.color))

  --名字
  self.detailNameText:setString(playerMgr.souls[self.id].info.name)

  --等级
  self.detailLvText:setString(string.format("%d/99",playerMgr.souls[self.id].level))

  --经验
  local expSoul = infoManager:findInfo("expSouls","class_id",playerMgr.souls[self.id].level)
  dump(expSoul)
  local upMaxExp= expSoul.upLevelExp
  self.expLoadingBar:setPercent(playerMgr.souls[self.id].exp/upMaxExp*100)
  self.detailExpText:setString(string.format("%d/%d",playerMgr.souls[self.id].exp,upMaxExp))

  --亲密度，疲劳度
  self.intimacyText:setString(string.format("Lv.%d",playerMgr.souls[self.id].loveLevel))
  self.fatigueText :setString(string.format("%d/%d",playerMgr.souls[self.id].currentEnergy,playerMgr.souls[self.id].info.maxEnergy))

  --全名
  self.allNameText:setString(playerMgr.souls[self.id].info.full_name)

  --技能名，技能描述
  -- local breachId = tonumber(self.id.."0"..playerMgr.souls[self.id].star)

  -- self.breachInfo = infoManager:findInfo("breachs","class_id",breachId)

  dump(self.breachInfo)
  self.skillInfo = infoManager:findInfo("skills","class_id",self.breachInfo.skill1_id)
  self.skillNameText:setString(self.skillInfo.name)
  self.skillText:setString(self.skillInfo.skillInstruction)


  --奥义名，奥义描述
  self.exSkillInfo = infoManager:findInfo("exSkills","class_id",self.id)
  self.exSkillNameText:setString(self.exSkillInfo.exName)
  self.exSkillText:setString(self.exSkillInfo.exInstruction)

  --星级
  for i=1,playerMgr.souls[self.id].star do
      self["starNode"..i]:setVisible(true)
  end

   for i=playerMgr.souls[self.id].star+1,6 do
      self["bgstarNode"..i]:setVisible(true)
  end

  --配件处理

  dump(playerMgr.souls[self.id])
  --dump(playerMgr.souls[self.id].assemblages)

  for i=1,4 do
    self["slotNode"..i]:setVisible(false)

  end

  for i=2,4 do
    self["noSlotNode"..i]:runAnimation("lock", false)
  end

  for i=1,4 do
       self["iconSprite"..i]= AnimationNode.seek(self["slotNode"..i],"itemIconSprite")
   end

  self:loadSlotInfo()




  self.mapBackButton:onClicked(function()
         musicManager:play(girl.UiMusicId.BUTTON_CLICK)
         MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
         self:close()

  end)




  self.atkValue         = self.breachInfo.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack
  print(self.atkValue)
  --未强化的六个属性值
  --local vSpeed = (self.coldTime - self.breachInfo.atkSpeed)/1000

  --强化加成攻击计算
  dump(playerMgr.souls[self.id].intensifys)

  local info = playerMgr.souls[self.id].intensifys

  local upgradeInfo    = {"atkValue",  "speedValue",  "perValue",  "dmgValue",  "armorValue",  "masterValue"}

  self.intensifysTable = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}

  self.baseValueTable  = {self.atkValue,self.breachInfo.atkSpeed,self.breachInfo.baoJi,self.breachInfo.baoJiAtk,self.breachInfo.poJia,self.breachInfo.skill_master}



  for i=1,6 do
    if self.intensifysTable[i] % 100 ~=0 then
       local valueInfo        = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i])
       print(self.baseValueTable[i])
       print(valueInfo[upgradeInfo[i]])
       self.baseValueTable[i] = self.baseValueTable[i] + valueInfo[upgradeInfo[i]]
       print(self.baseValueTable[i])
    end
  end



  --计算配件的属性加成

  self.upgradedAtk      = self.baseValueTable[1]
  self.upgradedSpeed    = self.baseValueTable[2]
  self.upgradedBaoji    = self.baseValueTable[3]
  self.upgradedBaojiAtk = self.baseValueTable[4]
  self.upgradedPojia    = self.baseValueTable[5]
  self.upgradedSkill    = self.baseValueTable[6]

  self.upgradedValueTable = {self.upgradedAtk,self.upgradedSpeed,self.upgradedBaoji,self.upgradedBaojiAtk,self.upgradedPojia,self.upgradedSkill}


  self.vSpeed = (self.coldTime - self.upgradedValueTable[2])/1000

  for i=1,4 do
    --  print("第%d次循环",i)
     if self["assemblage"..i] then
         if self["assemblage"..i].attributeType <= 6 then

           if self["assemblage"..i].attributeType == 2 then
              self.vSpeed = self.vSpeed * (1-self["assemblage"..i].attributeValue/10000)
           else
              self.upgradedValueTable[self["assemblage"..i].attributeType] = self.upgradedValueTable[self["assemblage"..i].attributeType] * (1+self["assemblage"..i].attributeValue/10000)
           end

        elseif self["assemblage"..i].attributeType ==8 then
             print("攻速")
             self.vSpeed = self.vSpeed * (1-self["assemblage"..i].attributeValue/10000)

        elseif self["assemblage"..i].attributeType ==9 then
             print("暴率暴伤")
            self.upgradedValueTable[3] = self.upgradedValueTable[3] * (1+self["assemblage"..i].attributeValue/10000)
            self.upgradedValueTable[4] = self.upgradedValueTable[4] * (1+self["assemblage"..i].attributeValue/10000)

        elseif self["assemblage"..i].attributeType ==10 then
             self.upgradedValueTable[1] = self.upgradedValueTable[1] * (1+self["assemblage"..i].attributeValue/10000)
             self.upgradedValueTable[5] = self.upgradedValueTable[5] * (1+self["assemblage"..i].attributeValue/10000)


        end
     else
        -- print("没有第%d个配件",i)
     end



  end




  self.valueTable       = {math.floor(self.upgradedValueTable[1]),
                           string.format("%.2f秒",self.vSpeed),
                           string.format("%.2f%%",self.upgradedValueTable[3]/100),
                           string.format("%.2f%%",self.upgradedValueTable[4]/100),
                           string.format("%.2f%%",self.upgradedValueTable[5]/100),
                           string.format("%.2f%%",self.upgradedValueTable[6]/100)}


  self.atkText  :setString(self.valueTable[1])
  self.speedText:setString(self.valueTable[2])
  self.perText  :setString(self.valueTable[3])
  self.dmgText  :setString(self.valueTable[4])
  self.armorText:setString(self.valueTable[5])
  self.skillValueText:setString(self.valueTable[6])

 --计算配件的属性加成

  -- self.typeTbale = {"攻击力","普攻CD","技能CD","暴击率","暴击伤害","破甲","韧性",{"普攻CD","技能CD"},{"暴击率","暴击伤害"},{"攻击力","破甲"}}





  -- for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
  --     print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
  --     self.idTable[v.order] = v.id
  --     self:showAssemblage(v.order,v.class_id)
  --     print("self.idTable[v.order]",self.idTable[v.order])
  --  end


   -- for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
   --    print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
   --    self["assemblage"..v.order] = infoManager:findInfo("assemblages","class_id",v.class_id)
   -- end





end


function SoulsDetailPanel:loadSlotInfo()

   if 3<=playerMgr.souls[self.id].star and  playerMgr.souls[self.id].star < 5 then
      self.noSlotNode2:runAnimation("open",false)

      self.idTable = {0,0,-1,-1}
   end
   if playerMgr.souls[self.id].star == 5 then
      self.noSlotNode2:runAnimation("open",false)
      self.noSlotNode3:runAnimation("open",false)
      --self.unlockStarText3:setString("元神5星级解锁")
      self.idTable = {0,0,0,-1}
   end
   if playerMgr.souls[self.id].star == 6  then
      self.noSlotNode2:runAnimation("open",false)
      self.noSlotNode3:runAnimation("open",false)
      self.noSlotNode4:runAnimation("open",false)

      self.idTable = {0,0,0,0}
   end

   for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
      print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self.idTable[v.order] = v.id
      self:showAssemblage(v.order,v.class_id)
      print("self.idTable[v.order]",self.idTable[v.order])
   end



end

function SoulsDetailPanel:showAssemblage(order,class_id)

    self["slotNode"..order]:setVisible(true)

    self["assemblage"..order] = infoManager:findInfo("assemblages","class_id",class_id)

    --dump(assemblage)

    self["slotNode"..order]:runAnimation(self["assemblage"..order].quality)


    local info = resMgr:findInfo(self["assemblage"..order].resId)
    dump(info)

    --local pic = cc.Sprite:create(info.name)
    self["iconSprite"..order]:setTexture(info.name)



end





return SoulsDetailPanel

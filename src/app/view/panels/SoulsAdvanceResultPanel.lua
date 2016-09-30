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
local resMgr     = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()


local SoulsAdvanceResultPanel = class("SoulsAdvanceResultPanel", PanelBase)

function SoulsAdvanceResultPanel.create(params)
  return SoulsAdvanceResultPanel.new({ csbName = "layers/girls/GirlsAdvanceResult.csb",id = params.id})
end


function SoulsAdvanceResultPanel:ctor(params)
  SoulsAdvanceResultPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self.index = 0
  self.change1 = true
  self.change2 = true

  self:mapUiElements({"atkNode","speedNode","perNode","valueNode","armorNode","touchNode","starNode1","starNode2","bg_cj_1_1","bg_cj_2_2","Button_1",
                      "starNode3","starNode4","starNode5","starNode6","girl_01_1","bg_cj_1_1","bg_cj_2_2","skillText","textCD","bgColorNode"})
  self.id = params.id
  print(self.id)

  --dump(playerMgr.souls[self.id])

  self.fatherTable = {self.atkNode,self.speedNode,self.perNode,self.valueNode,self.armorNode}
  self.textTable   = {"攻击","攻速","暴率","暴伤","破甲"}

  for i=1,5 do
      local protocolText = AnimationNode.seek(self.fatherTable[i],"Text_1")
      protocolText:setString(self.textTable[i])
      self["textBefore"..i]   = AnimationNode.seek(self.fatherTable[i],"Text_1_0")
      self["textAfter"..i]   = AnimationNode.seek(self.fatherTable[i],"Text_1_0_0")
  end

  -- local bgColor11 = AnimationNode.seek(self.bg_cj_1_1,"bgImagePanel1")
  -- local bgColor12 = AnimationNode.seek(self.bg_cj_1_1,"bgImagePanel2")

  -- bgColor11:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG1,playerMgr.souls[self.id].star-1))
  -- bgColor12:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG2,playerMgr.souls[self.id].star-1))

  -- local bgColor21 = AnimationNode.seek(self.bg_cj_2_2,"bgImagePanel1")
  -- local bgColor22 = AnimationNode.seek(self.bg_cj_2_2,"bgImagePanel2")

  -- bgColor21:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG1,playerMgr.souls[self.id].star))
  -- bgColor22:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG2,playerMgr.souls[self.id].star))


  --local sprite1 = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG,playerMgr.souls[self.id].star-1))
  --self.bg_cj_1_1:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG1,playerMgr.souls[self.id].star-1))
  self.bg_cj_1_1:runAnimation(string.format(playerMgr.souls[self.id].star-1),false)

  --local sprite2 = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG,playerMgr.souls[self.id].star))
  --self.bg_cj_2_2:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ADVANCEDBG2,playerMgr.souls[self.id].star))
  self.bg_cj_2_2:runAnimation(string.format(playerMgr.souls[self.id].star),false)

end


function SoulsAdvanceResultPanel:onEnter()

  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  SoulsAdvanceResultPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  print(playerMgr.souls[self.id].star)

  local breachId1 = tonumber(self.id.."0"..playerMgr.souls[self.id].star-1)
  local breachId2 = tonumber(self.id.."0"..playerMgr.souls[self.id].star)

  self.breachInfo1 = infoManager:findInfo("breachs","class_id",breachId1)
  self.breachInfo2 = infoManager:findInfo("breachs","class_id",breachId2)

  --dump(self.breachInfo1)
  self.skillInfo = infoManager:findInfo("skills","class_id",self.breachInfo1.skill1_id)
  --dump(self.skillInfo)





  self.skillText:setString(self.skillInfo.skillInstruction)


  print("攻击成长值:",self.breachInfo1.atk)

  self.atkValue1 = self.breachInfo1.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack

  self.atkValue2 = self.breachInfo2.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack




  self.skillSpeed1 = infoManager:findInfo("skills","class_id",self.breachInfo1.skill0_id)
  self.coldTime1   = self.skillSpeed1.coldTime

  self.skillSpeed2 = infoManager:findInfo("skills","class_id",self.breachInfo2.skill0_id)
  self.coldTime2   = self.skillSpeed2.coldTime

 --强化加成攻击计算
  dump(playerMgr.souls[self.id].intensifys)

  local info = playerMgr.souls[self.id].intensifys

  local upgradeInfo     = {"atkValue",  "speedValue",  "perValue",  "dmgValue",  "armorValue",  "masterValue"}

  self.intensifysTable  = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}

  self.baseValueTable1  = {self.atkValue1,self.breachInfo1.atkSpeed,self.breachInfo1.baoJi,self.breachInfo1.baoJiAtk,self.breachInfo1.poJia,self.breachInfo1.skill_master}
  self.baseValueTable2  = {self.atkValue2,self.breachInfo2.atkSpeed,self.breachInfo2.baoJi,self.breachInfo2.baoJiAtk,self.breachInfo2.poJia,self.breachInfo2.skill_master}


  for i=1,6 do
     if self.intensifysTable[i] % 100 ~=0 then
         -- print("%d不等于0",i)
         local valueInfo        = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i])
         self.baseValueTable1[i] = self.baseValueTable1[i] + valueInfo[upgradeInfo[i]]
         self.baseValueTable2[i] = self.baseValueTable2[i] + valueInfo[upgradeInfo[i]]
     end
  end




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


  self.valueTable1      = {math.floor(self.curUpgradedValueTable[1]),
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


  self["textBefore"..1]:setString(self.valueTable1[1])
  self["textBefore"..2]:setString(self.valueTable1[2])
  self["textBefore"..3]:setString(self.valueTable1[3])
  self["textBefore"..4]:setString(self.valueTable1[4])
  self["textBefore"..5]:setString(self.valueTable1[5])

  self["textAfter"..1]:setString(self.valueTable2[1])
  self["textAfter"..2]:setString(self.valueTable2[2])
  self["textAfter"..3]:setString(self.valueTable2[3])
  self["textAfter"..4]:setString(self.valueTable2[4])
  self["textAfter"..5]:setString(self.valueTable2[5])




  if playerMgr.souls[self.id].info.skill_type == 3 then
      self.textCD:setString(string.format("减少%.2f%%技能冷却时间",self.tarUpgradedValueTable[6]/100))
  elseif playerMgr.souls[self.id].info.skill_type == 1 then
      self.textCD:setString(string.format("增加%.2f%%技能威力",self.tarUpgradedValueTable[6]/100))
  end

  self.Button_1:onClicked(function()

   print("self.index:",self.index)
                               if self.index == 0 then
                                  print("还没播完还没播完")
                                  return
                               end

                               if self.index == 1 and self.change1 == true then
                                  self.change1 = false

                                      self:runAnimation("3in",false,function()
                                        self.index = 2


                                  end)
                               else
                                  if self.index == 2 and self.change2 == true then
                                     self.change2 = false
                                     self:runAnimation("3out",false,function()
                                          self:getParent():reload()
                                          self:close()
                                     end)
                                  else
                                     return
                                  end
                               end

 end)

  --全身图片
  --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.id))
  self.girl_01_1:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.id))

  -- girl.addTouchEventListener(self, {
  --                              swallow = true,
  --                              onBegan = function()
  --                              print("self.index:",self.index)
  --                              if self.index == 0 then
  --                                 print("还没播完还没播完")
  --                                 return
  --                              end

  --                              if self.index == 1 and self.change1 == true then
  --                                 self.change1 = false

  --                                     self:runAnimation("3in",false,function()
  --                                       self.index = 2


  --                                 end)
  --                              else
  --                                 if self.index == 2 and self.change2 == true then
  --                                    self.change2 = false
  --                                    self:runAnimation("3out",false,function()
  --                                         self:getParent():reload()
  --                                         self:close()
  --                                    end)
  --                                 else
  --                                    return
  --                                 end
  --                              end
  --                               return true


  --                             end})
  self:runAnimation("1in",false,function()
      self:runAnimation("1out",false,function()
          self.index = 1
      end)
      self.touchNode:runAnimation("loop", true)
  end)


  for i= playerMgr.souls[self.id].star + 1, 6 do
      self["starNode"..i]:setVisible(false)
  end












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




end

return SoulsAdvanceResultPanel

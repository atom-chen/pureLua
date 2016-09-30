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

local SoulsUpgradePanel = class("SoulsUpgradePanel", PanelBase)

function SoulsUpgradePanel.create(params)
  return SoulsUpgradePanel.new({ csbName = "layers/girls/GirlsUpgrade.csb",id = params.id,edu = params.edu })
end


function SoulsUpgradePanel:ctor(params)
  SoulsUpgradePanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"mapBackButton","nameText","typeNode","lvText","girlCardLSprite","toShopButton","washButton","girlCardLSprite",
                      "cardNode","propertyNode1","propertyNode2","propertyNode3","propertyNode4","propertyNode5","propertyNode6","goldText",
                       "timesText","detailButton","washAnimationNode"})
  self.id  = params.id
  self.edu = params.edu
  print(self.id)

  self.propertyTable = {"攻击","攻速","暴率","暴伤","破甲","技巧"}

  for i=1,6 do
     self["curText"..i]            = AnimationNode.seek(self["propertyNode"..i],"curText")
     self["tarText"..i]            = AnimationNode.seek(self["propertyNode"..i],"tarText")
     self["propertyText"..i]       = AnimationNode.seek(self["propertyNode"..i],"propertyText")
     self["propertyText"..i]  :setString(self.propertyTable[i])
     self["materialText"..i]       = AnimationNode.seek(self["propertyNode"..i],"materialText")
     self["materialNode"..i]       = AnimationNode.seek(self["propertyNode"..i],"materialNode")
     self["upgradeButton"..i]      = AnimationNode.seek(self["propertyNode"..i],"upgradeButton")
     self["moneyText"..i]          = AnimationNode.seek(self["propertyNode"..i],"moneyText")
     self["materialCountText"..i]  = AnimationNode.seek(self["propertyNode"..i],"materialText")
     self["singleTimeText"..i]     = AnimationNode.seek(self["propertyNode"..i],"singleTimeText")
     self["animationNode"..i]     = AnimationNode.seek(self["propertyNode"..i],"animationNode")

  end

  for i=1,6 do
    self["materialNode"..i]:runAnimation(string.format(i))
  end

  local breachId = tonumber(self.id.."0"..playerMgr.souls[self.id].star)
  self.breachInfo = infoManager:findInfo("breachs","class_id",breachId)
  dump(self.breachInfo)

  self.skillSpeed = infoManager:findInfo("skills","class_id",self.breachInfo.skill0_id)
  self.coldTime   = self.skillSpeed.coldTime

end


function SoulsUpgradePanel:onEnter()

  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  SoulsUpgradePanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  if self.edu then
     MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  end

  self:reload()

  self.info = infoManager:findInfo("intensifys","class_id",101)
  dump(self.info)

  self.info1 = infoManager:findInfo("materials","class_id",1)
  dump(self.info1)

  self:runAnimation("in",false,function()

  end)

  -- self.rockGirlSelfNode:runAnimation("rock",true)
  --全身图片
  --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))
  self.girlCardLSprite:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))

  self.cardNode:runAnimation(string.format(playerMgr.souls[self.id].star))
  --type
  self.typeNode:runAnimation(string.format(playerMgr.souls[self.id].info.type..playerMgr.souls[self.id].info.color))

  --名字
  self.nameText:setString(playerMgr.souls[self.id].info.name)

  --等级
  self.lvText:setString(string.format("Lv.%d/100",playerMgr.souls[self.id].level))


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
                               {func = 1,id = self.id})
          self:close()
     end)


    end





  end)

  self.washButton:onClicked(function()

     local function onPanelClosed(reason)
      if reason =="yes" then
         local pb = pbBuilder:build({
         proto = "data/pb/interface/washSoul.pb",
         desc  = "interface.washSoul.Request",
         input = { soul_id = self.id}})

         ws:send( "SOULWASH", pb, function(resultCode, des)
           print("SOULWASH:", resultCode,des)
           if resultCode == 0 then
              self.washAnimationNode:runAnimation("click", false)
              musicManager:play(girl.UiMusicId.SOUL_WASH)
              dump(playerMgr.souls[self.id].intensifys)
              print(playerMgr.souls[self.id].intensifys.atkId)
              for i=1,6 do
                self["singleTimeText"..i]:setString(string.format("Lv.%d",0))
              end

              self:reload()
           end
        end)
      end
    end

    if playerMgr.status.gold < girl.Price.SOULWASH then
       local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,
                       {message = girl.Message.SOULWASH2,
                       code = girl.MessageCode.CHANGE_SOULWASH})
                       :addTo(self,100)

    else
       if self.times == 0 then
          local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,
                          {message = girl.Message.SOULWASH3,
                          code = girl.MessageCode.CHANGE_SOULWASH})
                          :addTo(self,100)

       else
          local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,onPanelClosed,
                          {message = girl.Message.SOULWASH1,
                          code = girl.MessageCode.CHANGE_SOULWASH})
                          :addTo(self,100)
       end
    end

  end)


  self.toShopButton:onClicked(function()
    musicManager:play(girl.UiMusicId.BUTTON_CLICK)
      print("toShopButton")
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
  self.typeTable = {"ATK","ATK_SPEED","BAOJI","BAOJIATK","POJIA","SKILL"}

  for i=1,6 do
    self["upgradeButton"..i]:setTag(i)
    self["upgradeButton"..i]:onClicked(function(event)
      print(event.target:getTag())
      musicManager:play(girl.UiMusicId.SOUL_UPGRADE)
      local pb = pbBuilder:build({
        proto = "data/pb/interface/intensifySoul.pb",
        desc  = "interface.intensifySoul.Request",
        input = { soul_id = self.id,type = self.typeTable[event.target:getTag()]}
        })
      ws:send( "SOULINTENSIFY", pb, function(resultCode, des)
           print("SOULINTENSIFY:", resultCode,des)

           if resultCode == 0 then

              musicManager:play(girl.UiMusicId.HEROEQUIP_UPGRADE)
              self["animationNode"..event.target:getTag()] :runAnimation("up", false)
              dump(playerMgr.souls[self.id].intensifys)
              print(playerMgr.souls[self.id].intensifys.atkId)
              self:reload()
           end
           print("end")
       end)
    end)
  end

  local function onPanelClosed(reason)

      MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  end

  self.detailButton:onClicked(function()
      musicManager:play(girl.UiMusicId.BUTTON_CLICK)
      panelFactory:createPanel(panelFactory.Panels.SoulsDetailPanel,onPanelClosed,{id = self.id}):addTo(self)
      MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
  end)




end

function SoulsUpgradePanel:reload()

  dump(playerMgr.materials)

  --显示玩家的钱
  self["goldText"]:setString(playerMgr.status.gold)

  --玩家未计算强化的攻击力
  self.atkValue         = self.breachInfo.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack

  print("self.atkValueself.atkValueself.atkValueself.atkValue",self.atkValue)
  --未强化的六个属性值
  self.valueTable       = {self.atkValue,self.breachInfo.atkSpeed,self.breachInfo.baoJi,self.breachInfo.baoJiAtk,
                           self.breachInfo.poJia,self.breachInfo.skill_master}

  --作为表取值的K,六个属性强化的值,所需要的材料id,以及消耗材料数量consume
  --依次为                   攻击力，         攻速，        暴击率，       暴击伤害，     破甲，           精通
  local upgradeInfo     = {"atkValue",  "speedValue",  "perValue",  "dmgValue",  "armorValue",  "masterValue"}
  local materialIdTable = {"atkNeed" ,  "speedNeed" ,  "perNeed" ,  "dmgNeed",   "armorNeed",   "masterNeed"}
  local consumeTable    = {"atkConsume","speedConsume","perConsume","dmgConsume","armorConsume","masterConsume"}

  dump(playerMgr.souls[self.id].intensifys)

  local info = playerMgr.souls[self.id].intensifys

  self.intensifysTable = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}

  dump(self.intensifysTable)

  self.times = 0

   for k,v in ipairs(self.intensifysTable) do
       local mod  = v % 100
       self.times = self.times + mod
   end

   self.timesText:setString(string.format("%d/%d",self.times,self.breachInfo.qianghua_limit))

   for i=1,6 do
          self["propertyNode"..i]:runAnimation("yes")
   end


   for i=1,6 do
      if self.intensifysTable[i]%100 ~=0 then
         self["singleTimeText"..i]:setString(string.format("Lv.%d",self.intensifysTable[i]%100))
         local upgradeValue1 = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i])

         local upgradeValue2 = nil

          if self.intensifysTable[i] - self.id*100 >= 60 then
             print(i)
             print(self.intensifysTable[i])
             upgradeValue2   = infoManager:findInfo("intensifys","class_id",self.id*100+60)
          else
             upgradeValue2   = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i]+1)
          end
        

         print(upgradeValue1[upgradeInfo[i]])
         print(upgradeValue2[upgradeInfo[i]])

         self["curShowValue"..i] = self.valueTable[i]+ upgradeValue1[upgradeInfo[i]]
         self["tarShowValue"..i] = self.valueTable[i]+ upgradeValue2[upgradeInfo[i]]

      else
          local upgradeValue = nil
          if self.intensifysTable[i] - self.id*100 >= 60 then
             upgradeValue   = infoManager:findInfo("intensifys","class_id",self.id*100+60)
          else
             upgradeValue   = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i]+1)
          end

         self["curShowValue"..i] = self.valueTable[i]
         self["tarShowValue"..i] = self.valueTable[i]+ upgradeValue[upgradeInfo[i]]

      end
          local upgradeValue = nil
          if self.intensifysTable[i] - self.id*100 >= 60 then
             upgradeValue   = infoManager:findInfo("intensifys","class_id",self.id*100+60)
          else
             upgradeValue   = infoManager:findInfo("intensifys","class_id",self.intensifysTable[i]+1)
          end
         self["materialText"..i]:setString(string.format("%d/%d",0,upgradeValue[consumeTable[i]]))
         self["propertyNode"..i]:runAnimation("no")
         for k,v in pairs(playerMgr.materials) do
            -- print("v.class_id",v.class_id)
            if v.class_id == upgradeValue[materialIdTable[i]] then
                self["materialText"..i]:setString(string.format("%d/%d",v.count,upgradeValue[consumeTable[i]]))
                print("有材料，显示材料拥有数量")
                if v.count >= upgradeValue[consumeTable[i]] then
                   self["propertyNode"..i]:runAnimation("yes")
                end
              break
            end
         end
         --dump(playerMgr.status)
         self["moneyText"..i]:setString(string.format("%d",upgradeValue.price))

         if playerMgr.status.gold < upgradeValue.price then
            print("金币不够")
            self["propertyNode"..i]:runAnimation("no")
         end

         --判断的玩家的材料和金币够不够强化条件
    end

   if self.times == self.breachInfo.qianghua_limit then
       print("已经达到最大强化次数")
       for i=1,6 do
          self["propertyNode"..i]:runAnimation("no")
       end

   end


    for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
      print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self["assemblage"..v.order] = infoManager:findInfo("assemblages","class_id",v.class_id)
    end


    self.curUpgradedAtk      = self["curShowValue"..1]
    self.curUpgradedSpeed    = self["curShowValue"..2]
    self.curUpgradedBaoji    = self["curShowValue"..3]
    self.curUpgradedBaojiAtk = self["curShowValue"..4]
    self.curUpgradedPojia    = self["curShowValue"..5]
    self.curUpgradedSkill    = self["curShowValue"..6]

    self.curUpgradedValueTable = {self.curUpgradedAtk,      self.curUpgradedSpeed, self.curUpgradedBaoji,
                                  self.curUpgradedBaojiAtk, self.curUpgradedPojia, self.curUpgradedSkill}

    self.tarUpgradedAtk      = self["tarShowValue"..1]
    self.tarUpgradedSpeed    = self["tarShowValue"..2]
    self.tarUpgradedBaoji    = self["tarShowValue"..3]
    self.tarUpgradedBaojiAtk = self["tarShowValue"..4]
    self.tarUpgradedPojia    = self["tarShowValue"..5]
    self.tarUpgradedSkill    = self["tarShowValue"..6]

    self.tarUpgradedValueTable = {self.tarUpgradedAtk,      self.tarUpgradedSpeed, self.tarUpgradedBaoji,
                                  self.tarUpgradedBaojiAtk, self.tarUpgradedPojia, self.tarUpgradedSkill}


    self.curSpeed = (self.coldTime - self.curUpgradedValueTable[2])/1000
    self.tarSpeed = (self.coldTime - self.tarUpgradedValueTable[2])/1000


    for i=1,4 do
    --   print("第%d次循环",i)
      if self["assemblage"..i] then
         if self["assemblage"..i].attributeType <= 6 then

          print("type",self["assemblage"..i].attributeType)

           if self["assemblage"..i].attributeType == 2 then
              self.curSpeed = self.curSpeed * (1-self["assemblage"..i].attributeValue/10000)
              self.tarSpeed = self.tarSpeed * (1-self["assemblage"..i].attributeValue/10000)
           else
              print(i)
              print(self.curUpgradedValueTable[self["assemblage"..i].attributeType])
              print(self.tarUpgradedValueTable[self["assemblage"..i].attributeType])
              self.curUpgradedValueTable[self["assemblage"..i].attributeType] = self.curUpgradedValueTable[self["assemblage"..i].attributeType] * (1+self["assemblage"..i].attributeValue/10000)
              self.tarUpgradedValueTable[self["assemblage"..i].attributeType] = self.tarUpgradedValueTable[self["assemblage"..i].attributeType] * (1+self["assemblage"..i].attributeValue/10000)
              print(self.curUpgradedValueTable[self["assemblage"..i].attributeType])
              print(self.tarUpgradedValueTable[self["assemblage"..i].attributeType])
           end

        elseif self["assemblage"..i].attributeType ==8 then
             print("攻速")
             self.curSpeed = self.curSpeed * (1-self["assemblage"..i].attributeValue/10000)
             self.tarSpeed = self.tarSpeed * (1-self["assemblage"..i].attributeValue/10000)

        elseif self["assemblage"..i].attributeType ==9 then
             print("暴率暴伤")
            self.curUpgradedValueTable[3] = self.curUpgradedValueTable[3] * (1+self["assemblage"..i].attributeValue/10000)
            self.curUpgradedValueTable[4] = self.curUpgradedValueTable[4] * (1+self["assemblage"..i].attributeValue/10000)

            self.tarUpgradedValueTable[3] = self.tarUpgradedValueTable[3] * (1+self["assemblage"..i].attributeValue/10000)
            self.tarUpgradedValueTable[4] = self.tarUpgradedValueTable[4] * (1+self["assemblage"..i].attributeValue/10000)

        elseif self["assemblage"..i].attributeType ==10 then
              print("=10")
              print(self.curUpgradedValueTable[1])
              print(self.tarUpgradedValueTable[1])
             self.curUpgradedValueTable[1] = self.curUpgradedValueTable[1] * (1+self["assemblage"..i].attributeValue/10000)
             self.curUpgradedValueTable[5] = self.curUpgradedValueTable[5] * (1+self["assemblage"..i].attributeValue/10000)

             self.tarUpgradedValueTable[1] = self.tarUpgradedValueTable[1] * (1+self["assemblage"..i].attributeValue/10000)
             self.tarUpgradedValueTable[5] = self.tarUpgradedValueTable[5] * (1+self["assemblage"..i].attributeValue/10000)

                print(self.curUpgradedValueTable[1])
              print(self.tarUpgradedValueTable[1])


        end
     else
        -- print("没有第%d个配件",i)
     end



  end



  self.curValueTable     = {math.floor(self.curUpgradedValueTable[1]),
                            string.format("%.2f秒",self.curSpeed),
                            string.format("%.2f%%",self.curUpgradedValueTable[3]/100),
                            string.format("%.2f%%",self.curUpgradedValueTable[4]/100),
                            string.format("%.2f%%",self.curUpgradedValueTable[5]/100),
                            string.format("%.2f%%",self.curUpgradedValueTable[6]/100)}

  self.tarValueTable      = {math.floor(self.tarUpgradedValueTable[1]),
                            string.format("%.2f秒",self.tarSpeed),
                            string.format("%.2f%%",self.tarUpgradedValueTable[3]/100),
                            string.format("%.2f%%",self.tarUpgradedValueTable[4]/100),
                            string.format("%.2f%%",self.tarUpgradedValueTable[5]/100),
                            string.format("%.2f%%",self.tarUpgradedValueTable[6]/100)}

  for i=1,6 do
     self["curText"..i]:setString(self.curValueTable[i])
     self["tarText"..i]:setString(self.tarValueTable[i])
  end
   -- self["curText"..i]:setString(self["curShowValue"..i])
   -- self["tarText"..i]:setString(self["tarShowValue"..i])


end


return SoulsUpgradePanel

local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode       = import("..controls.CocostudioNode")
local Hero                = import("..battle.Hero", CURRENT_MODULE_NAME)
-- singleton
local playerMgr           = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoManager         = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr              = import("...data.information.ResManager" , CURRENT_MODULE_NAME):getInstance()
local ws                  = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder           = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
--
local HeroBanner = class("HeroBanner", AnimationNode)

function HeroBanner.create(param)

    dump(param)

    print("create IconNode")

    return HeroBanner.new({csbName = "nodes/hero/heroBanner.csb",id = param.id})
end



function HeroBanner:ctor(params)

     HeroBanner.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"nameText","loadingBar","lvText","expText","atkText","bloodText","dmgText","toughnessText","dependText",
                         "perText","armorText","speedText","heroPosNode","heroEquipNode","equipNode1","equipButton1","equipNode2",
                         "equipButton2","equipNode3","equipButton3","equipNode4","equipButton4","posNode","heroPos","loopNode",
                         "selectNode","bigEquipNode","curTime","tarTime","curText1","tarText1","curText2","tarText2","equipInstructionText",
                         "needLvText","moneyText","equipNameText","proTypeText1","proTypeText2","confirmButton","upButtonNode",
                         "buttonCloseText","buttonOpenText","instructionText","equipUpgradeNode","equipAdvanceNode",
                         "proTypeText2","Image_26_0_0_0_0","icon_up_139_0_0"})
     dump(playerMgr.heros)
     self.id = params.id
    --  print(self.id)

     self.pb   = playerMgr.heros[self.id]
     dump(self.pb)


     self.info = self.pb.info
     dump(self.info)


     self.heroBaseInfo  = infoManager:findInfo("roles","class_id",self.pb.level)
     dump(self.heroBaseInfo)
     self.upLevelExp = self.heroBaseInfo.upLevelExp

     self.loadingBar:setPercent(self.pb.exp/self.upLevelExp*100)
     self.expText:setString(string.format("%d/%d",self.pb.exp,self.upLevelExp))

     --从HERO表里读百分比
     self.rateInfo = infoManager:findInfo("heros","class_id",self.id)
     dump(self.rateInfo)

     self.skillInfo = infoManager:findInfo("skills","class_id",self.rateInfo.skill0_id)

     --上次和这次选择的装备
     self.curTag  = 0
     self.lastTag = 0
     --开始右边显示的是英雄的SPINE
     self.heroShow = true



      --英雄当前等级的基础属性（不算装备加成）
     --攻击
     self.heroAtk   = math.floor(self.heroBaseInfo.atk * self.rateInfo.atk_rate/10000)
     --破甲
     self.heroPojia = string.format("%.2f%%",self.heroBaseInfo.poJia/10000 * self.rateInfo.poJia_rate/10000*100)
     --血量
     self.heroBlood = math.floor(self.heroBaseInfo.hp * self.rateInfo.hp_rate/10000)
     --防御力
     self.heroDef   = math.floor(self.heroBaseInfo.deff * self.rateInfo.deff_rate/10000)
     --韧性
     self.heroTough = string.format("%.2f%%",self.heroBaseInfo.tenacity/10000 * self.rateInfo.tenacity_rate/10000*100)
     --暴击率
     self.heroPer   = string.format("%.2f%%",self.heroBaseInfo.baoJi_rate/10000 * self.rateInfo.baoJi_per_rate/10000*100)
     --暴击伤害
     self.heroDmg   = string.format("%.2f%%",self.heroBaseInfo.baoJi/10000 * self.rateInfo.baoJi_rate/10000*100)




     --获取四件装备栏Node
     for i=1,4 do
         self["iconSprite"..i]= AnimationNode.seek(self["equipNode"..i],"itemIconSprite")
     end

     self.propertyTable = {"攻击力","破甲","防御","韧性","血量","暴击率","暴伤害"}

     self.shengjie = false

end

--计算四件装备要用到显示的属性（包括对主角属性的加成）
function HeroBanner:getEquipsInfo()
    local eqmTable = {}
    for i=1,4 do

      table.insert(eqmTable,{class_id    = playerMgr.heros[self.id].intensify[i].class_id,
                             order_id    = playerMgr.heros[self.id].intensify[i].order_id,
                             intensifyId = playerMgr.heros[self.id].intensify[i].intensifyId})
      --local typeInfo = infoManager:findInfo("eqIntensifys","id",playerMgr.heros[self.id].intensify[i].intensifyId)


      self["curEpmInfo"..i]       = infoManager:findInfo("equipments","class_id",playerMgr.heros[self.id].intensify[i].class_id)
      --self["nextEpmInfo"..i]      = infoManager:findInfo("equipments","class_id",playerMgr.heros[self.id].intensify[i].class_id+1)

      self["equipNode"..i] :runAnimation(string.format(self["curEpmInfo"..i].quality), false)

      self["curIntensifyInfo"..i] = infoManager:findInfo("eqIntensifys",    "class_id",playerMgr.heros[self.id].intensify[i].intensifyId)

      if playerMgr.heros[self.id].intensify[i].intensifyId < 85 then
         self["tarIntensifyInfo"..i] = infoManager:findInfo("eqIntensifys", "class_id",playerMgr.heros[self.id].intensify[i].intensifyId+1)
         self["nextEpmInfo"..i]      = infoManager:findInfo("equipments","class_id",playerMgr.heros[self.id].intensify[i].class_id+1)
      else

         self["tarIntensifyInfo"..i] = infoManager:findInfo("eqIntensifys", "class_id",playerMgr.heros[self.id].intensify[i].intensifyId)
         self["nextEpmInfo"..i]      = self["curEpmInfo"..i]
      end
      -- self["tarIntensifyInfo"..i] = infoManager:findInfo("eqIntensifys",    "id",playerMgr.heros[self.id].intensify[i].intensifyId+1)
    end

    dump(eqmTable)


    --已强化次数，下一次强化次数，需要等级，需要金币数量,装备名，装备描述，两个属性类型
    for i=1,4 do
        self["curTime"..i]       = self["curIntensifyInfo"..i].times
        self["tarTime"..i]       = self["tarIntensifyInfo"..i].times
        self["needLv"..i]        = self["curIntensifyInfo"..i].needLv
        self["moneyText"..i]     = self["curIntensifyInfo"..i].price

        self["equipName"..i]        = self["curEpmInfo"..i].name
        self["equipInstruction"..i] = self["curEpmInfo"..i].instruction
        self["proTypeA"..i]         = self.propertyTable[self["curEpmInfo"..i].proType1]
        self["proTypeB"..i]         = self.propertyTable[self["curEpmInfo"..i].proType2]

        if self["curEpmInfo"..i].proType1 == 2 or self["curEpmInfo"..i].proType1 == 4 or self["curEpmInfo"..i].proType1 == 6 or self["curEpmInfo"..i].proType1 == 7 then
           if self["curIntensifyInfo"..i].type ==2 then
              self["curProValueA"..i] = string.format("%.2f%%",self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue1,i,false,1)/10000*100)
              self["tarProValueA"..i] = string.format("%.2f%%",self:fx(self["nextEpmInfo"..i].proValue1,self["nextEpmInfo"..i].deltaValue1,i,true,1)/10000*100)
           else
              self["curProValueA"..i] = string.format("%.2f%%",self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue1,i,false,1)/10000*100)
              self["tarProValueA"..i] = string.format("%.2f%%",self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue1,i,true,1)/10000*100)
           end
        else
           if self["curIntensifyInfo"..i].type ==2 then
              self["curProValueA"..i] = math.floor(self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue1,i,false,1))
              self["tarProValueA"..i] = math.floor(self:fx(self["nextEpmInfo"..i].proValue1,self["nextEpmInfo"..i].deltaValue1,i,true, 1))
           else
              self["curProValueA"..i] = math.floor(self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue1,i,false,1))
              self["tarProValueA"..i] = math.floor(self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue1,i,true, 1))
           end

        end

        if self["curEpmInfo"..i].proType2 == 2 or self["curEpmInfo"..i].proType2 == 4 or self["curEpmInfo"..i].proType2 == 6 or self["curEpmInfo"..i].proType2 == 7 then
           if self["curIntensifyInfo"..i].type ==2 then
              self["curProValueB"..i] = string.format("%.2f%%",self:fx(self["curEpmInfo"..i].proValue2,self["curEpmInfo"..i].deltaValue2,i,false,2)/10000*100)
              self["tarProValueB"..i] = string.format("%.2f%%",self:fx(self["nextEpmInfo"..i].proValue2,self["nextEpmInfo"..i].deltaValue2,i,true,2)/10000*100)
           else
              self["curProValueB"..i] = string.format("%.2f%%",self:fx(self["curEpmInfo"..i].proValue2,self["curEpmInfo"..i].deltaValue2,i,false,2)/10000*100)
              self["tarProValueB"..i] = string.format("%.2f%%",self:fx(self["curEpmInfo"..i].proValue2,self["curEpmInfo"..i].deltaValue2,i,true,2)/10000*100)
           end
        else
           if self["curIntensifyInfo"..i].type ==2 then
              self["curProValueB"..i] = math.floor(self:fx(self["curEpmInfo"..i].proValue2,self["curEpmInfo"..i].deltaValue2,i,false,2))
              self["tarProValueB"..i] = math.floor(self:fx(self["nextEpmInfo"..i].proValue2,self["nextEpmInfo"..i].deltaValue2,i,true, 2))
           else
              self["curProValueB"..i] = math.floor(self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue2,i,false,2))
              self["tarProValueB"..i] = math.floor(self:fx(self["curEpmInfo"..i].proValue1,self["curEpmInfo"..i].deltaValue2,i,true, 2))
           end

        end

        self["quality"..i]  = string.format(self["curEpmInfo"..i].quality)
        print("quality",self["curEpmInfo"..i].quality)
        self["resId"..i]    = self["curEpmInfo"..i].resId
    end

end

--计算装备当前属性/强化后的属性,传bool false代表强化前，true代表强化后
function HeroBanner:fx(x,delta,i,bool,AorB)
   if bool then
     if AorB ==1 then
        print("true")
        return x+(delta)*self["tarIntensifyInfo"..i].percent/10000
     else
        return x+(delta)*self["tarIntensifyInfo"..i].percent/10000
     end

   else
     if AorB ==1 then
         print("false")
        return x+(delta)*self["curIntensifyInfo"..i].percent/10000
     else

        return x+(delta)*self["curIntensifyInfo"..i].percent/10000
     end
   end

end


function HeroBanner:onEnter()



     self.nameText:setString(self.info.name)
     self.lvText:setString(self.pb.level)
     self.instructionText:setString(self.info.hero_instruction)



     --self:refreshHeroInfo()

     --英雄的攻击间隔
     self.speedText:setString(string.format("%.1f秒",self.skillInfo.coldTime/1000))


     --装备升阶动画节点
     --self.successAniNode:setVisible(false)

     self.equipUpgradeNode:setVisible(false)
     self.equipAdvanceNode:setVisible(false)

    self:showHeroSpine()
    self:refreshEquipIcons()

    self:getEquipsInfo()

    self:refreshHeroInfo()

    for i=1,4 do
         self["equipButton"..i]:setTag(i)
         self["equipButton"..i]:onClicked(function(event)
         print(event.target:getTag())
         self.selectNode:setVisible(false)
         self.selectNode:setPosition(self["equipButton"..i]:getPosition())
         self.selectNode:setVisible(true)
         self.selectNode:runAnimation("loop",true)
         self:changeEquip(event.target:getTag())
         end)
     end

     self.confirmButton:onClicked(function(event)
         musicManager:play(girl.UiMusicId.EQUIP_UPGRADE)
         local pb = pbBuilder:build({
         proto = "data/pb/interface/intensifyHero.pb",
         desc  = "interface.intensifyHero.Request",
         input = { hero_id = self.id,equip_id = playerMgr.heros[self.id].intensify[self.lastTag].class_id}
         })
         ws:send( "HEROINTENSIFY", pb, function(resultCode, des)
           print("HEROINTENSIFY:", resultCode,des)
           if resultCode == 0 then
             --musicManager:play(girl.UiMusicId.EQUIP_UPGRADE)
             musicManager:play(girl.UiMusicId.HEROEQUIP_UPGRADE)
             self.equipUpgradeNode:setVisible(true)
             self.equipUpgradeNode:runAnimation("up",false,function()
                  self.equipUpgradeNode:setVisible(false)
             end)
             if self.shengjie == true then
                self.equipAdvanceNode:setVisible(true)
                self.equipAdvanceNode:runAnimation("in",false,function()
                  self.equipAdvanceNode:setVisible(false)
                end)
                self.shengjie = false
             end
            --   dump(playerMgr.heros[self.id].intensify)
            --   print(self.lastTag)
            --   print(playerMgr.heros[self.id].intensify[self.lastTag].class_id)
            --   print(playerMgr.heros[self.id].intensify[self.lastTag].order_id)
            --   print(playerMgr.heros[self.id].intensify[self.lastTag].intensifyId)
              --self.ProjectNode_9:setVisible(true)
              --self.ProjectNode_9:runAnimation("in", false, function()
                   self:refreshEquipInfo(self.lastTag)
                   self:refreshEquipIcons()
                   self:refreshHeroInfo()
              --end)
              -- self:refreshEquipInfo(self.lastTag)
              -- self:refreshEquipIcons()
              -- self:refreshHeroInfo()

              MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.HEROEQUIP_UPGRADE)
              --self:getParent():getParent().topPanel:reload()
           end
           print("end")
       end)
     end)
end


function HeroBanner:refreshHeroInfo()

     -- self.id = params.id
     -- print(self.id)




      print(self.heroAtk)
      print(self["curProValueA"..1])
      self.atk   = self.heroAtk  + self["curProValueA"..1]

      self.pojia = self:cutStrAndToNumber(self.heroPojia,self["curProValueB"..1])
      self.blood = self.heroBlood + self["curProValueA"..4]
      self.def   = self.heroDef   + self["curProValueA"..2]

      self.tough = self:cutStrAndToNumber(self.heroTough,self["curProValueB"..2])
      self.per   = self:cutStrAndToNumber(self.heroPer,   self["curProValueA"..3])
      self.dmg   = self:cutStrAndToNumber(self.heroDmg,  self["curProValueB"..3])


     self.atkText:setString(self.atk)
     self.bloodText:setString(self.blood)
     self.dmgText:setString(self.dmg)
     self.toughnessText:setString(self.tough)
     self.dependText:setString(self.def)
     self.perText:setString(self.per)
     self.armorText:setString(self.pojia)
end


function HeroBanner:cutStrAndToNumber(str1,str2)
   print("str1",str1)
   print("str2",str2)
   return string.format("%.2f%%",tonumber(string.sub(str1,0,string.len(str1)-1)) + tonumber(string.sub(str2,0,string.len(str2)-1)))
end



function HeroBanner:refreshEquipIcons()

    self.resIdTable = {}
    for i=1,4 do
        local info  = infoManager:findInfo("equipments","class_id",self.pb.intensify[i].class_id)
        table.insert(self.resIdTable,info.resId)
    end

    dump(self.resIdTable)

    for i=1,4 do
        --local sp = cc.Sprite:create(resMgr:getResPath(self.resIdTable[i]))
        self["iconSprite"..i]:setTexture(resMgr:getResPath(self.resIdTable[i]))
    end
end

function HeroBanner:refreshEquipInfo(tag)

    self:getEquipsInfo()

    self:refreshEquipIcons()

    self.needLvText:setString(self["needLv"..tag])
    self.moneyText :setString(self["moneyText"..tag])
    self.curTime   :setString(self["curTime"..tag])
    self.tarTime   :setString(self["tarTime"..tag])

    if self["curIntensifyInfo"..tag].type == 2 then

       if self.pb.level < self["needLv"..tag] or playerMgr.status.gold < self["moneyText"..tag]  then
          self.upButtonNode:runAnimation("2")
          self.confirmButton:setTouchEnabled(false)
       else
          self.upButtonNode:runAnimation("1")
          self.confirmButton:setTouchEnabled(true)
       end
       self.buttonOpenText:setString("升阶")
       self.buttonCloseText:setString("升阶")
       self.shengjie = true
       print("升阶")

    elseif self["curIntensifyInfo"..tag].type == 0 then
        self.upButtonNode:runAnimation("2")
        self.confirmButton:setTouchEnabled(false)
        self.buttonOpenText:setString("已满")
        self.buttonCloseText:setString("已满")
    else

       if self.pb.level < self["needLv"..tag] or playerMgr.status.gold < self["moneyText"..tag] then
          self.upButtonNode:runAnimation("2")
          self.confirmButton:setTouchEnabled(false)
       else
          self.upButtonNode:runAnimation("1")
          self.confirmButton:setTouchEnabled(true)
       end
       self.buttonOpenText:setString("强化")
       self.buttonCloseText:setString("强化")
    end



    self.equipNameText       :setString(self["equipName"..tag])
    self.equipInstructionText:setString(self["equipInstruction"..tag])
    self.proTypeText1        :setString(self["proTypeA"..tag])
    self.proTypeText2        :setString(self["proTypeB"..tag])


    self.bigEquipNode:runAnimation(self["quality"..tag])

    local icon = AnimationNode.seek(self.bigEquipNode,"itemIconSprite")
    --local sprite = cc.Sprite:create(resMgr:getResPath(self["resId"..tag]))
    icon:setTexture(resMgr:getResPath(self["resId"..tag]))

    self.curText1:setString(self["curProValueA"..tag])
    self.tarText1:setString(self["tarProValueA"..tag])
    self.curText2:setString(self["curProValueB"..tag])
    self.tarText2:setString(self["tarProValueB"..tag])

    self.curText2:show()
    self.tarText2:show()
    self.proTypeText2:show()
    self.Image_26_0_0_0_0:setVisible(true)
    self.icon_up_139_0_0:show()

    if tag == 4  then
      self.curText2:hide()
      self.tarText2:hide()
      self.proTypeText2:hide()
      self.Image_26_0_0_0_0:setVisible(false)
      self.icon_up_139_0_0:hide()

    end

      -- self["curProValueA"..i] = self:fx(i,false,1)/10000/10000*100
      --      self["tarProValueA"..i] = self:fx(i,true, 1)/10000/10000*100

      --      self["curProValueB"..i] = self:fx(i,true, 2)/10000/10000*100
      --      self["tarProValueB"..i] = self:fx(i,true, 2)/10000/10000*100



end

function HeroBanner:showHeroSpine()
    print("1111111self.selectNode false")
    self.selectNode:setVisible(false)
    print("self.selectNode false")
    self.heroPosNode:runAnimation("in",false)
    self.posNode:runAnimation("loop", true)
    self.loopNode:runAnimation("loop", true)
    self.heroSpine = Hero.createOnUiWithId(self.id)
    self.heroSpine:addTo(self.heroPos)
    self.heroShow = true
    print("222222self.selectNode false")
end

function HeroBanner:changeEquip(tag)
    if self.heroShow == false  then
         if self.lastTag == tag then
            print("两次点击的一样，切换回主角Spine")
            self.heroEquipNode:runAnimation("out",false,function()
            self:showHeroSpine()
            print("self:showHeroSpine()")
            end)
         else
            self:refreshEquipInfo(tag)
         end
    else
        self.heroPosNode:runAnimation("out",false,function()
        self.heroSpine:removeFromParent()
        self.heroSpine = nil
        self.heroShow = false
        self.heroEquipNode:runAnimation("in",false)
        self:refreshEquipInfo(tag)
        end)

    end
    self.lastTag = tag
end

-- function HeroBanner:showHeroSpine()

--     self.heroPosNode:runAnimation("in",false)
--     self.posNode:runAnimation("loop", true)
--     self.loopNode:runAnimation("loop", true)
--     self.heroSpine = Hero.createOnUiWithId(self.id)
--     self.heroSpine:addTo(self.heroPos)
--     self.heroShow = true


-- end





return HeroBanner

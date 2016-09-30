local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("..controls.CocostudioNode")

-- singleton
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr       = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()


local GirlsCardNode = class("GirlsCardNode", AnimationNode)



function GirlsCardNode.create(param)

    -- print(param.id)

    print("create GirlsCardNode")
    if param.assemble then

       return GirlsCardNode.new({csbName = "nodes/girls/girlsList/girlsCard1.csb",id = param.id, assemble = param.assemble})
    else
       return GirlsCardNode.new({csbName = "nodes/girls/girlsList/girlsCard2.csb",id = param.id, assemble = param.assemble})
    end


end



function GirlsCardNode:ctor(params)

  if params.assemble then
     self.id = params.id
     self.assemble = params.assemble
     --dump(playerMgr.souls[self.id])

     --获得强化次数信息------------------------------------------------------------------------------------------------
     local info = playerMgr.souls[self.id].intensifys

     self.intensifysTable = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}

     --dump(self.intensifysTable)

     self.times = 0

     for k,v in ipairs(self.intensifysTable) do
         local mod  = v % 100
         self.times = self.times + mod
     end
     ----------------------------------------------------------------------------------------------------------------

     --获得攻击力信息------------------------------------------------------------------------------------------------------
     -- local breachId = tonumber(self.id.."0"..playerMgr.souls[self.id].star)

     -- self.breachInfo = infoMgr:findInfo("breachs","class_id",breachId)

     -- print("攻击成长值:",self.breachInfo.atk)

     -- self.atkValue = self.breachInfo.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack


     ----------------------------------------------------------------------------------------------------------------

     GirlsCardNode.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"girlCardLSprite","starNode","teamIndexNode","typeNode","nameText","lvText","loveLevelText","loadingBar",
                      "advancedLoopNode","fragmentNumText","attackText","strengthenText","numText","atkValueText","timesText","progressLabel"})

     self.funcTable = {self.attackText,self.strengthenText,self.fragmentNumText,self.fragmentNumText}
     --dump(playerMgr.soulFragments)
     print("======fragment:"..self.id)
     if playerMgr.soulFragments[self.id] ==nil then
        self.fragmentCount = 0
     else
        self.fragmentCount = playerMgr.soulFragments[self.id].count
     end
     --获得攻击力信息------------------------------------------------------------------------------------------------------
     self:refreshAttack()

  else

     self.id = params.id
     self.assemble = params.assemble

     GirlsCardNode.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"lvText","starNode","typeNode","nameText","girlCardLSprite",
                         "slotNode1","slotNode2","slotNode3","slotNode4"})


     self.num = {}
     for k,v in girl.pairsByKeys(playerMgr.assemblages) do
       table.insert(self.num,k)
     end

     for i=1,4 do
       self["orderId"..i] = -1
     end
     --初始化配件id表，0代表没有穿，-1代表没有解锁
     self.idTable = {0,-1,-1,-1}




  end

end

function GirlsCardNode:onEnter()

    self.lvText:setString(playerMgr.souls[self.id].level)
    self.starNode:runAnimation(string.format(playerMgr.souls[self.id].star))
    self.typeNode:runAnimation(string.format(playerMgr.souls[self.id].info.type..playerMgr.souls[self.id].info.color))
    self.nameText:setString(playerMgr.souls[self.id].info.name)

    self.girlCardLSprite:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))


    self:runAnimation(string.format(playerMgr.souls[self.id].star))



    if self.assemble then
       self:refreshFunc(1,1)
       self.loadingBar:setPercent(playerMgr.souls[self.id].currentEnergy/playerMgr.souls[self.id].info.maxEnergy*100)
       self.progressLabel:setString(string.format("%d/%d",playerMgr.souls[self.id].currentEnergy,playerMgr.souls[self.id].info.maxEnergy))
       self.loveLevelText:setString(playerMgr.souls[self.id].loveLevel)


    else
       self:showSlotsInfo()
    end

end

function GirlsCardNode:refreshLoveLv()

       self.loveLevelText:setString(playerMgr.souls[self.id].loveLevel)

end



function GirlsCardNode:refreshAttack()


     --星级基础攻击计算
     local breachId = tonumber(self.id.."0"..playerMgr.souls[self.id].star)

     self.breachInfo = infoMgr:findInfo("breachs","class_id",breachId)

    --  print("攻击成长值:",self.breachInfo.atk)

     self.atkValue = self.breachInfo.atk * playerMgr.souls[self.id].level + playerMgr.souls[self.id].info.base_attack

     --强化加成攻击计算
    --  dump(playerMgr.souls[self.id].intensifys)

     local info = playerMgr.souls[self.id].intensifys


     if info.atkId % 100 ~=0 then

       local upgradeInfo = infoMgr:findInfo("intensifys","class_id",info.atkId)
       self.atkValue = self.atkValue + upgradeInfo.atkValue

     end

    for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
    --   print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self["assemblage"..v.order] = infoMgr:findInfo("assemblages","class_id",v.class_id)
    end

     for i=1,4 do
    --   print("第%d次循环",i)
      if self["assemblage"..i] then
         if self["assemblage"..i].attributeType == 1 or self["assemblage"..i].attributeType == 10 then
             self.atkValue = math.floor(self.atkValue * (1+self["assemblage"..i].attributeValue/10000))
         end
     else
        -- print("没有第%d个配件",i)
     end



  end


     self.atkValueText:setString(string.format(self.atkValue))


end

function GirlsCardNode:showSlotsInfo()

    if self.slotNode1==nil then
       print("return")
       return
    end

   self.slotNode1:runAnimation("free", false)
   self.slotNode2:runAnimation("lock",false)
   self.slotNode3:runAnimation("lock",false)
   self.slotNode4:runAnimation("lock",false)


   if 3<=playerMgr.souls[self.id].star and  playerMgr.souls[self.id].star < 5 then
      self.slotNode2:runAnimation("free",false)
      self.idTable = {0,0,-1,-1}
   end
   if playerMgr.souls[self.id].star == 5 then
      self.slotNode2:runAnimation("free",false)
      self.slotNode3:runAnimation("free",false)
      self.idTable = {0,0,0,-1}
   end
   if playerMgr.souls[self.id].star == 6  then
      self.slotNode2:runAnimation("free",false)
      self.slotNode3:runAnimation("free",false)
      self.slotNode4:runAnimation("free",false)
      self.idTable = {0,0,0,0}
   end

   for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
      print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self.idTable[v.order] = v.id
      self["slotNode"..v.order]:runAnimation("on",false)
      self["itemSlotNode"..v.order] = AnimationNode.seek(self["slotNode"..v.order],"itemSlotNode")
      local sprite = AnimationNode.seek(self["slotNode"..v.order],"itemIconSprite")


      local assemblage = infoMgr:findInfo("assemblages","class_id",v.class_id)
      self["itemSlotNode"..v.order]:runAnimation(assemblage.quality)
      --local info = resMgr:findInfo(assemblage.resId)
      --local pic = cc.Sprite:create(resMgr:getResPath(assemblage.resId))
      sprite:setTexture(resMgr:getResPath(assemblage.resId))

   end



end

function GirlsCardNode:refreshFragments()

  local breachId = tonumber(self.id.."0"..playerMgr.souls[self.id].star)

  self.breachInfo = infoMgr:findInfo("breachs","class_id",breachId)

  self:runAnimation(string.format(playerMgr.souls[self.id].star))
  self.starNode:runAnimation(string.format(playerMgr.souls[self.id].star))

  if playerMgr.soulFragments[self.id] ==nil then
        self.fragmentCount = 0
  else
        self.fragmentCount = playerMgr.soulFragments[self.id].count
  end

  self.numText:setString(string.format("%d/%d",self.fragmentCount,self.breachInfo.up_needCount))
      if self.fragmentCount >= self.breachInfo.up_needCount and playerMgr.souls[self.id].star < 6 then
         self.advancedLoopNode:setVisible(true)
         self.advancedLoopNode:runAnimation("loop",true)
         self.fragmentNumText:setVisible(false)
      else
         self.fragmentNumText:setVisible(true)
         self.advancedLoopNode:setVisible(false)

      end

end

function GirlsCardNode:refreshTimes()


  local info = playerMgr.souls[self.id].intensifys

  self.intensifysTable = {info.atkId,info.speedId,info.perId,info.valueId,info.armorId,info.masterId}

     --dump(self.intensifysTable)

     self.newTimes = 0

     for k,v in ipairs(self.intensifysTable) do
         local mod  = v % 100
         self.newTimes = self.newTimes + mod
     end

    self.times = self.newTimes

    self.timesText:setString(string.format("%d/%d",self.times,self.breachInfo.qianghua_limit))

end


function GirlsCardNode:refreshFunc(lastfuncIndex,curfuncIndex,new)
	if curfuncIndex ==5  then
		--self.saveIndex = lastfuncIndex
		return
	end
  if new then
    print("new")
    self.funcTable[1]:setVisible(false)
  end
	-- if lastfuncIndex ==5 then
	-- 	lastfuncIndex = self.saveIndex
	-- end

	-- print(lastfuncIndex)
	-- print(curfuncIndex)

   self.funcTable[lastfuncIndex]:setVisible(false)
   self.funcTable[curfuncIndex]:setVisible(true)

   if curfuncIndex ==1 then
      self.advancedLoopNode:setVisible(false)
   	  self.atkValueText:setString(string.format(self.atkValue))
   elseif curfuncIndex == 2 then
   	  self.advancedLoopNode:setVisible(false)
      self:refreshTimes()
   elseif curfuncIndex == 3 then

     self:refreshFragments()
  elseif curfuncIndex == 4 then
      self.advancedLoopNode:setVisible(false)
      self.fragmentNumText:setVisible(false)
      --self.numText:setString(string.format("%d/100",playerMgr.souls[self.id].count))
   end

end



return GirlsCardNode

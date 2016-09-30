local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GirlsCardNode = import("..fragment.GirlsCardNode",CURRENT_MODULE_NAME)
local SoulAssembleNode = import("..fragment.SoulAssembleNode", CURRENT_MODULE_NAME)
-- singleton
local infoMgr       = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()

local SoulsPeijianPanel = class("SoulsPeijianPanel", PanelBase)

function SoulsPeijianPanel.create(params)
  return SoulsPeijianPanel.new({ csbName = "layers/girls/GirlsPeijian.csb",id = params.id,edu = params.edu })
end


function SoulsPeijianPanel:ctor(params)
  SoulsPeijianPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"mapBackButton","girlCardLSprite","star1","star2","star3","star4","star5","star6","Button_1",
                      "nameText","typeNode","lvText","cardNode","itemNode1","itemNode2","itemNode3","itemNode4","detailButton"})
  self.id  = params.id
  self.edu = params.edu 
  print(self.id)



  self.typeTbale = {"攻击力","普攻CD","技能CD","暴击率","暴击伤害","破甲","韧性",{"普攻CD","技能CD"},{"暴击率","暴击伤害"},{"攻击力","破甲"}}

  --dump(playerMgr.souls[self.id])
  dump(playerMgr.souls[self.id].assemblages)
  self.num = {}
  for k,v in girl.pairsByKeys(playerMgr.assemblages) do
       table.insert(self.num,k)
  end

  self.assemble = {}
  for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
      print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
  end

  for i=1,4 do
      self["orderId"..i] = -1 
  end
  --初始化配件id表，0代表没有穿，-1代表没有解锁
  self.idTable = {0,-1,-1,-1}
  
end


function SoulsPeijianPanel:onEnter()

  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  SoulsPeijianPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  if self.edu then
     MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  end

  
  --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))
  self.girlCardLSprite:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_CARD,self.id))

  self.cardNode:runAnimation(string.format(playerMgr.souls[self.id].star))

   --type
  self.typeNode:runAnimation(string.format(playerMgr.souls[self.id].info.type..playerMgr.souls[self.id].info.color))

  --名字
  self.nameText:setString(playerMgr.souls[self.id].info.name)

  --等级
  self.lvText:setString(string.format("Lv.%d/100",playerMgr.souls[self.id].level))

  --星阶
  for i=1,playerMgr.souls[self.id].star do
      self["star"..i]:setVisible(true)
  end

 
  for i=1,4 do
        self["addButton"..i] = AnimationNode.seek(self["itemNode"..i],"Button_1")
        self["removeButton"..i] = AnimationNode.seek(self["itemNode"..i],"removeButton")
        self["unlockStarText"..i] = AnimationNode.seek(self["itemNode"..i],"explainText")
        self["removeButton"..i]:setTag(i)
        --脱装备按钮，第二个参数ID传0代表脱掉了
        self["removeButton"..i]:onClicked(function(event)
        print("event.target:getTag()",event.target:getTag())
        self["itemNode"..event.target:getTag()]:runAnimation("get",false)
        self.idTable[event.target:getTag()] = 0
            local pb = pbBuilder:build({
            proto = "data/pb/interface/assemblagesChange.pb",
            desc  = "interface.assemblagesChange.Request",
            input = { soul_id = self.id ,id = self.idTable}
            })

            ws:send( "ASSEMBLAGESCHANGE", pb, function(resultCode, des)
                 print("ASSEMBLAGESCHANGE:", resultCode,des)
                 if resultCode == 0 then
                     print("ASSEMBLAGESCHANGE 成功")
                     musicManager:play(girl.UiMusicId.ASSEMBLE_TAKE_OFF)
                     
                 end
            end)
        end)
        self["addButton"..i]:setTag(i)
        self["addButton"..i]:onClicked(function(event)
        print("add add add add add")
        panelFactory:createPanel(panelFactory.Panels.SoulsPeijianListPanel,nil,{order = event.target:getTag(),id = self.id,idTable = self.idTable}):addTo(self)
      end)
  end

   
   self.itemNode1:runAnimation("get", false)
   self.itemNode2:runAnimation("lock",false)
   self.unlockStarText2:setString("3星级解锁")
   self.itemNode3:runAnimation("lock",false)
   self.unlockStarText3:setString("5星级解锁")
   self.itemNode4:runAnimation("lock",false)
   self.unlockStarText4:setString("6星级解锁")

   if 3<=playerMgr.souls[self.id].star and  playerMgr.souls[self.id].star < 5 then
      self.itemNode2:runAnimation("get",false)
      --self.unlockStarText2:setString("元神3星级解锁")
      self.idTable = {0,0,-1,-1}
   end
   if playerMgr.souls[self.id].star == 5 then
      self.itemNode2:runAnimation("get",false)
      self.itemNode3:runAnimation("get",false)
      --self.unlockStarText3:setString("元神5星级解锁")
      self.idTable = {0,0,0,-1}
   end
   if playerMgr.souls[self.id].star == 6  then
      self.itemNode2:runAnimation("get",false)
      self.itemNode3:runAnimation("get",false)
      self.itemNode4:runAnimation("get",false)
      --self.unlockStarText4:setString("元神6星级解锁")
      self.idTable = {0,0,0,0}
   end

  for k,v in girl.pairsByKeys(playerMgr.souls[self.id].assemblages) do
      print("id",v.id,"class_id:",v.class_id,"soul_id:",v.soul_id,v.order)
      self.idTable[v.order] = v.id
      self:changeAssemblage(v.order,v.id)
      print("self.idTable[v.order]",self.idTable[v.order])
  end


  self:runAnimation("in",false)

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
                               {func = 3,id = self.id})
          self:close()  
     end)
     --MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)

  end

      

  end)


  local function onPanelClosed(reason)
      MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  end

  self.detailButton:onClicked(function()
    musicManager:play(girl.UiMusicId.BUTTON_CLICK)
      panelFactory:createPanel(panelFactory.Panels.SoulsDetailPanel,onPanelClosed,{id = self.id}):addTo(self)
      MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
  end)



end


function SoulsPeijianPanel:refresh()
   
   
 
end


function SoulsPeijianPanel:changeAssemblage(order,idx)
   
   print("do change")
   self["itemNode"..order]:runAnimation("on",false)

   local sprite     = AnimationNode.seek(self["itemNode"..order],"itemIconSprite")
   local nameText   = AnimationNode.seek(self["itemNode"..order],"equipNameText")
   local equipNode  = AnimationNode.seek(self["itemNode"..order],"equipNode")

   local protocolText1 = AnimationNode.seek(self["itemNode"..order],"protocolText1")
   local protocolText2 = AnimationNode.seek(self["itemNode"..order],"protocolText2")
   local valueText1    = AnimationNode.seek(self["itemNode"..order],"valueText1")
   local valueText2    = AnimationNode.seek(self["itemNode"..order],"valueText2")
   local Image_26_0    = AnimationNode.seek(self["itemNode"..order],"Image_26_0")


   local classid = playerMgr.assemblages[idx].class_id

   local assemblage = infoMgr:findInfo("assemblages","class_id",classid)

   -- dump(assemblage)

   nameText:setString(assemblage.name)
   equipNode:runAnimation(assemblage.quality)


   local info = resMgr:findInfo(assemblage.resId)
   -- dump(info)

   --local pic = cc.Sprite:create(info.name)
   sprite:setTexture(info.name)

   if assemblage.attributeType < 8 then
      protocolText2:setVisible(false)
      valueText2:setVisible(false)
      Image_26_0:setVisible(false)

      protocolText1:setString(self.typeTbale[assemblage.attributeType])
      if assemblage.attributeType ==2 or assemblage.attributeType ==3 then
         valueText1:setString(string.format("-%.2f%%",assemblage.attributeValue/10000*100))
      else
         valueText1:setString(string.format("+%.2f%%",assemblage.attributeValue/10000*100))
      end
   else
      protocolText1:setString(self.typeTbale[assemblage.attributeType][1])
      protocolText2:setString(self.typeTbale[assemblage.attributeType][2])
      if assemblage.attributeType == 8 then
         valueText1:setString(string.format("-%.2f%%",assemblage.attributeValue/10000*100))
         valueText2:setString(string.format("-%.2f%%",assemblage.attributeValue/10000*100))
      else
         valueText1:setString(string.format("+%.2f%%",assemblage.attributeValue/10000*100))
         valueText2:setString(string.format("+%.2f%%",assemblage.attributeValue/10000*100))
      end

   end
 
end


return SoulsPeijianPanel

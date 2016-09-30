local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local IconNode      = import("..fragment.IconNode",CURRENT_MODULE_NAME)

local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()

local QuestPartBoxInfoPanel = class("QuestPartGetPanel", PanelBase)


function QuestPartBoxInfoPanel.create(params)
  return QuestPartBoxInfoPanel.new({ csbName = "layers/quest/quest_boxinfo.csb",info = params.info})
end

function QuestPartBoxInfoPanel:ctor(params)

  QuestPartBoxInfoPanel.super.ctor(self, params)
  self:enableNodeEvents()
  self:mapUiElements({"closeButton","IconNode","itemNode1","itemNode2","itemNode3","itemNode4","itemNode5",
                       "itemCount1","itemCount2","itemCount3","itemCount4","itemCount5",
                       "itemNameText1","itemNameText2","itemNameText3","itemNameText4","itemNameText5"})

  self.info = params.info
  dump(self.info)

  self.equipIcon = {[1000] = "icon/equip/equip01.png",[1001] ="icon/equip/equip02.png", [1002] ="icon/equip/equip03.png"}
  self.equipName = {[1000] = "黄金小马甲",[1001] ="氪金眼睛", [1002] ="要你命手枪"}
 end

function QuestPartBoxInfoPanel:onEnter()

   QuestPartBoxInfoPanel.super.onEnter(self)
   girl.addTouchEventListener(self, {swallow = true})

   self:runAnimation("in", false)
   self.IconNode:runAnimation(string.format(#self.info))


   for i=1,#self.info do
        if self.info[i].type == 1 then
           print("道具")
           print(self.info[i].rewardId) --根据rewardId来创建Icon图标
           local sprite = AnimationNode.seek(self["itemNode"..i],"itemIconSprite")
           -- local pic = cc.Sprite:create(self.equipIcon[self.info[i].rewardId])
           sprite:setTextureByPlist(self.equipIcon[self.info[i].rewardId])
           self["itemCount"..i]:setString(string.format("X%d",self.info[i].rewardCount))
           self["itemNameText"..i]:setString(self.equipName[self.info[i].rewardId])

        elseif self.info[i].type == 2 then
          print("元魂")
          --todo
        elseif self.info[i].type == 3 then
          print("金币")
           local sprite = AnimationNode.seek(self["itemNode"..i],"itemIconSprite")
           sprite:setTexture(resMgr:getIconPath(resMgr.IconType.GOLD))
           self["itemCount"..i]:setString(string.format("X%d",self.info[i].rewardCount))
           self["itemNameText"..i]:setString("金币")

        elseif self.info[i].type == 4 then
          print("钻石")
          local sprite = AnimationNode.seek(self["itemNode"..i],"itemIconSprite")
          sprite:setTexture(resMgr:getIconPath(resMgr.IconType.DIMOND))
          self["itemCount"..i]:setString(string.format("X%d",self.info[i].rewardCount))
          self["itemNameText"..i]:setString("钻石")

        elseif self.info[i].type == 7 then
          print("配件")
          local sprite = AnimationNode.seek(self["itemNode"..i],"itemIconSprite")
          local itemInfo = infoMgr:findInfo("assemblages","class_id",self.info[i].rewardId)  
          self["itemCount"..i]:setString(string.format("X%d",self.info[i].rewardCount))
          self["itemNameText"..i]:setString(itemInfo.name)
          self["itemNode"..i]:runAnimation(itemInfo.quality,false)
          sprite:setTexture(resMgr:getResPath(itemInfo.resId))

        elseif self.info[i].type == 9 then
          print("材料")
          local sprite = AnimationNode.seek(self["itemNode"..i],"itemIconSprite")
          local itemInfo = infoMgr:findInfo("materials","class_id",self.info[i].rewardId)  
          self["itemCount"..i]:setString(string.format("X%d",self.info[i].rewardCount))
          self["itemNameText"..i]:setString(itemInfo.name)
          self["itemNode"..i]:runAnimation(itemInfo.quality,false)
          sprite:setTexture(resMgr:getResPath(itemInfo.resId))
        end

       -- local sprite = AnimationNode.seek(self["itemNode"..i],"Sprite")

       -- local pic = cc.Sprite:create("textures/ui/icon/equip/icon_coin.png")
       -- sprite:setTextureByPlist(pic:getTexture())
   end
 



  self.closeButton:onClicked(function()
       musicManager:play(girl.UiMusicId.BUTTON_CLICK)
       print(girl.UiMusicId.BUTTON_CLICK)
       self:getParent():runAnimation("in", false)
       self:close()

  end)  

end



return QuestPartBoxInfoPanel

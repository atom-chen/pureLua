local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode  = import("..controls.CocostudioNode")
local infoMgr        = import("...data.information.InfoManager",CURRENT_MODULE_NAME):getInstance()
local resMgr         = import("...data.information.ResManager" ,CURRENT_MODULE_NAME):getInstance()
local ws             = import("...extra.NetWebSocket",          CURRENT_MODULE_NAME):getInstance()
local pbBuilder      = import("...extra.ProtobufBuilder",       CURRENT_MODULE_NAME):getInstance()
local playerMgr      = import("...data.PlayerDataManager",      CURRENT_MODULE_NAME):getInstance()


local SmallIconNode  = class("SmallIconNode", AnimationNode)

function SmallIconNode.create(param)
  return SmallIconNode.new({csbName = "nodes/icon_equipS.csb",info = param.info})
end

function SmallIconNode:ctor(params)

     SmallIconNode.super.ctor(self,params)
     self:enableNodeEvents()

     self:mapUiElements({"itemIconSprite","getItemCountText","getItemNameText"})

     self.getItemCountText:setVisible(true)
     self.getItemNameText:setVisible(true)

     self.info = params.info

    if self.info.type == 1 then
        print("道具")
        --print(self.info.rewardId) --根据rewardId来创建Icon图标
        -- local pic = cc.Sprite:create(self.equipIcon[self.info.rewardId])
        -- self["itemIconSprite"]:setTexture(pic:getTexture())
    elseif self.info.type == 2 then
        print("元魂")
        --todo
    elseif self.info.type == 3 then
        print("金币")
        self["itemIconSprite"]:setTexture(resMgr:getIconPath(resMgr.IconType.GOLD))
        self["getItemCountText"]:setString(string.format("X%d",self.info.rewardCount))
        self["getItemNameText"]:setString("金币")

    elseif self.info.type == 4 then
        print("钻石")
        self["itemIconSprite"]:setTexture(resMgr:getIconPath(resMgr.IconType.DIMOND))
        self["getItemCountText"]:setString(string.format("X%d",self.info.rewardCount))
        self["getItemNameText"]:setString("钻石")
    elseif self.info.type == 7 then
        print("配件")

        local itemInfo = infoMgr:findInfo("assemblages","class_id",self.info.rewardId)
        self["getItemCountText"]:setString(string.format("X%d",self.info.rewardCount))
        self["getItemNameText"]:setString(itemInfo.name)
        self:runAnimation(itemInfo.quality,false)
        self["itemIconSprite"]:setTexture(resMgr:getResPath(itemInfo.resId))

    elseif self.info.type == 9 then
        print("材料")

        local itemInfo = infoMgr:findInfo("materials","class_id",self.info.rewardId)
        self["getItemCountText"]:setString(string.format("X%d",self.info.rewardCount))
        self["getItemNameText"]:setString(itemInfo.name)
        self:runAnimation(itemInfo.quality,false)
        self["itemIconSprite"]:setTexture(resMgr:getResPath(itemInfo.resId))
    end
end

return SmallIconNode

local CURRENT_MODULE_NAME = ...

-- classs
local IconNode		     = import("..fragment.IconNode", CURRENT_MODULE_NAME)
local AnimationNode		 = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)


-- singleton
local infoMgr            = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr             = import("...data.information.ResManager" , CURRENT_MODULE_NAME):getInstance()
local playerMgr          = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local SoulAssembleNode   = class("SoulAssembleNode", AnimationNode)



function SoulAssembleNode.create(param)

    dump(param)

    print("create SoulAssembleNode")
    print("create SoulAssembleNode")
    print("create SoulAssembleNode")

    return SoulAssembleNode.new({csbName = "nodes/girls/girlPeijian/peijian2.csb"})

end



function SoulAssembleNode:ctor(params)


     SoulAssembleNode.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"equipNameText","ownerText","protocolText1","protocolText2","valueText1","valueText2",
     	                 "removeButton","itemIconSprite","Image_26_0","ProjectNode_3","button"})

     --self:runAnimation(string.format(self.data.type))
     self.typeTbale = {"攻击力","普攻CD","技能CD","暴击率","暴击伤害","破甲","韧性",{"普攻CD","技能CD"},{"暴击率","暴击伤害"},{"攻击力","破甲"}}



    --self.equipNode:runAnimation("2")
    self.equipNode =  IconNode.seek(self,"equipNode")
end

function SoulAssembleNode:onEnter()
    SoulAssembleNode.super.onEnter(self)
    self.button:setVisible(false)
   -- self:runAnimation("usedin",false)
   -- self.equipNameText:setString(self.assemblage.name)
   -- self.equipNode:runAnimation(self.assemblage.quality)

end

function SoulAssembleNode:onExit()
    SoulAssembleNode.super.onExit(self)
end



function SoulAssembleNode:initSelf(classid,idx,soulId)

   self:runAnimation("usedin",false)
   --读静态表配件信息
   -- print(classid,idx,soulId)
   self.assemblage = infoMgr:findInfo("assemblages","class_id",classid)

   -- dump(self.assemblage)
   --读玩家数据的配件信息

   self.num = {}
   for k,v in girl.pairsByKeys(playerMgr.assemblages) do
       table.insert(self.num,k)
   end
   print(playerMgr.assemblages[self.num[idx]].soul_id)

   --判断这个件装备有没有战姬在穿,自己在穿显示已装备，其他元魂在穿显示XXX元魂已装备
   if  playerMgr.assemblages[self.num[idx]].soul_id == 0 then
   	   self.ownerText:setVisible(false)
   else
      if playerMgr.assemblages[self.num[idx]].soul_id == soulId then
         self.ownerText:setString("已装备")
      else
         self.ownerText:setString(playerMgr.souls[playerMgr.assemblages[self.num[idx]].soul_id].info.name.."已装备")
      end
   end

   self.equipNameText:setString(self.assemblage.name)
   self.equipNode:runAnimation(self.assemblage.quality)

   local info = resMgr:findInfo(self.assemblage.resId)
   -- dump(info)

   local pic = cc.Sprite:create(info.name)
   local sprite = AnimationNode.seek(self.equipNode,"itemIconSprite")
   sprite:setTexture(info.name)

   if self.assemblage.attributeType < 8 then
   	  self.protocolText2:setVisible(false)
   	  self.valueText2:setVisible(false)
   	  self.Image_26_0:setVisible(false)

   	  self.protocolText1:setString(self.typeTbale[self.assemblage.attributeType])
   	  if self.assemblage.attributeType ==2 or self.assemblage.attributeType ==3 then
   	  	 self.valueText1:setString(string.format("-%.2f%%",self.assemblage.attributeValue/10000*100))
   	  else
   	  	 self.valueText1:setString(string.format("+%.2f%%",self.assemblage.attributeValue/10000*100))
   	  end
   else
   	  self.protocolText1:setString(self.typeTbale[self.assemblage.attributeType][1])
   	  self.protocolText2:setString(self.typeTbale[self.assemblage.attributeType][2])
   	  if self.assemblage.attributeType == 8 then
   	     self.valueText1:setString(string.format("-%.2f%%",self.assemblage.attributeValue/10000*100))
   	     self.valueText2:setString(string.format("-%.2f%%",self.assemblage.attributeValue/10000*100))
   	  else
   	  	 self.valueText1:setString(string.format("+%.2f%%",self.assemblage.attributeValue/10000*100))
   	     self.valueText2:setString(string.format("+%.2f%%",self.assemblage.attributeValue/10000*100))
   	  end

   end

end




return SoulAssembleNode

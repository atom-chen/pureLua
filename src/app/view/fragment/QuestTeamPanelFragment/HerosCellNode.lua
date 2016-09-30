local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("...controls.CocostudioNode")

-- singleton
local playerMgr     = import("....data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("....data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()

local HerosCellNode = class("HerosCellNode", AnimationNode)



function HerosCellNode.create(param)
    print(param.id)
    print("create HerosCellNode")
    return HerosCellNode.new({csbName = "nodes/quest/Quest_team/heroListSingle.csb",id = param.id})
end



function HerosCellNode:ctor(params)

     self.id = params.id

     HerosCellNode.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"bd_chuzhan_1","nameText1","nameText2",
                         "heroHead","lvText2","lvText1"})
end

function HerosCellNode:onEnter()

    if  self.id == 0 then
        self:runAnimation("3")

    else
        -- dump(playerMgr.souls[self.id])
        -- self.lvText:setString(string.format("Lv.%d",playerMgr.souls[self.id].level))
        -- self.typeNode:runAnimation(string.format(playerMgr.souls[self.id].info.color))
        -- self.nameText:setString(playerMgr.souls[self.id].info.name)
        -- self.nameText_0:setString(playerMgr.souls[self.id].info.name)

        -- self.starText:setString(playerMgr.souls[self.id].info.star)
        -- self.starText_0:setString(playerMgr.souls[self.id].info.star)

        -- self.head_girl01_11:setTextureByPlist(sprite:getTexture())

        self:runAnimation("1")
    end


end


function HerosCellNode:changeSelected()
    self:runAnimation("2")
end


function HerosCellNode:changeNormal()
    self:runAnimation("1")
end



return HerosCellNode

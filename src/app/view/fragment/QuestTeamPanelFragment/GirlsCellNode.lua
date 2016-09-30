local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("...controls.CocostudioNode")

-- singleton
local playerMgr     = import("....data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("....data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("....data.information.ResManager", CURRENT_MODULE_NAME):getInstance()

local GirlsCellNode = class("GirlsCardNode", AnimationNode)



function GirlsCellNode.create(param)
    print(param.id)
    print("create GirlsCellNode")
    return GirlsCellNode.new({csbName = "nodes/quest/Quest_team/girlListSingle.csb",id = param.id})
end



function GirlsCellNode:ctor(params)

    self.id = params.id
    GirlsCellNode.super.ctor(self,params)
    self:enableNodeEvents()
    self:mapUiElements({"head_girl01_11","nameText","nameText_0",
                         "typeNode","starText","starText_0","lvText","bd_chuzhan_1","colorStarNode"})
end

function GirlsCellNode:onEnter()

    if  self.id == 0 then
        self:runAnimation("3")
    else
        -- dump(playerMgr.souls[self.id])
        self.lvText:setString(string.format("Lv.%d",playerMgr.souls[self.id].level))
        self.typeNode:runAnimation(string.format(playerMgr.souls[self.id].info.type..playerMgr.souls[self.id].info.color))
        self.nameText:setString(playerMgr.souls[self.id].info.name)
        self.nameText_0:setString(playerMgr.souls[self.id].info.name)

        self.starText:setString(playerMgr.souls[self.id].star)
        self.starText_0:setString(playerMgr.souls[self.id].star)

        self.colorStarNode:runAnimation(string.format(playerMgr.souls[self.id].star),false)

        print("ghkkkkkkkkkkkkkkkkkkkkkkk",playerMgr.souls[self.id].star)

        --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_BANNER,self.id))
        self.head_girl01_11:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_BANNER,self.id))

        self:runAnimation("1")
    end


end

function GirlsCellNode:setInTeam()
    self.bd_chuzhan_1:setVisible(true)
end

function GirlsCellNode:setOutTeam()
    self.bd_chuzhan_1:setVisible(false)
end




function GirlsCellNode:changeSelected()
    --print("换状态换状态")
    self:runAnimation("2")
end


function GirlsCellNode:changeNormal()
    self:runAnimation("1")
end



return GirlsCellNode

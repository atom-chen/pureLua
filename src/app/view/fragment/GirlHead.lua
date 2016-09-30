local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("..controls.CocostudioNode")
--single
local resMgr            = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()

local GirlHead = class("GirlHead", AnimationNode)

GirlHead.Type = {
    -- NORMAL = "nodes/email/email.csb",
    NORMAL = "nodes/icon_girlshead.csb",
    SMALL = "nodes/icon_girlsheadS.csb"
}

function GirlHead.create(params)
    return GirlHead.new({csbName = params.type, pb = params.pb})
end

function GirlHead:ctor(params)
    GirlHead.super.ctor(self,params)
    self:enableNodeEvents()

    self:mapUiElements({"energyNode","energyText","energyLoadingBar","headTypeNode","head_girl_sprite"})

    self.pb = params.pb
end

function GirlHead:refresh(pb)
    self.pb = pb or self.pb

    local function _wirteEnergy(pb)
        self.energyNode:show()
        self.energyText:show()
        self.energyLoadingBar:show()
        self.energyText:setString(string.format("%d/%d",pb.currentEnergy, pb.info.maxEnergy))
        self.energyLoadingBar:setPercent(pb.currentEnergy*100/pb.info.maxEnergy)
    end

    local function _writeIconTexture(class_id)
        --头像图标
        self.head_girl_sprite:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_HEAD,class_id))
    end

    local function _wirteStar(star)
        --星级品质
        self:runAnimation(string.format(star))
    end

    local function _wirteType(info)
         --类型
         self.headTypeNode:show()
         self.headTypeNode:runAnimation(string.format(info.type..info.color))
    end

    -- dump(self.pb)
    if not self.pb then
        return
    end
    if self.pb.currentEnergy and self.pb.info then
        _wirteEnergy(self.pb)
    end

    if self.pb.class_id then
        _writeIconTexture(self.pb.class_id)
    end

    if self.pb.star then
        _wirteStar(self.pb.star)
    end

    if self.pb.info then
        _wirteType(self.pb.info)
    end

end




return GirlHead

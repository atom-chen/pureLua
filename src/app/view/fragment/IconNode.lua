local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("..controls.CocostudioNode")

-- singleton
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()

local IconNode = class("IconNode", AnimationNode)

IconNode.csb = "nodes/icon_equip.csb"

function IconNode.create(param)
    return IconNode.new({csbName = IconNode.csb, data = param.data})
end

function IconNode.seek(parentNode, nodeName, data)
    return IconNode.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        csbName    = IconNode.csb,
        data       = data
    })
end

function IconNode:ctor(params)
     IconNode.super.ctor(self,params)
     self:enableNodeEvents()

     self.data = params.data

     self:mapUiElements({"itemIconSprite"})

end

function IconNode:refresh(data)
    self.data = data or self.data
    self.data = resMgr:getItemData(self.data)

    local function _writeIcon(path)
        self.itemIconSprite:setTexture(path)
    end

    local function _writeQuality(quality)
        if quality >= 0 and quality <= 5 then
            self:runAnimation(quality)
        else
            self:runAnimation("item")
        end
    end

    if self.data then
        if self.data.path then
            _writeIcon(self.data.path)
        end

        if self.data.quality then
            _writeQuality(self.data.quality)
        end
    end
end


return IconNode

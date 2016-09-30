local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")
local TextButton       = import("...fragment.TextButton")


local HeroEquipment = class("HeroEquipment",AnimationNode)


function HeroEquipment.create(callback)
    return HeroEquipment.new({
        callback   = callback,
        csbName = "nodes/heroEquitment.csb"
        })
end

function HeroEquipment.seek(parentNode,nodeName, callback)
    return HeroEquipment.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        callback   = callback,
        csbName    = "nodes/heroEquitment.csb"
    })
end

HeroEquipment.Events = table.enumTable
{
    -- 确定点击事件
    "ON_BUTTON_CONFIRM",
    -- 取消
    "ON_BUTTON_CANCEL"
}


--[[
params.parentNode
params.nodeName
params.callback
]]
function HeroEquipment:ctor(params)
    HeroEquipment.super.ctor(self,params)
    self:enableNodeEvents()

    self.cb = params.callback

    self:mapUiElements({"listview","confirmNode","cancelNode","cancelButton","confirmButton"})
   -- self:mapUiElement("cancelNode", function () return TextButton.seek(TextButton.TYPES.RED_NORMAL, self, "cancelButton") end)

    --self:mapUiElement("confirmNode", function () return TextButton.seek(TextButton.TYPES.BLUE_NORMAL, self, "confirmButton") end)
    self.confirmButtonText = AnimationNode.seek(self.confirmNode, "text")
    self.cancelButtonText  = AnimationNode.seek(self.cancelNode, "text")
end

function HeroEquipment:onEnter(  )
    HeroEquipment.super.onEnter(self);

    for i=1,10 do
        local event_banner = AnimationNode.load("nodes/hero/list_equip.csb")
        local custom_item = ccui.Layout:create()
        custom_item:setContentSize(cc.size( Helpers:getCascadeBoundingBox(event_banner).width, Helpers:getCascadeBoundingBox(event_banner).height))
        event_banner:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
        custom_item:addChild(event_banner)

        self.listview:pushBackCustomItem(custom_item)
    end

    self.confirmButton:onClicked(function (  )
        self.cb(HeroEquipment.Events.ON_BUTTON_CONFIRM)
    end)
    self.cancelButton:onClicked(function (  )
        self.cb(HeroEquipment.Events.ON_BUTTON_CANCEL)
    end)

    self.confirmButtonText:setString( Strings.CONFIRM )
    self.cancelButtonText:setString( Strings.CANCEL )
end




return HeroEquipment

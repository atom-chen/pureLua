local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")


local HeroShow = class("HeroShow",AnimationNode)


function HeroShow.create(callback)
    return HeroShow.new({
        callback    = callback,
        csbName     = "nodes/heroMain.csb"
        })
end

function HeroShow.seek( parentNode, nodeName, callback)
    return HeroShow.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        callback   = callback,
        csbName    = "nodes/heroMain.csb"
    })
end

HeroShow.Events = table.enumTable
{
    -- 装备点击事件
    "ON_BUTTON_EQUIP"
}

--[[
params.parentNode
params.nodeName
params.callback 所有事件从这里出去
]]
function HeroShow:ctor(params)
    HeroShow.super.ctor(self,params)
    self:enableNodeEvents()

    self.cb = params.callback
    self:mapUiElements({"equip_1", "equip_2","equip_3","equip_4","equip_5","equip_6"})
    
end

function HeroShow:onEnter(  )

    for i=1,6 do
        Helpers:seekNodeByName(self["equip_" .. i], "button"):setTag(i)
        self["equip_" .. i]:onButtonClicked("button", function ( event )
            -- 全部熄灭
            for i=1,6 do
                self["equip_" .. i]:runAnimation("normal", false)
            end
            -- 选中
            self["equip_" .. event.target:getTag()]:runAnimation("select", false)
            -- 传事件
            self.cb(HeroShow.Events.ON_BUTTON_EQUIP, event.target:getTag())
        end)
    end
    
end


function HeroShow:refresh(params)


    local function _withId(id)

    end

    if params.id then
        _withId(params.id)
    else
        printError("Must have id or classId!")
    end
end




return HeroShow

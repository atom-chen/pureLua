local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")


local HeroInfo = class("HeroInfo",AnimationNode)



function HeroInfo.create(callback)
    return HeroInfo.new({
        callback   = callback,
        csbName = "nodes/heroAttribute.csb"
        })
end

function HeroInfo.seek(parentNode,nodeName, callback)
    return HeroInfo.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        callback   = callback,
        csbName    = "nodes/heroAttribute.csb"
    })
end

function HeroInfo:ctor(params)
    HeroInfo.super.ctor(self,params)
    self:enableNodeEvents();

    self.cb = params.callback

end

function HeroInfo:onEnter()

end

function HeroInfo:refresh(params)


    local function _withId(id)

    end

    if params.id then
        _withId(params.id)
    else
        printError("Must have id or classId!")
    end
end




return HeroInfo

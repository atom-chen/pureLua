local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("..controls.CocostudioNode")


local StatesButton = class("StatesButton",AnimationNode)


function StatesButton.seek( parentNode, nodeName, state, buttonName )
    return StatesButton.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        state      = state,
        buttonName = buttonName
    })
end

--[[
params.parentNode
params.nodeName
]]
function StatesButton:ctor(params)
    StatesButton.super.ctor(self,params)
    self:enableNodeEvents();
    -- dump(params)
    self.buttonName = params.buttonName or "button"
    self:mapUiElements({self.buttonName})
    if params.state then
        self:setState(params.state)
    end
end

function StatesButton:onClicked( callback )
    self[self.buttonName]:onClicked(callback)
end

function StatesButton:setState( state )
    self:runAnimation(state)
end

function StatesButton:setButtonTag(tag)
    self[self.buttonName]:setTag(tag)
end

return StatesButton

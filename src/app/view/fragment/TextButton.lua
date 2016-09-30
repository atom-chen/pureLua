local CURRENT_MODULE_NAME = ...

local StatesButton = import(".StatesButton")


local TextButton = class("TextButton",StatesButton)


TextButton.TYPES =
{
    BLUE_NORMAL = "nodes/btn_blue00.csb",
    BLUE_LARGE = "nodes/btn_blue01.csb",
    RED_NORMAL = "nodes/btn_red00.csb",
}

function TextButton.create( type )
    return TextButton.new({
        csbName = type
        })
end

function TextButton.seek( type, parentNode, nodeName )
    return TextButton.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        csbName    = type
    })
end

--[[
params.parentNode
params.nodeName
]]
function TextButton:ctor(params)
    TextButton.super.ctor(self,params)
    self:enableNodeEvents();

    self:mapUiElements({"text"})
end

function TextButton:setString( str )
    self.text:setString(str);
end




return TextButton

local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("..controls.CocostudioNode")


local ImageButton = class("ImageButton", AnimationNode)

ImageButton.TYPES =
{
	OPERATION 	= "nodes/home/home_btnS.csb",
	SYSTEM		= "nodes/home/home_btn.csb"       
}

function ImageButton.create( type, state )
    return ImageButton.new({
            csbName = type,
            state 	= state
    })
end

function ImageButton.seek( parentNode, nodeName, type, state)
    return ImageButton.new({
            parentNode 	= parentNode,
            nodeName	= nodeName,
            csbName		= type,
            state 		= state
    })
end

function ImageButton:ctor(params)
	ImageButton.super.ctor(self, params)

    self:mapUiElement("active")
    self:setState(params.state)
    self:setActive( false )
   
end

function ImageButton:setState( state )
    self.state = state
    self:mapUiElement(state)
   
	self:runAnimation( state )
   
end

function ImageButton:setActive( bActive )
	self.active:setVisible(bActive)
end

function ImageButton:onClicked( callback )
    self[self.state]:onClicked( callback )
end

return ImageButton

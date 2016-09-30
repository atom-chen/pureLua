local CURRENT_MODULE_NAME = ...

local AnimationNode       = import("..controls.CocostudioNode")

local ArrowNode  = class("ArrowNode", display.newNode)



function ArrowNode:ctor(params)

	self:enableNodeEvents()
    
	self.ArrowNode = AnimationNode.new({csbName = "nodes/battle/warning.csb"}):addTo(self)
end


function ArrowNode:onEnter()
	print("进入 onEnter")
   	self.ArrowNode:runAnimation("loop",true)
end


return ArrowNode
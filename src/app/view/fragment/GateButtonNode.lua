local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("..controls.CocostudioNode")


local GateButtonNode = class("GateButtonNode", AnimationNode)



function GateButtonNode.create(param)

    -- dump(param)

    -- print("create GateButton")

    return GateButtonNode.new({csbName = "nodes/quest/new_point.csb",data = param})

end



function GateButtonNode:ctor(params)

     self.data = params.data
     self.type = params.data.type

     self.gateId = params.data.gateId

     GateButtonNode.super.ctor(self,params)
     self:enableNodeEvents()
     self:mapUiElements({"rankNode","arrowNode","gateButton","newNode","gateTypeNode"})

     self:runAnimation("old",false)

     self.gateTypeNode:runAnimation(string.format(self.data.type))
end


function GateButtonNode:showArrow()
      self.arrowNode:runAnimation("loop",true)
end

function GateButtonNode:hideArrow()
      self.arrowNode:setVisible(false)
end

function GateButtonNode:setRank(state)
    if state == 0 then
        self.rankNode:setVisible(false)
        return
    end
    -- print(state)
    self.rankNode:runAnimation(state)
    --关卡类型为剧情的话隐藏rankNode
    if self.type==1 then
       self.rankNode:setVisible(false)
    end
    -- print("end")
end

function GateButtonNode:playNewParticle()

      self.newParticleNode:setVisible(true)
end

return GateButtonNode

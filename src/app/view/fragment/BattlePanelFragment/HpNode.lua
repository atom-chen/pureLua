local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")


local HpNode = class("HpNode",AnimationNode)


function HpNode.create(params)
    return HpNode.new({csbName = "nodes/battle/enemyHp.csb",obj = params.obj})
end


function HpNode:ctor(params)

    HpNode.super.ctor(self,params)
    self:enableNodeEvents()

    self.obj = params.obj
    self.barMax = self.obj.info.hp
    self:mapUiElements({"LoadingBar_1","LoadingBar_1_0"})

end


function HpNode:onEnter()

    self:onUpdate(handler(self,self.updateBar))

end


function HpNode:updateBar(dt)

    if self.obj.curHp<=0 then
        self:removeFromParent()
        return
    end
    local percent = self.obj.curHp*1.0/self.barMax
    self.LoadingBar_1:setPercent(percent*100)
    self.LoadingBar_1_0:setPercent(percent*100)
    if percent<0.3 then
        self.LoadingBar_1:setVisible(true)
        self.LoadingBar_1_0:setVisible(false)
    else
        self.LoadingBar_1:setVisible(false)
        self.LoadingBar_1_0:setVisible(true)
    end
end

return HpNode
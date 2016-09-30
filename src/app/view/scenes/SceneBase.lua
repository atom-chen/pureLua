
local CURRENT_MODULE_NAME = ...

local SceneBase = class("SceneBase",cc.load("mvc").ViewBase)

function SceneBase:createResoueceNode(resourceFilename)
    if self.node then
        self.node:removeSelf()
        self.node = nil
    end
    self.node = import("..controls.CocostudioNode", CURRENT_MODULE_NAME).load(resourceFilename)
    assert(self.node, string.format("ViewBase:createResoueceNode() - load resouce CocostudioNode from file \"%s\" failed", resourceFilename))
    self:addChild(self.node)
end

return SceneBase
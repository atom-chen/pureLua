local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local LiveNode              = import("..controls.LiveNode", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager        = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local UUPanel = class("UUPanel", PanelBase)


function UUPanel.create()
    return UUPanel.new({ csbName = "effects/live2d/UU/Layer.csb"})
end

function UUPanel:ctor(params)
    UUPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"UU","CZ"})

    self.live2d = LiveNode.load("live2d/live_uu/uu_00.model.json"):addTo(self,1)
    self.CZ:setLocalZOrder(20)
    --self.quanNode:setLocalZOrder(30)
    self.live2d:setPosition(200,0)
end

function UUPanel:onEnter()
    UUPanel.super.onEnter(self)
    self:onUpdate(handler(self, self.update))

    musicManager:play(girl.BGM.UU)

    girl.addTouchEventListener(self,{
                               swallow = true,
                               onBegan = function()
                                 self.live2d:removeSelf()
                                 musicManager:play(girl.BGM.HOME)
                                 self:close("UU")
                                
                                 return true
                               end
    })









    self.live2d:runRandomMotion("in", 2)
    self:runAnimation(self.DefaultAnimation, false, function()
        musicManager:play(girl.BGM.HOME)
        self:close("UU")
    end)
end

function UUPanel:update()
    -- print("update")
    self.live2d:setPosition(self.UU:getPositionX(),self.UU:getPositionY())
    self.live2d:setSacle(self.UU:getScale()*1.05)
    -- dump(self.UU:getPosition())
    -- dump(self.UU:getScale())
end

return UUPanel

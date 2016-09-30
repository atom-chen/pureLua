local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()

local DeedResultTenPanel = class("DeedResultTenPanel", PanelBase)

function DeedResultTenPanel.create()
  return DeedResultTenPanel.new({ csbName = "layers/draw/get10.csb"})
end


function DeedResultTenPanel:ctor(params)
  DeedResultTenPanel.super.ctor(self, params)
  self:enableNodeEvents()

end

function DeedResultTenPanel:onEnter()

  DeedResultTenPanel.super.onEnter(self)
  self:runAnimation("10")
  girl.addTouchEventListener(self, {
                               swallow = true,
                               onBegan = function()
                                 self:close()
                               end
  })
end


return DeedResultTenPanel

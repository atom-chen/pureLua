local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()

local BossComePanel = class("BossComePanel", PanelBase)

function BossComePanel.create()
  return BossComePanel.new({ csbName = "layers/battle/energy_burst.csb"})
end

function BossComePanel:ctor(params)
  BossComePanel.super.ctor(self, params)
  self:enableNodeEvents()

end

function BossComePanel:onEnter()
	BossComePanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})
    self:runAnimation("in",false,function()
    self:close("boss")
    --self:resumeAll()

    end)

end

return BossComePanel

local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)


-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()

local SceneBgPanel = class("SceneBgPanel", PanelBase)


function SceneBgPanel.create()
  return SceneBgPanel.new({ csbName = "layers/bg/Bg01.csb"})
end

function SceneBgPanel:ctor(params)

  SceneBgPanel.super.ctor(self, params)
  self:enableNodeEvents()

   self:mapUiElements({"Image_1"})
 

end

function SceneBgPanel:onEnter()

   SceneBgPanel.super.onEnter(self)

   self.Image_1:setScale9Enabled(true)

   self:runAnimation("loop", true)


   
   
end

return SceneBgPanel
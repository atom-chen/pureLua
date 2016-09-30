local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()

local LogoPanel = class("LogoPanel", PanelBase)


function LogoPanel.create()
    return LogoPanel.new({ csbName = "layers/main1.csb"})
end

function LogoPanel:ctor(params)
    LogoPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"Button_12"})

    self.inDone = false


end

function LogoPanel:onEnter()

    LogoPanel.super.onEnter(self)

    self:runAnimation( "in",false,function()
    	 self.inDone = true
    	 self.Button_12:setVisible(true)
         -- logo:close()
         -- self:getApp():enterScene("NewUpdateScene")
    end)

    self.Button_12:onClicked(function()
    	print("12324322")
       if self.inDone == false then
       	  return
       else
       	  self:close("logo")
       end
    end)

end

return LogoPanel

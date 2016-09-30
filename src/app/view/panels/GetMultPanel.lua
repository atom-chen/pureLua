local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local SmallIconNode = import("..fragment.SmallIconNode",CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local infoMgr       = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()

local GetMultPanel  = class("GetMultPanel", PanelBase)


function GetMultPanel.create(params)
    return GetMultPanel.new({ csbName = "layers/draw/get5.csb",info = params.info})
end

function GetMultPanel:ctor(params)
    GetMultPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"mainNode","gotNode1","gotNode2",
                        "gotNode3","gotNode4","gotNode5"})
    self.info = params.info

end

function GetMultPanel:onEnter()
    GetMultPanel.super.onEnter(self)

    self:runAnimation("10")

    self.mainNode:runAnimation(string.format(#self.info),false)

    for i=1,#self.info do
        self["node"..i] = SmallIconNode.create({info = self.info[i]}):addTo(self["gotNode"..i])
    end

    girl.addTouchEventListener(self,{
        onBegan = function(touch,event)
            self:close()
            return true
        end
    })
end

return GetMultPanel

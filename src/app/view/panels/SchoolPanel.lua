local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local BgImageNode   = import("..fragment.BgImageNode",CURRENT_MODULE_NAME)
-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()

local SchoolPanel = class("SchoolPanel", PanelBase)


function SchoolPanel.create()
    return SchoolPanel.new({ csbName = "layers/school.csb"})
end

function SchoolPanel:ctor(params)
    SchoolPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self.elements = {}

    local elements = {
        { key = "hero", panel = "HeroPanel" },
        { key = "spa", panel = "RecoveryPanel" },
        { key = "item", panel = "NULL" },
        { key = "soul", panel = "SoulsPanel" },
        { key = "atk", panel = "QuestChapterPanel" },
        { key = "shop", panel = "NULL" }}

    for _,v in ipairs(elements) do
        local element = v
        self.elements[v.key] = element
    end

    self:mapUiElements({"schoolBackNode"})

end

function SchoolPanel:onEnter()
    SchoolPanel.super.onEnter(self)

    girl.addTouchEventListener(self, {swallow = true})
    self:runAnimation("in")
    -- MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)

    self.bgImage = BgImageNode.seek(self,"bgImage",109)


    for _,v in pairs(self.elements) do
        self:onButtonClicked(v.key.."Button", function()
            if v.panel == "NULL" then
                panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = Strings.NULL_PANEL}):addTo(self)
            else
                self:exit(function()
                    panelFactory:createPanel( panelFactory.Panels[v.panel], handler(self,self.onPanelClosed)):addTo(self)
                end)
            end
        end)
    end

    self.schoolBackNode:onButtonClicked("mapBackButton",function()
        self:close("SchoolPanel")
    end)
end

function SchoolPanel:onExit()
    SchoolPanel.super.onExit(self,"SchoolPanel")
end

function SchoolPanel:onPanelClosed(reason)
    self:runAnimation("in")
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
end

function SchoolPanel:exit(callback)
    self:runAnimation("out", false, callback)
end


return SchoolPanel

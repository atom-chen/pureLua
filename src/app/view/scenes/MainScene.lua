local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local panelFactory = import("..controls.PanelFactory"):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()

local MainScene = class("MainScene", import(".SceneBase", CURRENT_MODULE_NAME))

-- MainScene.RESOURCE_FILENAME = "scenes/Main.csb"


function MainScene:onCreate()

end


function MainScene:onEnter()

	local function onPanelClosed(reason)
        if reason == "logo" then
            self:getApp():enterScene("NewUpdateScene")
        end
    end

    local logo = panelFactory:createPanel(panelFactory.Panels.LogoPanel, onPanelClosed):addTo(self)

    -- logo:runAnimation( "in",false,function()
    --     logo:close()
    --     self:getApp():enterScene("NewUpdateScene")
    -- end)

   --local help = panelFactory:createPanel(panelFactory.Panels.HelpInfoPanel, onPanelClosed):addTo(self)

end

return MainScene

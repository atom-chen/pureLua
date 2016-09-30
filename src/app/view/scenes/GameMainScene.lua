local CURRENT_MODULE_NAME = ...

require "app.UpdateFunctions"

-- classes

-- singleton
local panelFactory = import("..controls.PanelFactory"):getInstance()
local playerMgr     = import("...data.PlayerDataManager"):getInstance()


local GameMainScene = class("GameMainScene", import(".SceneBase", CURRENT_MODULE_NAME))

-- GameMainScene.RESOURCE_FILENAME = "scenes/GameMain.csb"

function GameMainScene:onCreate()

    local function onPanelClosed(reason)
        if reason == "sign" then
            panelFactory:createPanel(panelFactory.Panels.HomePanel):addTo(self)
        end
    end

    panelFactory:createPanel(panelFactory.Panels.HomeBgPanel):addTo(self)

    if playerMgr.firstBlood then
        panelFactory:createPanel(panelFactory.Panels.SignPanel, onPanelClosed):addTo(self)
    else
        panelFactory:createPanel(panelFactory.Panels.HomePanel):addTo(self)
    end

    panelFactory:createPanel( panelFactory.Panels.TopPanel):addTo(self,100)

    panelFactory:createPanel( panelFactory.Panels.BarragePanel):addTo(self, 10000)
end

function GameMainScene:onEnter()
end

function GameMainScene:onExit()

end

return GameMainScene

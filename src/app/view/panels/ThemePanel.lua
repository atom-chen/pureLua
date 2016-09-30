local CURRENT_MODULE_NAME = ...

-- classes
local PanelBase    = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local LiveNode     = import("..controls.LiveNode", CURRENT_MODULE_NAME)

-- singleton
local panelFactory = import("..controls.PanelFactory"):getInstance()
local musicMgr     = import("..controls.MusicManager"):getInstance()
local playerMgr    = import("...data.PlayerDataManager"):getInstance()
local resMgr       = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()


local ThemePanel = class("ThemePanel", PanelBase)

ThemePanel.temp_x = 800
ThemePanel.temp_y = -160

function ThemePanel.create()
    return ThemePanel.new({})
end

function ThemePanel:ctor(params)
    ThemePanel.super.ctor(self,params)
    self:enableNodeEvents()

     self.theme =  panelFactory:createPanel(panelFactory.Panels.ThemeConsolePanel, onPanelClosed, { cb = handler(self, self.onThemeEvent)}):addTo(self, 30)

     local showSoul =  playerMgr.config.showSoul
     self.live2d = LiveNode.load(resMgr:getResPath(playerMgr.souls[showSoul].currentFashionClassId)):addTo(self, 20)
     local pos = girl.fixNodePosition(self.temp_x, self.temp_y)
     self.live2d:setPosition(pos.x, pos.y)
end

function ThemePanel:onEnter()
    ThemePanel.super.onEnter(self)
    self.theme:runAnimation("in")
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
end

function ThemePanel:onExit()
    ThemePanel.super.onExit(self)
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.HOME_BG_REFRESH)
end

function ThemePanel:onThemeEvent(event, params)
    print(event)
    if event == "show" then
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.HOME_BG_TRY, params)
    elseif event == "back" then
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.HOME_BG_REFRESH)
    elseif event == "use" then
        -- temp code
        for _,v in pairs(playerMgr.decorations) do
            if v.class_id == params.class_id then

                for _,k in pairs(playerMgr.decorations) do
                    if v.info.position == k.info.position then
                        k.state = "NORMAL"
                    end
                end

                v.state = "SELECTED"
            end
        end
        -- end
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.HOME_BG_REFRESH)

    end
end

return ThemePanel

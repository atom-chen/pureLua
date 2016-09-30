
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase              = import("...controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode          = import("...controls.CocostudioNode", CURRENT_MODULE_NAME)
local HomePanel              = import("...panels.HomePanel", CURRENT_MODULE_NAME)

-- singleton
local panelFactory           = import("...controls.PanelFactory", CURRENT_MODULE_NAME) :getInstance()
local musicManager           = import("...controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

--
-- 主界面
--
local HomeMorePanel = class("HomeMorePanel", PanelBase)

function HomeMorePanel.create(  )
    return HomeMorePanel.new({ csbName = "layers/more.csb" })
end

function HomeMorePanel:ctor(params)
    HomeMorePanel.super.ctor(self, params)
    self:enableNodeEvents()

    self.elements = {}

    local elements = {
        { key = "notice", panel = "NULL" },
        { key = "mail", panel = "MailPanel" },
        { key = "sign", panel = "SignPanel" },
        { key = "shop", panel = "NULL" },
        { key = "bag", panel = "BagPanel" },
        { key = "friend", panel = "NULL" },
        { key = "book", panel = "NULL" },
        { key = "user", panel = "NULL" },
        { key = "setting", panel = "NULL" },
        { key = "help", panel = "HelpInfoPanel" },
        { key = "back", panel = "NULL" }}

    for _,v in ipairs(elements) do
        local element = v
        element.root = self:seek(v.key.."Node")
        element.node = element.root:seek("nNode")
        element.node:runAnimation(v.key)
        element.button = element.root:seek("button")
        element.active = element.root:seek("active")
        self.elements[v.key] = element
    end

end

function HomeMorePanel:onEnter( )
    HomeMorePanel.super.onEnter(self)

    girl.addTouchEventListener(self,{swallow = true})
    self:runAnimation("in")

    self:onButtonClicked("mapBackButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self:runAnimation("out", false, function()
            self:close()
        end)
    end)

    for _,v in pairs(self.elements) do
        v.button:onClicked(function()
            musicManager:play(girl.UiMusicId.BUTTON_CLICK)
            if v.panel == "NULL" then
                panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = Strings.NULL_PANEL}):addTo(self)
            else
                self:exit(function()
                    panelFactory:createPanel( panelFactory.Panels[v.panel], handler(self,self.onPanelClosed)):addTo(self,HomePanel.Z_NORMAL,HomePanel.TAG_REMOVED)
                end)
            end
        end)
    end

end

function HomeMorePanel:onExit()
    HomeMorePanel.super.onExit(self, "HomeMorePanel")
end

function HomeMorePanel:exit(func)
    self:runAnimation("out", false, function()
        if func then func() end
    end)
end

function HomeMorePanel:onPanelClosed(reason)
    self:runAnimation("in")
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT,{hide = true})
    -- self.homePanel:refresh()
end

return HomeMorePanel

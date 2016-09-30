local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)


-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr  = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resMgr  = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()

local HomeBgPanel = class("HomeBgPanel", PanelBase)


function HomeBgPanel.create()
  return HomeBgPanel.new({ csbName = "layers/bg/GameMainBg.csb"})
end

HomeBgPanel.DecorationType = {
    "windows",
    "desk",
    "cabinet",
    "bed",
    "wallpaper",
    "floor",
    "carpet",
    "lamp",
    "decorate2",
    "decorate1"
}

function HomeBgPanel:ctor(params)

    HomeBgPanel.super.ctor(self, params)
    self:enableNodeEvents()

    for _,v in ipairs(self.DecorationType) do
        -- fuck
        if  v ==  "wallpaper" or
            v ==  "floor" then
            for i=1,2 do
                self:mapUiElement(v..i)
            end
        else
            self:mapUiElement(v)
        end
    end

end

function HomeBgPanel:onEnter()
   HomeBgPanel.super.onEnter(self)

   self:refresh()
   MessageManager:addMessage(girl.MessageLayer.UI, girl.UiMessage.HOME_BG_REFRESH, handler(self, self.refresh))
   MessageManager:addMessage(girl.MessageLayer.UI, girl.UiMessage.HOME_BG_TRY, handler(self, self.try))
end

function HomeBgPanel:onExit()
    HomeBgPanel.super.onExit(self)
    MessageManager.removeMessageByLayerTarget(girl.MessageLayer.UI, self)
end

function HomeBgPanel:refresh()
    for _,v in pairs(playerMgr.decorations) do
        if v.state == "SELECTED" then
            -- fuck
            if self.DecorationType[v.info.position] == "wallpaper" or
                self.DecorationType[v.info.position] == "floor" then
                for i=1,2 do
                    self[self.DecorationType[v.info.position]..i]:setTexture(resMgr:getIconPath(resMgr.IconType.THEME_USE_FUCK, v.class_id, i))
                end
            else
                self[self.DecorationType[v.info.position]]:setTexture(resMgr:getIconPath(resMgr.IconType.THEME_USE, v.class_id))
            end
        end
    end
end

function HomeBgPanel:try(body, layer, msg, pb)
    if pb then
        -- fuck
        if self.DecorationType[pb.info.position] == "wallpaper" or
            self.DecorationType[pb.info.position] == "floor" then
                for i=1,2 do
                    self[self.DecorationType[pb.info.position]..i]:setTexture(resMgr:getIconPath(resMgr.IconType.THEME_USE_FUCK, pb.class_id, i))
                end
        else
            self[self.DecorationType[pb.info.position]]:setTexture(resMgr:getIconPath(resMgr.IconType.THEME_USE, pb.class_id))
        end
    end
end

return HomeBgPanel

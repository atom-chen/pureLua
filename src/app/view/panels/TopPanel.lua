
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase             = import("..controls.PanelBase")
local AnimationNode         = import("..controls.CocostudioNode")

-- singleton
local panelFactory          = import("..controls.PanelFactory"):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local playerMgr             = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoManager         = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
--
-- 武将详细
--
local TopPanel = class("TopPanel", PanelBase)

function TopPanel.create( params )
    return TopPanel.new({ csbName = "layers/Top.csb" })
end

function TopPanel:ctor(params)
    TopPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"goldText","diamondText","ticketText","homeButton","homeButtonNode","topBg",
                        "playerLvText","playerLoadingBar","playerPerText"})
    self:addSendMessage()

    self.bShow = false

    self.heroBaseInfo  = infoManager:findInfo("roles","class_id",playerMgr.heros[2].level)

    if playerMgr.heros[2].level == 80 then
       self.percent = 0
    else
      self.upLevelExp = self.heroBaseInfo.upLevelExp
      self.percent = math.floor(playerMgr.heros[2].exp/self.upLevelExp*100)
     
    end
   
  
end

function TopPanel:onEnter( )
    TopPanel.super.onEnter(self)
    self:onButtonClicked("homeButton", function()
        print("----click-homeButton-----")
        girl.gc()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.HOME_CLEAN_UP)
    end)
    self:schedule(self,handler(self, self.refresh),0.2)
end

function TopPanel:refresh()
    self.goldText:setString(playerMgr.status.gold)
    self.diamondText:setString(playerMgr.status.diamond)
    self.ticketText:setString(playerMgr.status.ticket)
    self.playerLvText:setString(playerMgr.heros[2].level)
    self.playerLoadingBar:setPercent(self.percent)
    self.playerPerText:setString(string.format("%d%%",self.percent))
end

function TopPanel:addSendMessage()
    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.TOP_IN,handler(self, self.onTopIn))
    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.TOP_OUT,handler(self, self.onTopOut))
end

function TopPanel:onTopIn(body,layer,msg,data)
    -- if self.bShow == true then
    --     return
    -- end
    self.homeButtonNode:show()
    self.topBg:show()

    if data then
        if data.hide then
            self.homeButtonNode:hide()
            self.topBg:hide()
        end
        self:runAnimation("in", data.loop or false,data.callback)
    else
        self:runAnimation("in")
    end

    self.bShow = true
end

function TopPanel:onTopOut(body,layer,msg,data)
    -- if self.bShow == false then
    --     return
    -- end

    self.homeButtonNode:show()
    self.topBg:show()

    if data then
        if data.hide then
            -- print("onTopOut  hide --------")
            self.homeButtonNode:hide()
            self.topBg:hide()
        end
        self:runAnimation("out", data.loop or false,data.callback)
    else
        self:runAnimation("out")
    end
    self.bShow = false
end

return TopPanel

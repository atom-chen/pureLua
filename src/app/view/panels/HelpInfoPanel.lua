
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase             = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode         = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local HeroBanner            = import("..fragment.HeroBanner", CURRENT_MODULE_NAME)
-- singleton
local panelFactory          = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr             = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoManager           = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local resMgr                = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
--
-- 武将详细
--
local HelpInfoPanel = class("HelpInfoPanel", PanelBase)

function HelpInfoPanel.create()
    return HelpInfoPanel.new({ csbName = "layers/help.csb" })
end


function HelpInfoPanel:ctor(params)
    HelpInfoPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"pageView","left","right","pageCountLabel","mapBackButton"})

    self.rightArrowBtn = AnimationNode.seek(self["right"],"arrowButton")
    self.leftArrowBtn  = AnimationNode.seek(self["left"],"arrowButton")

	  self.whichPage = 1

end

function HelpInfoPanel:onEnter( )

	print("HelpInfoPanel:onEnter")
	local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
	bg:setLocalZOrder(-100)

	HelpInfoPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})

  self:runAnimation("in", false,function()
      self.left:runAnimation("loop", true)
      self.right:runAnimation("loop", true)

  end)

  self:refreshPage(1)



 
	
    for i = 1,16 do
        local layout = ccui.Layout:create()
        layout:setContentSize(cc.size(display.width, 550))
        -- local page1 = HeroBanner.create({ id = 2}):addTo(layout)
        -- page1:setPosition(cc.p(layout:getContentSize().width/2, layout:getContentSize().height/2))

        local listView = ccui.ListView:create()
        -- set list view ex direction
        listView:setDirection(ccui.ScrollViewDir.vertical)
        listView:setBounceEnabled(true)
        --listView:setBackGroundImage("textures/background/questMap/chapterMap01_03.png")
        --listView:setBackGroundImageScale9Enabled(true)
        listView:setAnchorPoint(0.5,0.5)
        listView:setContentSize(cc.size(self.pageView:getContentSize().width, self.pageView:getContentSize().height))
        listView:setPosition(cc.p(layout:getContentSize().width/2, layout:getContentSize().height/2))
        
        layout:addChild(listView)

        local imageView = ccui.ImageView:create(resMgr:getIconPath(resMgr.IconType.HELP,i))
        imageView:setTouchEnabled(true)
        imageView:setScale9Enabled(false)

        imageView:setAnchorPoint(1,1)
        imageView:setPosition(cc.p(0, layout:getContentSize().height))
     
        listView:pushBackCustomItem(imageView)
        self.pageView:addPage(layout)
    end

    local function pageViewEvent(sender, eventType)
        if eventType == ccui.PageViewEventType.turning then
            local pageView = sender
            local pageInfo = string.format("%d" , pageView:getCurPageIndex() + 1)
            self.whichPage = pageView:getCurPageIndex() + 1
            -- print("pagepagepage",self.whichPage)
            musicManager:play(girl.UiMusicId.PAGE_SLIDE)
            --self:pNodeChange(self.whichPage)
            self:refreshPage(self.whichPage)
            
        end
    end 

    self.pageView:addEventListener(pageViewEvent)


    self.rightArrowBtn:onClicked(function()
      musicManager:play(girl.UiMusicId.CLICK_BTN)
      -- print("1111111self.whichPart",self.whichPage)
      self.pageView:scrollToPage(self.whichPage+1-1)
      self.whichPage =  self.whichPage + 1
      self:refreshPage(self.whichPage)
      -- print("2222222self.whichPart",self.whichPage)
    end)

    self.leftArrowBtn:onClicked(function()
      musicManager:play(girl.UiMusicId.CLICK_BTN)
      -- print("1111111self.whichPart",self.whichPage)
      self.pageView:scrollToPage(self.whichPage-1-1)
      self.whichPage =  self.whichPage - 1
      self:refreshPage(self.whichPage)
      -- print("2222222self.whichPart",self.whichPage)
    end)


    self.mapBackButton:onClicked(function()
        -- print("back")
        musicManager:play(girl.UiMusicId.CLICK_BTN)

        self:runAnimation("out",false,function()
           MessageManager.sendMessage(girl.MessageLayer.UI, girl.UiMessage.HOME_CLEAN_UP)
        end)
    end)




end

function HelpInfoPanel:refreshPage(pageIndex)

    self.left:setVisible(false)
    self.right:setVisible(false)
      if  pageIndex == 1 then
          self.right:setVisible(true)
      else
        if pageIndex ~= 16 then
           self.left:setVisible(true)
           self.right:setVisible(true)
        else
           self.left:setVisible(true)
        end
      end

    self.pageCountLabel:setString(string.format("%d/16",pageIndex))

end



return HelpInfoPanel

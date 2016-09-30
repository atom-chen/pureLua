
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase             = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode         = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local HeroShow              = import("..fragment.HeroPanelFragment.HeroShow", CURRENT_MODULE_NAME)
local HeroInfo              = import("..fragment.HeroPanelFragment.HeroInfo", CURRENT_MODULE_NAME)
local HeroBanner            = import("..fragment.HeroBanner", CURRENT_MODULE_NAME)
local Hero 					= import("..battle.Hero", CURRENT_MODULE_NAME)
-- singleton
local panelFactory          = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr             = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoManager           = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
--
-- 武将详细
--
local HeroPanel = class("HeroPanel", PanelBase)

function HeroPanel.create( id )
    return HeroPanel.new({ csbName = "layers/hero/hero.csb" }, id)
end


function HeroPanel:ctor(params, id)
    HeroPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self:mapUiElements({"pageView","leftArrowNode","rightArrowNode","pNode1","pNode2","pNode3","pNode4"})

    self.rightArrowBtn = AnimationNode.seek(self["rightArrowNode"],"arrowButton")
    self.leftArrowBtn  = AnimationNode.seek(self["leftArrowNode"],"arrowButton")
    self.whichPage = 1
end

function HeroPanel:onEnter( )

    print("HeroPanel:onEnter")
    local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
    bg:setLocalZOrder(-100)

    HeroPanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})

    self:runAnimation("in",false)
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)

    self.leftArrowNode:runAnimation("loop",true)
    self.rightArrowNode:runAnimation("loop", true)

    self:refreshArrowNode(1)
    self:pNodeChange(1) --进HERO界面默认显示第一个PAGE


    --for i = 1,1 do
    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(display.width, 464))
    local page1 = HeroBanner.create({ id = 2}):addTo(layout)
    page1:setPosition(cc.p(layout:getContentSize().width/2, layout:getContentSize().height/2))
    page1:runAnimation("in",false)
    self.pageView:addPage(layout)
   -- end

    local function pageViewEvent(sender, eventType)

        if eventType == ccui.PageViewEventType.turning then
            local pageView = sender
            local pageInfo = string.format("%d" , pageView:getCurPageIndex() + 1)
            if self.whichPage ~= pageView:getCurPageIndex() + 1 then
               musicManager:play(girl.UiMusicId.PAGE_SLIDE)
               print("不同才播放划动的声音")
            end
            self.whichPage = pageView:getCurPageIndex() + 1
            print("pagepagepage",self.whichPage)
            --musicManager:play(girl.UiMusicId.PAGE_SLIDE)
            self:pNodeChange(self.whichPage)
            self:refreshArrowNode(self.whichPage)
            -- if self.whichPage ==1 then
            -- 	self.pageNode1:runAnimation("on")
            -- 	self.pageNode2:runAnimation("off")
            -- else
            -- 	self.pageNode1:runAnimation("off")
            -- 	self.pageNode2:runAnimation("on")
            -- end
        end
    end 

    self.pageView:addEventListener(pageViewEvent)


    self.rightArrowBtn:onClicked(function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        print("1111111self.whichPart",self.whichPage)
        self.pageView:scrollToPage(self.whichPage+1-1)
        self.whichPage =  self.whichPage + 1
        self:refreshArrowNode(self.whichPage)
        print("2222222self.whichPart",self.whichPage)
    end)

    self.leftArrowBtn:onClicked(function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        print("1111111self.whichPart",self.whichPage)
        self.pageView:scrollToPage(self.whichPage-1-1)
        self.whichPage =  self.whichPage - 1
        self:refreshArrowNode(self.whichPage)
        print("2222222self.whichPart",self.whichPage)
    end)
end

function HeroPanel:refreshArrowNode(pageIndex)

    self.leftArrowNode:setVisible(false)
    self.rightArrowNode:setVisible(false)
  
end

function HeroPanel:pNodeChange(pageIndex)

    for i=1,4 do
        self["pNode"..i]:runAnimation("off", false)
    end

    self["pNode"..pageIndex]:runAnimation("on", false)


end



return HeroPanel

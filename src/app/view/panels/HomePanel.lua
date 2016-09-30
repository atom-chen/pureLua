
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase              = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode          = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local ImageButton 			 = import("..fragment.ImageButton", CURRENT_MODULE_NAME)
local LiveNode               = import("..controls.LiveNode", CURRENT_MODULE_NAME)

-- singleton
local panelFactory           = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager           = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local playerManager          = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resManager             = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr                = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()

--
-- 主界面
--
local HomePanel = class("HomePanel", PanelBase)

HomePanel.TAG 			 = 2000
HomePanel.TAG_REMOVED 	 = -2000
HomePanel.Z_NORMAL 	     = 100
HomePanel.BGM 	         = 5000000

function HomePanel.create(  )
    return HomePanel.new({ csbName = "layers/Home.csb" })
end

function HomePanel:ctor(params)
    HomePanel.super.ctor(self, params)
    self:enableNodeEvents()

    self.live2d = {}

    self.elements = {}

    local elements = {
        { key = "mail", panel = "MailPanel",sound = girl.UiMusicId.CLICK_BTN},
        { key = "help", panel = "HelpInfoPanel",sound = girl.UiMusicId.CLICK_BTN },
        { key = "mission", panel = "QuestChapterPanel",sound = girl.UiMusicId.HOME_ATTACK },
        { key = "soul", panel = "SoulsPanel" ,sound = girl.UiMusicId.CLICK_BTN},
        { key = "gacha", panel = "DeedPanel" ,sound = girl.UiMusicId.CLICK_BTN},
        { key = "theme", panel = "ThemePanel" ,sound = girl.UiMusicId.CLICK_BTN},
        { key = "school", panel = "SchoolPanel" ,sound = girl.UiMusicId.CLICK_BTN}}

    for _,v in ipairs(elements) do
        local element = v
        element.root = self:seek(v.key.."Node")
        element.node = element.root:seek("nNode")
        element.node:runAnimation(v.key)
        element.button = element.root:seek("button")
        element.active = element.root:seek("active")
        self.elements[v.key] = element
    end

    elements = {
        { key = "more", panel = "HomeMorePanel", tag = self.TAG,sound = girl.UiMusicId.CLICK_BTN },
        { key = "soulInfo", panel = "EduPanel",tag = self.TAG, params = {},sound = girl.UiMusicId.CLICK_BTN}
    }

    for _,v in ipairs(elements) do
        local element = v
        element.button = self:seek(v.key.."Button")
        self.elements[v.key] = element
    end

    self:mapUiElements({"girlNode"})

    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.HOME_CLEAN_UP,handler(self, self.cleanup))
end

-- 对应的表触摸位置数据
local TouchPos = {
    NORMAL = 0, -- 正常状态
    HEAD   = 1, -- 头部
    BODY   = 4, -- 身体
    CHEST  = 3, -- 胸部
    FACE   = 2 -- 脸
}

function HomePanel:onEnter( )
    HomePanel.super.onEnter(self)

    girl.addTouchEventListener(self,{swallow = true,
    onBegan = function(touch, event)
        return true
    end,
    onEnded = function(touch, event)
        if self.live2d.node ~= nil then
            local touchPos = touch:getLocation()
            local hit = self.live2d.node:hit(touchPos.x, touchPos.y)
            if hit ~= self.live2d.node.TouchEvent.NORMAL then
                local devType = infoMgr:findInfo("devExps", "class_id", self.pb.class_id*100+self.pb.loveLevel).devType
                local touchPos = TouchPos[table.keyof( self.live2d.node.TouchEvent, hit)]
                local actionTouch = infoMgr:findInfo("actionTouchs", "class_id", self.pb.class_id*100+touchPos*10+devType)
                -- dump(actionTouch)

                -- 运行动作
                local action = infoMgr:findInfo("actions", "class_id", actionTouch.actionId)
                self.live2d.node:runExpression(action.expName)
                self.live2d.node:runRandomMotion(action.actionName, 2)
                self.live2d.node:say(string.format("sound/live2d/mp3/%s.mp3", action.soundName), string.format("sound/live2d/txt/%s.txt",action.soundName), function()
                end)
            end
        end
    end})

    musicManager:play(self.BGM)
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN,{hide = true})
    self:runAnimation("in")

    for _,v in pairs(self.elements) do
        v.button:onClicked(function()
            if v.sound then
               musicManager:play(v.sound)
            end
            self:exit(function()
                panelFactory:createPanel( panelFactory.Panels[v.panel], handler(self,self.onPanelClosed), v.params):addTo(self, self.Z_NORMAL, v.tag or self.TAG_REMOVED)
            end)
        end)
    end
    self:refresh()
end

function HomePanel:refresh()
    local showSoul =  playerManager.config.showSoul

    self.live2d.class_id = showSoul
    self.pb = playerManager.souls[showSoul]
    self.elements["soulInfo"].params.id = showSoul

    -- 刷新各个激活
    if table.nums(playerManager.mails) > 0 then
        self.elements.mail.active:show()
    else
        self.elements.mail.active:hide()
    end

    -- 刷新live2d
    if self.live2d.node == nil then
        self.live2d.node = LiveNode.load(resManager:getResPath(playerManager.souls[showSoul].currentFashionClassId)):addTo(self)
        self.live2d.node:setPosition(self.girlNode:getPositionX(), self.girlNode:getPositionY())
    end

end

function HomePanel:exit(func)
    if self.live2d.node ~= nil then
        self.live2d.node:removeSelf()
        self.live2d.node = nil
    end

    self:runAnimation("out", false, function()
        if func then func() end
    end)
    -- print("------------HomePanel:exit------这里有个TopOut-------")
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT,{hide = true})
end

--移除所有的Layers
function HomePanel:cleanup()
	local function removeByTag(tag)
		local mb = Helpers:seekNodeByTag(self, tag)
		while nil ~= mb do
			mb:removeFromParent()
			mb = Helpers:seekNodeByTag(self, tag)
		end
	end
	removeByTag(HomePanel.TAG_REMOVED)
end

function HomePanel:onPanelClosed(reason)
    print("fun: HomePanel:onPanelClosed(reason)")
    self:runAnimation("in")
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN,{hide = true})
    -- if reason ~= "HomeMorePanel" then
        self:refresh()
    -- end
end

return HomePanel

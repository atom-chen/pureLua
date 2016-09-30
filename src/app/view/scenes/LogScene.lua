local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local panelFactory = import("..controls.PanelFactory"):getInstance()
local musicMgr     = import("..controls.MusicManager"):getInstance()
local playerMgr     = import("...data.PlayerDataManager"):getInstance()


local LogScene = class("LogScene", import(".SceneBase", CURRENT_MODULE_NAME))

-- LogScene.RESOURCE_FILENAME = "scenes/GameMain.csb"

function LogScene:onCreate()

end

function LogScene:onEnter()
    local layer = cc.Layer:create():addTo(self)
    self.missLabel = cc.Label:createWithTTF("miss", "fonts/STHeiti-Medium_1.ttf", 28)
    self.missLabel:setAnchorPoint(cc.p(0.5, 0.5))
    self.missLabel:setPosition(display.size.width / 2, display.size.height/2)
    layer:addChild(self.missLabel , 0)


    cc.SpriteFrameCache:getInstance():addSpriteFrames("studio/textures/plist/ui/talk_battle.plist")

    --self.buttonPath1 = "textures/ui/talk/bd_talkB.png"
    --self.buttonPath2 = "textures/ui/talk/bd_talkBG.png"


    local spriteFrame1 = cc.SpriteFrameCache:getInstance():getSpriteFrame("")
    local spriteFrame2 = cc.SpriteFrameCache:getInstance():getSpriteFrame("")

    for i=1,2 do
        local textButton = ccui.Button:create():addTo(self)
        textButton:setTouchEnabled(true)
        textButton:setTitleFontSize(28)

        -- textButton:addTouchEventListener(handler(self,self.onButton))
        textButton:loadTextures(spriteFrame1,spriteFrame1,spriteFrame2)
        textButton:setTitleFontName("fonts/STHeiti-Medium_1.ttf")
        self["button"..i] = textButton
    end

    self.button1:setTitleText("进入游戏")
    self.button1:setAnchorPoint(display.RIGHT_BOTTOM)
    self.button1:setPosition(cc.p(display.size.width, 0))
    self.button1:addTouchEventListener(function()
        cc.UserDefault:getInstance():setStringForKey("miss","")
        -- self:getApp():enterScene("MainScene")
        local function onPanelClosed(reason)
            if reason == "login" then
                self:getApp():enterScene("GameMainScene")
            end
        end
        panelFactory:createPanel(panelFactory.Panels.LoginPanel, onPanelClosed):addTo(self)
        musicMgr:play(5000015)
    end)

    self.button2:setTitleText("清空")
    self.button2:setAnchorPoint(display.LEFT_BOTTOM)
    self.button2:setPosition(cc.p(0, 0))
    self.button2:addTouchEventListener(function()
        cc.UserDefault:getInstance():setStringForKey("miss","")
        self.missLabel:setString(cc.UserDefault:getInstance():getStringForKey("miss"))
    end)
    -- print(cc.UserDefault:getInstance():getStringForKey("miss"))
    self.missLabel:setString("联系大表哥缺少资源列表如下："..cc.UserDefault:getInstance():getStringForKey("miss"))

end

function LogScene:onExit()

end

return LogScene



--
--
-- local CURRENT_MODULE_NAME = ...
--
-- -- classes
--
-- -- singleton
-- local LogScene = class("LogScene", import(".SceneBase", CURRENT_MODULE_NAME))
--
-- LogScene.RESOURCE_FILENAME = "scenes/Main.csb"
--
--
-- function LogScene:onCreate()
--     -- local layer = cc.Layer:create():addTo(self)
--     -- self.missLabel = cc.Label:createWithTTF(v, "fonts/STHeiti-Medium_1.ttf", 28)
--     -- self.missLabel:setAnchorPoint(cc.p(0.5, 0.5))
--     -- self.missLabel:setPosition(display.size.width / 2, display.size.height/2)    layer:addChild(self.missLabel , 0)
--     --
--     -- self.buttonPath1 = "studio/textures/ui/talk/bd_talkB.png"
--     -- self.buttonPath2 = "studio/textures/ui/talk/bd_talkBG.png"
--     --
--     -- for i=1,2 do
--     --     local textButton = ccui.Button:create():addTo(self)
--     --     textButton:setTouchEnabled(true)
--     --     textButton:setTitleFontSize(28)
--     --     textButton:setPosition(cc.p(display.size.width, 0))
--     --     -- textButton:addTouchEventListener(handler(self,self.onButton))
--     --     textButton:loadTextures(self.buttonPath1,self.buttonPath1,self.buttonPath2)
--     --     textButton:setTitleFontName("fonts/STHeiti-Medium_1.ttf")
--     --     self["button"..i] = textButton
--     -- end
--     --
--     -- self.button1:setTitleText("进入游戏")
--     -- self.button1:setAnchorPoint(display.RIGHT_BOTTOM)
--     -- self.button1:addTouchEventListener(function()
--     --     self:getApp():enterScene("MainScene")
--     -- end)
--     --
--     -- self.button2:setTitleText("清空")
--     -- self.button2:setAnchorPoint(display.LEFT_BOTTOM)
--     -- self.button2:addTouchEventListener(function()
--     --     cc.UserDefault:getInstance():setStringForKey("miss","")
--     -- end)
-- end
--
--
-- function LogScene:onEnter()
--     self.miss:setString(cc.UserDefault:getInstance():getStringForKey("miss","null"))
-- end
--
-- function LogScene:onExit()
-- end
--
--
-- return LogScene

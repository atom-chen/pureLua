local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode       = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase           = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local LiveNode            = import("..controls.LiveNode", CURRENT_MODULE_NAME)
local StoryBannerNode     = import("..fragment.EduFragment.StoryBannerNode", CURRENT_MODULE_NAME)
local ClothNode           = import("..fragment.EduFragment.ClothNode", CURRENT_MODULE_NAME)
local GiftNode            = import("..fragment.EduFragment.GiftNode", CURRENT_MODULE_NAME)
local GridView            = import("..controls.GridView", CURRENT_MODULE_NAME)
local ImageLabel          = import("..fragment.ImageLabel", CURRENT_MODULE_NAME)
local GiftPageBannerNode  = import("..fragment.EduFragment.GiftPageBannerNode", CURRENT_MODULE_NAME)
local ClothShopBannerNode = import("..fragment.EduFragment.ClothShopBannerNode", CURRENT_MODULE_NAME)

-- singleton
local panelFactory        = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr           = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local infoMgr             = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr              = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local ws                  = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder           = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local EduPanel      = class("EduPanel", PanelBase)

EduPanel.Z_FRAGMENT = 100
EduPanel.Z_GIRL     = 10
EduPanel.CellTag    = 100
EduPanel.LayoutTag  = 1000


function EduPanel.create(params)
    params.csbName = "layers/edu/Education.csb"

    return EduPanel.new(params)
end

EduPanel.Status = table.enumTable({
    "MAIN",
    "STORY_TALK",
    "STORY_PAPAPA",
    "DRESS",
    "GIFT",
    "SECRET",
    "CLOTH_SHOP",
    "GIFT_SHOP",
    "CLOTH",

})

function EduPanel:ctor(params)
    EduPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self.live2d = {}
    -- dump(params.id)
    self.id = params.id
    self.soulPanel = params.soulPanel
    -- dump(params)
    self:mapUiElements({"loveNode",--爱心
                        "loveLoadingBar",--爱心进度
                        "loveText",--爱心文字
                        "loveAddNode",--爱心增加数值
                        "loveLevelLabel"--爱心等级
                        ,"retractNode"--收起按钮
                        ,"storyNode"--故事节点
                        ,"giftNode"--礼物节点
                        ,"listView"--通用列表
                        ,"secretListView"--秘密列表
                        ,"girlNode"--live2d位置
                        ,"setIndexButton"--设置在主页
                        ,"storyTalkNode" -- 话题标签
                        ,"storyPapapaNode"-- 约会标签
                        ,"storyListView" -- 故事listview
                        ,"buyClothButton" --购买衣服
                        ,"leftArrowNode" --左尖头
                        ,"rightArrowNode"--右尖头
                        ,"shopPageView" --服装商店pageview
                        ,"giftListPanel" -- 礼品店list基础容器
                        ,"giftShopPageView" -- 礼品店pageview
                        ,"giftShopImage" --礼品店背景
                        ,"eduHaveGoldText" -- 拥有金币
                        ,"handNode" -- 邪恶小手
                        ,"handTouchNode" -- 邪恶小手触摸框
                        ,"handLoadingBar" -- 邪恶小手进度条
                        ,"handNumLabel" -- 邪恶小手次数
                        ,"handTimeLabel" -- 邪恶剩余时间
                        ,"dressCurtain" --穿衣服关窗帘
                        ,"girlNameImageView" -- 养成妹子名字
                    })

    -- 移动的小手
    self.handMovingNode = AnimationNode.load("nodes/edu/touch.csb"):addTo(self)
    --live2d说话
    self.live2d.talkNode = AnimationNode.seek(self, "girlTalkNode")
    self.live2d.talkNode:setLocalZOrder(self.Z_FRAGMENT)
    self.live2d.talk = ImageLabel.seek(self, "talkNode")
    self.live2d.talk:runAnimation("3")
    self.live2d.touchTime = playerMgr.actionTouch.touchOverTime
    -- 倒计时锁定，为了等联网
    self.live2d.timeLock = false

    --修改Z轴覆盖
    self.secretListView:setLocalZOrder(self.Z_FRAGMENT)
    self.retractNode:setLocalZOrder(self.Z_FRAGMENT+1)

    MessageManager.addMessage(self,girl.MessageLayer.UI, girl.UiMessage.CLOTH_SHOP_REFRESH,handler(self,self.refreshClothShop))
end

function EduPanel:onEnter()
    EduPanel.super.onEnter(self)

    -- 联网进入场景
    local pb    = pbBuilder:build({
          proto = "data/pb/interface/enterScene.pb",
          desc  = "interface.enterScene.Request",
          input = { scene      = "SOUL_EDU" } })

    ws:send( "ENTER_SCENE", pb, function(resultCode, des, data)
        if resultCode == 0 then
            self.live2d.touchTime = playerMgr.actionTouch.touchOverTime
            self:refresh()
        end
    end)

    self:runAnimation("in")

    self.girlNameImageView:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_NAME,self.id))
    print("girlNameImageViewgirlNameImageViewgirlNameImageView")
    -- dump(self.pb)
    self.status = self.Status.MAIN

    girl.addTouchEventListener(self,{swallow = true})

    self:onButtonClicked("storyButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.STORY_TALK
        self:runAnimation("toStory")
        self:refreshStory()
    end)

    self.storyTalkNode:onButtonClicked("normalTakeButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.STORY_TALK
        print("STORY_TALK:"..self.status)
        self:refreshStory()
    end)

    self.storyPapapaNode:onButtonClicked("normalTakeButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.STORY_PAPAPA
        print("STORY_PAPAPA:"..self.status)
        self:refreshStory()
    end)

    self:onButtonClicked("dressButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.CLOTH
        self:runAnimation("toCloth")
        self:refreshCloth()
    end)

    self:onButtonClicked("giftButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.GIFT
        self:runAnimation("toGift")
        self:refreshGift()
    end)

    self:onButtonClicked("secretButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.SECRET
        self:runAnimation("toSecret")
        self:refreshSecret()
    end)

    self:onButtonClicked("giftShopButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.GIFT_SHOP
        self:runAnimation("toGiftShop")
        self:refreshGiftShop()
    end)

    self:onButtonClicked("buyClothButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self.status = self.Status.CLOTH_SHOP
        self:refreshClothShop()
        self:runAnimation("toClothShop", false,function()

            self.leftArrowNode:runAnimation("loop",true)
            self.rightArrowNode:runAnimation("loop",true)

        end)
    end)

    self:onButtonClicked("setIndexButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        local pb    = pbBuilder:build({
              proto = "data/pb/interface/modifyConfig.pb",
              desc  = "interface.modifyConfig.Request",
              input ={ params = { {key= "showSoul", value = tostring(self.id)} } }
          })

        ws:send( "MODIFY_CONFIG", pb, function(resultCode, des, data)
            if resultCode == 0 then
                dump(playerMgr.config)
                self:refresh()
            end
        end)
    end)

    self:onButtonClicked("retractButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        if self.status == self.Status.SECRET then
            self:runAnimation("secretBackEd")
            self.secretListView:removeAllItems()
            self.secretListView:refreshView()
        elseif self.status == self.Status.CLOTH then
            self:runAnimation("clothBackEd")
            self.listView:removeAllItems()
            self.listView:refreshView()
        elseif self.status == self.Status.STORY_TALK or
            self.status == self.Status.STORY_PAPAPA then
            self:runAnimation("storyBackEd")
        elseif self.status == self.Status.GIFT then
            self:runAnimation("giftBackEd")
        end
        self:showGirl()
        self.status = self.Status.MAIN

    end)

    self:onButtonClicked("mapBackButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        local function onBackButton()
            if self.soulPanel then
               self:getParent():reloadSoulAtk(self.id)
               self:getParent():reloadLoveLv(self.id)
            end
            self:close()
        end
        if self.status == self.Status.MAIN then
            self:runAnimation("out", false, onBackButton)
        elseif self.status == self.Status.CLOTH then
            self.retractNode:runAnimation("out")
            self:runAnimation("backMain", false, onBackButton)
        elseif self.status == self.Status.GIFT then
            self.giftNode:runAnimation("out")
            self.retractNode:runAnimation("out")
            self:runAnimation("backMain", false, onBackButton)
        elseif self.status == self.Status.STORY_TALK or
            self.status == self.Status.STORY_PAPAPA then
            self.storyNode:runAnimation("out")
            self.retractNode:runAnimation("out")
            self:runAnimation("backMain", false, onBackButton)
        elseif self.status == self.Status.SECRET then
            self.retractNode:runAnimation("out")
            self:runAnimation("backMain", false, onBackButton)
        elseif self.status == self.Status.CLOTH_SHOP then
            self.retractNode:runAnimation("out")
            self:refreshCloth()
            self:runAnimation("shopBackCloth")
            self.status = self.Status.CLOTH
        elseif self.status == self.Status.GIFT_SHOP then
            self.retractNode:runAnimation("out")
            self:runAnimation("shopBackGift")
            self.status = self.Status.GIFT
            self:refreshGift()
        end
    end)

    -- 左边4个跳转按钮
    self:onButtonClicked("detailButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self:hideGirl()
        panelFactory:createPanel(panelFactory.Panels.SoulsDetailPanel, handler(self,self.onPanelClosed), {id = self.pb.class_id}):addTo(self,self.Z_FRAGMENT)
    end)

    self:onButtonClicked("upgradeButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self:hideGirl()
        panelFactory:createPanel(panelFactory.Panels.SoulsUpgradePanel, handler(self,self.onPanelClosed), {id = self.pb.class_id,edu = true}):addTo(self,self.Z_FRAGMENT)
    end)

    self:onButtonClicked("advanceButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self:hideGirl()
        panelFactory:createPanel(panelFactory.Panels.SoulsAdvancePanel, handler(self,self.onPanelClosed), {id = self.pb.class_id,edu = true}):addTo(self,self.Z_FRAGMENT)
    end)

    self:onButtonClicked("peijianButton", function()
        musicManager:play(girl.UiMusicId.BUTTON_CLICK)
        self:hideGirl()
        panelFactory:createPanel(panelFactory.Panels.SoulsPeijianPanel, handler(self,self.onPanelClosed), {id = self.pb.class_id,edu = true}):addTo(self,self.Z_FRAGMENT)
    end)

    self:showGirl()

    self:onUpdate(handler(self, self.update))
end

function EduPanel:showGirl()
    -- self.live2d.node:show()
    self:refresh()
end

function EduPanel:hideGirl()
    -- self.live2d.node:hide()
    if self.live2d.node ~= nil then
        self.live2d.node:removeSelf()
        self.live2d.node = nil
    end
    self.live2d.talkNode:hide()
end

function EduPanel:update(dt)
    -- 刷新小手剩余时间＝＝0就是满了
    if playerMgr.actionTouch.touchOverTime == 0 then
        self.handTimeLabel:setString("Max")
    else
        if self.live2d.touchTime > dt*1000 then
            self.live2d.touchTime = self.live2d.touchTime - dt*1000
            local s = self.live2d.touchTime / 1000
            local th = s / 3600
            local tm = math.mod(s, 3600) / 60
            local ts = math.mod(math.mod(s, 3600), 60)
            self.handTimeLabel:setString(string.format("%d:%d:%d", th, tm ,ts))
        else
            if self.live2d.timeLock == false then
                -- 更新数据
                self.live2d.timeLock = true
                local pb    = pbBuilder:build({
                      proto = "data/pb/interface/updateDiff.pb",
                      desc  = "interface.updateDiff.Request",
                      input ={ scene      = "SOUL_EDU" }})

                ws:send( "UPDATE_DIFF", pb, function(resultCode, des, data)
                    if resultCode == 0 then
                        self.live2d.touchTime = playerMgr.actionTouch.touchOverTime
                        self:refresh()
                        self.live2d.timeLock = false
                    end
                end)
            end
        end
    end
end

function EduPanel:refresh()
    self.pb = playerMgr.souls[self.id]

    -- 刷新设置到主页
    if playerMgr.config.showSoul == self.id then
        self.setIndexButton:setTouchEnabled(false)
        self.setIndexButton:setBright(false)
    else
        self.setIndexButton:setTouchEnabled(true)
        self.setIndexButton:setBright(true)
    end

    -- 刷新爱心
    self.loveLevelLabel:setString(self.pb.loveLevel)
    local maxLove = infoMgr:findInfo("devExps", "class_id", self.pb.class_id*100+self.pb.loveLevel).maxExp
    self.loveText:setString(string.format("%d/%d", self.pb.currentLove, maxLove))
    self.loveLoadingBar:setPercent(self.pb.currentLove * 100 / maxLove)

    -- 刷新live2d
    if self.live2d.node == nil or self.live2d.class_id ~= self.pb.currentFashionClassId then
        if self.live2d.node ~= nil then
            self.live2d.node:removeSelf()
        end

        self.live2d.class_id = self.pb.currentFashionClassId
        -- print("kkkk:"..self.girlNode:getGlobalZOrder())
        self.live2d.node = LiveNode.load(resMgr:getResPath(self.pb.currentFashionClassId)):addTo(self,self.Z_GIRL,888)
        self.live2d.node:setPosition(self.girlNode:getPositionX(), self.girlNode:getPositionY())

        print("------addGirlTouchEvent() 又来了一次--------")
        self:addGirlTouchEvent()
    end

    -- 刷新金币
    self.eduHaveGoldText:setString(playerMgr.status.gold)

    -- 刷新小手次数
    self.handNumLabel:setString(tostring(playerMgr.actionTouch.touchTimes))
    -- 刷新小手状态
    -- printInfo("touchTimes:"..playerMgr.actionTouch.touchTimes)
    if playerMgr.actionTouch.touchTimes > 0 then
        self.handNode:runAnimation("on")
    else
        self.handNode:runAnimation("off")
    end

    self.handMovingNode:hide()
    self.handRate = 0
    self.handLoadingBar:setPercent(self.handRate)

    -- self.girlNameSprite:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_NAME, self.id, self.id))

end

function EduPanel:onGiftAddItem(item, idx)
    -- if idx > 18 then
        -- item:refresh()
    -- else
        -- item:refresh("111")
    -- end
    item:refresh(self.giftData[idx])
end

function EduPanel:onGiftCellTouched(item, idx)
    print(" fun:onGiftCellTouched  :"..idx)
end

function EduPanel:onGiftNumCells()
    return #self.giftData
end

--礼物使用拖拽处理
function EduPanel:addGiftUseEventListener()

    if self.giftListener then
        return
    end
    girl.addTouchEventListener(self,{swallow = true})
    local node = display.newNode():addTo(self,20000)
    self.giftListener = girl.addTouchEventListener(node, {swallow = false,
    onBegan = function(touch, event)
        print("gift ... onBegan")
        if self.status ~= self.Status.GIFT then
            self.giftListener:setSwallowTouches(true)
            return false
        end
        local touchPos = touch:getLocation()
        --item碰撞
        --print("gift Num: "..self:onGiftNumCells())
        for i=1,self:onGiftNumCells() do
            local item = self.gridView:itemAtIndex(i)
            local pos  = item:convertToWorldSpace(cc.p(item:getPositionX(), item:getPositionY()))
            local size = item:getRect()
            if cc.rectContainsPoint(size,touchPos) then
                -- print("tttt!!!!:"..i)
                self.selectIndex = i
                self.selectItem  = item
                self.giftListener:setSwallowTouches(false)
                return true
            end
        end
        self.giftListener:setSwallowTouches(true)
        return false
    end,
    onMoved = function(touch, event)

        print("gift ... onMoved")
        local touchPos = touch:getLocation()
        -- listView碰撞
        local listSize = self.gridView:getCascadeBoundingBox()
        if cc.rectContainsPoint(listSize,touchPos) then
            if self.cloneItem ~= nil then
                self.cloneItem:setPosition(touchPos)
            end
        else
            if self.cloneItem ~= nil then
                self.cloneItem:setPosition(touchPos)
                self.giftListener:setSwallowTouches(false)
            else
                local item = self.selectItem
                --local pos  = item:convertToWorldSpace(cc.p(item:getPositionX(), item:getPositionY()))
                -- local size = item:getCascadeBoundingBox()
                self.cloneItem = GiftNode.create():addTo(self,100)
                local pb = self.selectItem.pb
                pb.count = 0
                self.cloneItem:refresh(pb)--self.selectItem.pb
                self.cloneItem:setPosition(cc.p(touchPos))
            end
            self.giftListener:setSwallowTouches(true)
        end
    end,
    onEnded = function(touch, event)

        print("gift ... onEnded")
        local touchPos = touch:getLocation()
        self.giftListener:setSwallowTouches(false)
        if self.cloneItem ~= nil then
            if self.live2d.node:hit(touchPos.x, touchPos.y,self.live2d.node.TouchEvent.ALL ) == true then
                print("礼物已经成功的送到妹子手上啦！！")
                -- 更新数据
                self.live2d.timeLock = true
                local pb    = pbBuilder:build({
                      proto = "data/pb/interface/useDevProp.pb",
                      desc  = "interface.useDevProp.Request",
                      input ={ devProp_id = self.selectItem.pb.class_id,soul_id = self.pb.class_id } })

                ws:send( "USE_GIFT", pb, function(resultCode, des, data)
                    if resultCode == 0 then
                        self:refreshGift()
                    end
                end)

            end
            self.cloneItem:removeSelf()
            self.cloneItem = nil
        end
    end})
end

function EduPanel:refreshGift()

    self:showGirl()

    self.giftData = {}

    local function getGiftData()
        local giftData = {}
        for _,v in pairs(playerMgr.devProps) do
            table.insert(giftData, v)
        end
        return giftData
    end

    self.giftData = getGiftData()

    if self.gridView == nil then
        local size = self.giftListPanel:getContentSize()
        self.gridView = GridView:create({
            rect             = cc.rect(0,0,size.width,size.height),
            numItems         = 3,
            Item             = GiftNode,
            direction        = cc.SCROLLVIEW_DIRECTION_VERTICAL,
            margin           = 0,
            autoLayoutCell   = true,
            cb_onCellTouched = function(item,idx) self:onGiftCellTouched(item,idx) end,
            cb_onNumCells    = function() return self:onGiftNumCells() end,
            cb_onAddItem     = function(item,idx) self:onGiftAddItem(item,idx) end
        }):addTo(self.giftListPanel, 3000)
        self:addGiftUseEventListener()
    else
        self.gridView:reload()
    end
end

function EduPanel:refreshGiftShop()

    self:hideGirl()
    self.giftShopData = {}
    self.giftShopPageView:removeAllPages()

    local function getPageData()
        local giftShopData = {}
        local giftShopPageData = {}
        local idx = 1
        for _,v in pairs(playerMgr.devPropShop) do
            table.insert(giftShopPageData, v)
            idx = idx + 1
            if idx > 10 then
                table.insert(giftShopData, giftShopPageData)
                giftShopPageData = {}
                idx = 1
            end
        end
        if #giftShopPageData > 0 then
            table.insert(giftShopData, giftShopPageData)
        end
        return giftShopData
    end

    self.giftShopData = getPageData()
    -- dump(self.giftShopData)

    for _,v in ipairs(self.giftShopData) do
        local event_banner = GiftPageBannerNode.create()
        event_banner:refresh(v)
        local custom_item = ccui.Layout:create()
        custom_item:setContentSize(cc.size(self.giftShopPageView:getCascadeBoundingBox().width, self.giftShopPageView:getCascadeBoundingBox().height))
        event_banner:setPosition(cc.p(custom_item:getCascadeBoundingBox().width/2.0, custom_item:getCascadeBoundingBox().height/2.0))
        custom_item:addChild(event_banner)
        self.giftShopPageView:addPage(custom_item)
    end
end

function EduPanel:refreshStory()
    print("refreshStory:"..self.status)
    if self.status == self.Status.STORY_TALK then
        self.storyTalkNode:runAnimation("select_talk")
        self.storyPapapaNode:runAnimation("normal_date")
    else
        self.storyTalkNode:runAnimation("normal_talk")
        self.storyPapapaNode:runAnimation("select_date")
    end
    self.storyListView:removeAllItems()
    -- dump(self.pb.projects)
    local data = {}
    for _,v in pairs(self.pb.projects) do
        if self.status == self.Status.STORY_TALK then
            if v.type == 1 then
                table.insert(data, v)
            end
        else
            if v.type == 2 then
                table.insert(data, v)
            end
        end
    end

    table.sort(data, function(a,b) return a.state > b.state end)

    for i,v in ipairs(data) do
        local event_banner = StoryBannerNode.create(v)
        event_banner:setTag(self.CellTag)
        -- event_banner:retain()
        -- event_banner:runAnimation("select")

        local custom_item = ccui.Layout:create()
        custom_item:setTag(self.LayoutTag+i)
        -- custom_item:retain()
        custom_item:setTouchEnabled(true)
        custom_item:setContentSize(cc.size( event_banner:getCascadeBoundingBox().width, event_banner:getCascadeBoundingBox().height))
        event_banner:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
        custom_item:addChild(event_banner)
        self.storyListView:pushBackCustomItem(custom_item)
    end

    self.storyListView:addEventListener(function(sender, eventType)
        if eventType ~= 0 then
            print("select child index = ",sender:getCurSelectedIndex())
            local index = sender:getCurSelectedIndex() + 1
            local banner = sender:getChildByTag(self.LayoutTag + index):getChildByTag(self.CellTag)
            dump(banner.pb)
            if banner.pb.state ~= 2 then

                local pb    = pbBuilder:build({
                      proto = "data/pb/interface/enterProject.pb",
                      desc  = "interface.enterProject.Request",
                      input ={ soul_id = self.pb.class_id, project_id = banner.pb.class_id } })

                ws:send( "ENTER_PROJECT", pb, function(resultCode, des, data)
                    if resultCode == 0 then
                        self:hideGirl()
                        local script = panelFactory:createPanel(panelFactory.Panels.StoryScriptPanel, handler(self, self.onPanelClosed)):addTo(self, self.Z_FRAGMENT)
                        script:runScript( resMgr:getIconPath(resMgr.IconType.PAPAPA, banner.pb.class_id), function()
                            script:close("story")
                            self:refreshStory()
                        end, true)
                    end
                end)
            end
        end
    end)
end

function EduPanel:refreshSecret()

    self.secretListView:removeAllItems()
    local event_banner = AnimationNode.load("nodes/edu/secret.csb")
    event_banner:runAnimation("in")
    event_banner:setTag(self.CellTag)
    for _,v in pairs(self.pb.secrets) do
        local info = infoMgr:findInfo("secrets", "class_id", v.class_id)
        local secretNode = event_banner:seek(info.position.."Node")
        if info.position ~= 1 then
            local maskNode = secretNode:seek("maskImage")
            if v.state == 2 then
                maskNode:show()
            else
                maskNode:hide()
            end

            if v.state == 3 then
                local newNode = secretNode:seek("newNode")
                newNode:show()
            end
        end
        local valueText = secretNode:seek("valueText")
        valueText:setString(info.value)
    end
    -- event_banner:retain()
    -- event_banner:refresh()
    -- event_banner:runAnimation("select")

    local custom_item = ccui.Layout:create()
    custom_item:setTag(self.LayoutTag)
    -- custom_item:retain()
    custom_item:setTouchEnabled(true)
    custom_item:setContentSize(cc.size( event_banner:getCascadeBoundingBox().width, event_banner:getCascadeBoundingBox().height))
    event_banner:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
    custom_item:addChild(event_banner)
    self.secretListView:pushBackCustomItem(custom_item)

    self.secretListView:refreshView()
end

function EduPanel:refreshCloth()

    print("fun: EduPanel:refreshCloth()")
    self:showGirl()
    self.listView:removeAllItems()
    dump(self.pb.fashions)

    self.clothData = {}
    self.clothes   = {}
    local function getClothData()
        local clothData = {}
        for k,v in girl.pairsByKeys(self.pb.fashions) do
           table.insert(clothData,k)
        end
        return clothData
    end
    self.clothData = getClothData()
    -- dump(self.clothData)
    local rowNum = #self.clothData/3 + 1
    for i=1,rowNum do

        local event_banner = AnimationNode.load("nodes/edu/clothBanner.csb")
        event_banner:runAnimation("in")
        event_banner:setTag(self.CellTag)
        for j=1,3 do
            local fashion = self.pb.fashions[self.clothData[(i-1)*3 + j]]
            if (i-1)*3 + j <= #self.clothData then
                local cloth = ClothNode.seek(event_banner,"clothRack"..j)
                cloth:setVisible(true)
                fashion.mode = 1
                cloth:refresh(fashion)
                table.insert(self.clothes,cloth)
            end
        end

        local custom_item = ccui.Layout:create()
        custom_item:setTag(self.LayoutTag)
        -- custom_item:retain()
        custom_item:setTouchEnabled(true)
        custom_item:setContentSize(cc.size(event_banner:getCascadeBoundingBox().width,event_banner:getCascadeBoundingBox().height))
        event_banner:setPosition(cc.p(custom_item:getContentSize().width,custom_item:getContentSize().height/2.0))
        custom_item:addChild(event_banner)
        self.listView:pushBackCustomItem(custom_item)
        self.listView:refreshView()

    end
    self:addClothUseEventListener()
end

function EduPanel:refreshClothShop()

    print("fun: EduPanel:refreshClothShop()")
    self:hideGirl()
    self.shopPageView:removeAllPages()
    local function getPageData()
        local clothShopData = {}
        local clothShopPageData = {}
        local idx = 1
        for _,v in pairs(self.pb.shopFashions) do

            --add state & mode
            v.mode = 2 --shop
            table.insert(clothShopPageData, v)
            idx = idx + 1
            if idx > 5 then
                table.insert(clothShopData, clothShopPageData)
                clothShopPageData = {}
                idx = 1
            end
        end
        if #clothShopPageData > 0 then
            table.insert(clothShopData, clothShopPageData)
        end
        return clothShopData
    end
    self.clothShopData = getPageData()
    dump(self.clothShopData)
    for _,v in ipairs(self.clothShopData) do
        local event_banner = ClothShopBannerNode.create()
        event_banner:refresh(v)
        local custom_item = ccui.Layout:create()
        dump(self.shopPageView:getCascadeBoundingBox())
        custom_item:setContentSize(cc.size( self.shopPageView:getCascadeBoundingBox().width, self.shopPageView:getCascadeBoundingBox().height))
        event_banner:setPosition(cc.p(custom_item:getCascadeBoundingBox().width/2.0, custom_item:getCascadeBoundingBox().height - 12)) --custom_item:getCascadeBoundingBox().width/2.0
        custom_item:addChild(event_banner)
        self.shopPageView:addPage(custom_item)
    end
end

--服装更换拖拽事件处理
function EduPanel:addClothUseEventListener()

    if self.clothListener then
        return
    end

    girl.addTouchEventListener(self,{swallow = true})
    local node = display.newNode():addTo(self,20000)
    self.clothListener = girl.addTouchEventListener(node, {swallow = false,
    onBegan = function(touch, event)
        print(" ClothUse-- onBegan status:"..self.status)
        local touchPos = touch:getLocation()
        if self.status ~= self.Status.CLOTH then
            self.clothListener:setSwallowTouches(true)
            return false
        end
        --item碰撞
        for i,v in ipairs(self.clothes) do
            local item = v
            local pos  = item:convertToWorldSpace(cc.p(item:getPositionX(), item:getPositionY()))
            local size = item:getCascadeBoundingBox()
            local rect = cc.rect(pos.x - size.width ,pos.y-size.height,size.width,size.height)
            -- dump(rect)
            -- girl.createTestRect(size):addTo(item,40000)
            if cc.rectContainsPoint(rect,touchPos) then
                print("--tttt!!!!:"..i)
                self.selectIndex = i
                self.selectItem  = item
                self.clothListener:setSwallowTouches(false)
                return true
            end
        end
        self.clothListener:setSwallowTouches(true)
        return false
    end,
    onMoved = function(touch, event)
        print(" ClothUse-- onMoved")
        local touchPos = touch:getLocation()
        -- listView碰撞
        local listSize = self.listView:getCascadeBoundingBox()
        if cc.rectContainsPoint(listSize,touchPos) then
            if self.cloneItem ~= nil then
                self.cloneItem:setPosition(touchPos)
            end
        else
            if self.cloneItem ~= nil then
                self.cloneItem:setPosition(touchPos)
                self.clothListener:setSwallowTouches(false)
            else
                local item = self.selectItem
                --local pos  = item:convertToWorldSpace(cc.p(item:getPositionX(), item:getPositionY()))
                --local size = item:getCascadeBoundingBox()
                self.cloneItem = ClothNode.create():addTo(self,100)
                self.cloneItem:refresh(self.selectItem.params)--self.selectItem.pb
                self.cloneItem:setPosition(cc.p(touchPos))
            end
            self.clothListener:setSwallowTouches(true)
        end
    end,
    onEnded = function(touch, event)

        print(" ClothUse-- onEnded")
        local touchPos = touch:getLocation()
        self.clothListener:setSwallowTouches(false)
        if self.cloneItem ~= nil then
            if self.live2d.node:hit(touchPos.x, touchPos.y,self.live2d.node.TouchEvent.ALL) == true then
                print("衣服已经成功的给妹子穿上啦！！")
                self.dressCurtain:setLocalZOrder(110)
                self:runAnimation("inChangeCloth",false,function()
                    --更新数据
                    self.live2d.timeLock = true
                    local pb    = pbBuilder:build({
                          proto = "data/pb/interface/changeFashion.pb",
                          desc  = "interface.changeFashion.Request",
                          input ={fashion_id = self.selectItem.pb.class_id} })
                    ws:send("CHANGE_FASHION", pb, function(resultCode, des, data)
                        if resultCode == 0 then
                            self.live2d.node:removeSelf()
                            self.live2d.node = LiveNode.load(resMgr:getResPath(self.selectItem.pb.class_id)):addTo(self,self.Z_GIRL,888)
                            self.live2d.node:setPosition(self.girlNode:getPositionX(), self.girlNode:getPositionY())
                            self:refreshCloth()
                            self:runAnimation("outChangeCloth")
                        else
                            self:runAnimation("outChangeCloth")
                        end
                    end)
                end)
            end
            self.cloneItem:removeSelf()
            self.cloneItem = nil
        end
        -- dump(pos)
    end})
end

function EduPanel:addGirlTouchEvent()
    if self.live2d.node == nil then
        return
    end
    -- 邪恶小手操作
    -- 对应的表触摸位置数据
    local TouchPos = {
        NORMAL = 0, -- 正常状态
        HEAD   = 1, -- 头部
        BODY   = 4, -- 身体
        CHEST  = 3, -- 胸部
        FACE   = 2 -- 脸
    }
    self.live2dListener =  girl.addTouchEventListener(self.live2d.node,{swallow = false,
    onBegan = function(touch, event)
        -- 妹子在其他界面隐藏了，就不要做逻辑了
        if self.live2d.node == nil then
            return false
        end
        -- 显示说话，等点击
        if self.live2d.talkNode:isVisible() == true then
            self.live2d.talkNode:hide()
        end
        -- 不在主界面也不要摸了
        if self.status ~= self.Status.MAIN then
            return false
        end
        local touchPos = touch:getLocation()
        if self.live2d.node:hit(touchPos.x, touchPos.y) ~= self.live2d.node.TouchEvent.NORMAL then
            self.handMovingNode:setPosition(touchPos)
            self.handMovingNode:setLocalZOrder(12)
            self.handMovingNode:show()
            return true
        else
            -- self.live2d.node:runRandomMotion("screen", 2)
            -- self.live2d.node:runRandomExpression()
             self.live2dListener:setSwallowTouches(true)
            return false
        end
    end,
    onMoved = function(touch, event)
        -- 显示说话，等点击
        if self.live2d.talkNode:isVisible() == true then
            return
        end
        local touchPos = touch:getLocation()
        -- dump(touchPos)
        self.handMovingNode:setPosition(touchPos)
        -- if false == self.handMovingNode:isVisible() then
        --     return
        -- end

        local hit = self.live2d.node:hit(touchPos.x, touchPos.y)
        if hit ~= self.live2d.node.TouchEvent.NORMAL then
            if playerMgr.actionTouch.touchTimes > 0 then
                self.handNode:runAnimation("movingOn")
            else
                self.handNode:runAnimation("movingOff")
            end
            if hit == self.live2d.last then
                -- 满了
                if self.handRate >= 100 then

                    local devType = infoMgr:findInfo("devExps", "class_id", self.pb.class_id*100+self.pb.loveLevel).devType
                    local touchPos = TouchPos[table.keyof( self.live2d.node.TouchEvent, hit)]
                    local actionTouch = infoMgr:findInfo("actionTouchs", "class_id", self.pb.class_id*100+touchPos*10+devType)
                    -- dump(actionTouch)

                    -- 运行动作
                    local action = infoMgr:findInfo("actions", "class_id", actionTouch.actionId)
                    dump(action)
                    self.live2d.node:runExpression(action.expName)
                    self.live2d.node:runRandomMotion(action.actionName, 2)
                    self.live2d.node:say(string.format("sound/live2d/mp3/%s.mp3", action.soundName), string.format("sound/live2d/txt/%s.txt",action.soundName), function()
                    end)
                    -- 有次数请求网络
                    if playerMgr.actionTouch.touchTimes > 0 then
                        -- 先减1
                        playerMgr.actionTouch.touchTimes = playerMgr.actionTouch.touchTimes - 1
                        -- 联网
                        local pb    = pbBuilder:build({
                              proto = "data/pb/interface/touchSoul.pb",
                              desc  = "interface.touchSoul.Request",
                              input ={ class_id      = actionTouch.class_id } })

                        ws:send( "TOUCH_SOUL", pb, function(resultCode, des, data)
                            if resultCode == 0 then
                                self.live2d.touchTime = playerMgr.actionTouch.touchOverTime
                                self:refresh()
                            end
                        end)
                    end
                    self.live2d.talkNode:show()
                    -- if self.live2d.talkNodeAction then
                        self.live2d.talkNode:stopAction(self.live2d.talkNodeAction)
                    -- end
                    self.live2d.talk:setString(actionTouch.content)
                    self.live2d.talkNode:runAnimation("in")
                    -- 3秒后消失
                    self.live2d.talkNodeAction = self.live2d.talkNode:runAction(cc.Sequence:create(cc.DelayTime:create(3.0), cc.CallFunc:create(function() self.live2d.talkNode:hide() end), nil))

                    self.handRate = 0
                    self.handLoadingBar:setPercent(self.handRate)
                    self.handMovingNode:hide()

                    self:refresh()

                else
                    self.handRate = self.handRate + 3
                    self.handLoadingBar:setPercent(self.handRate)
                end
            end
        else
            self.handRate = 0
            self.handLoadingBar:setPercent(self.handRate)
            self.handMovingNode:hide()
        end

        self.live2d.last = hit
    end,
    onEnded = function(touch, event)
        self.handRate = 0
        self.handLoadingBar:setPercent(self.handRate)
        self.handMovingNode:hide()
        self.live2d.last = self.live2d.node.TouchEvent.NORMAL
        self:refresh()
    end
    })
end

function EduPanel:onPanelClosed(reason)
    if self.live2d.node == nil then
        self:refresh()
    end
    if reason == "story" then
        self.status = self.Status.MAIN
    end
end

function EduPanel:onExit()
    EduPanel.super.onExit(self,"EduPanel")
    MessageManager.removeMessageByLayerName(girl.MessageLayer.UI,girl.UiMessage.CLOTH_SHOP_REFRESH)
    print("EduPanel:onExit()")
end

return EduPanel

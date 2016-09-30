local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GirlHead   = import("..fragment.GirlHead", CURRENT_MODULE_NAME)


-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resMgr     = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()


local RecoveryPanel = class("RecoveryPanel", PanelBase)

RecoveryPanel.CellTag   = 100
RecoveryPanel.LayoutTag = 1000

function RecoveryPanel.create()
    return RecoveryPanel.new({ csbName = "layers/Recovery.csb"})
end

function RecoveryPanel:ctor(params)
    RecoveryPanel.super.ctor(self, params)
    self:enableNodeEvents()

    -- 当前选择的item
    self.selectItem = nil
    -- 当前选择的item的index
    self.selectIndex = 1
    -- 当前clone的item
    self.cloneItem = nil

    self.overDelay = 0
    self.delay = 0

    self:mapUiElements({"bottonNode", "listView", "backNode"})
    self.rooms = {}
    for i = 1,4 do
        self.rooms[i] = {}
        self.rooms[i].id = i
        self.rooms[i].recoveryButton = self:seek("recoveryButton" .. i)
        self.rooms[i].recoveryButton:setTag(i)
        self.rooms[i].recoveryButton:onClicked(handler(self,self.onRecoveryClicked))
        self.rooms[i].doorNode = self:seek("doorNode" .. i)
        self.rooms[i].expandNode = self:seek("expandNode" .. i)
        self.rooms[i].expandButton = self:seek("expandButton" .. i)
        self.rooms[i].expandButton:setTag(i)
        self.rooms[i].expandButton:onClicked(handler(self,self.onExpandClicked))
        self.rooms[i].airNode = self:seek("airNode" .. i)
        self.rooms[i].infoNode = self:seek("girlInfoNode" .. i)
        self.rooms[i].quickButton = self.seek(self.rooms[i].infoNode, "quickRecoveryButton")
        self.rooms[i].quickButton:setTag(i)
        self.rooms[i].quickButton:onClicked(handler(self,self.onQuickClicked))
        self.rooms[i].girlQNode = self.seek(self.rooms[i].infoNode, "gilrQNode")
        self.rooms[i].girlQSprite = self.seek(self.rooms[i].infoNode, "girlQSprite")
        self.rooms[i].infoNameLabel = self.seek(self.rooms[i].infoNode, "nameLabel")
        self.rooms[i].infoStarLabel = self.seek(self.rooms[i].infoNode, "starLabel")
        self.rooms[i].infoProgressLabel = self.seek(self.rooms[i].infoNode, "progressLabel")
        self.rooms[i].infoLoadingBar = self.seek(self.rooms[i].infoNode, "loadingBar")
        self.rooms[i].infoLevelLabel = self.seek(self.rooms[i].infoNode, "levelLabel")
        self.rooms[i].infoTimeLabel = self.seek(self.rooms[i].infoNode, "timeLabel")
        self.rooms[i].infoShadowNode = self.seek(self.rooms[i].infoNode, "infoShadowNode")
    end

    self:addAllTouchEventListener()

end

function RecoveryPanel:onEnter()
    RecoveryPanel.super.onEnter(self)
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)

    -- 联网进入场景
    local pb    = pbBuilder:build({
          proto = "data/pb/interface/enterScene.pb",
          desc  = "interface.enterScene.Request",
          input ={ scene      = "SHOWER" } })

    ws:send( "ENTER_SCENE", pb, function(resultCode, des, data)
        if resultCode == 0 then
            self:refreshTime()
            self:refresh()
            self:onUpdate(handler(self, self.update))
            ws:addListener("LISTENER", handler(self, self.onListener))
        end
    end)

    self:refresh()
    self.listView:hide()

    self.backNode:runAnimation("in")

    self:onButtonClicked("mapBackButton", function()
        self:close("recovery")
    end)
end

function RecoveryPanel:onExit()
    RecoveryPanel.super.onExit(self,"RecoveryPanel")
    -- local items = self.listView:getItems()
    -- for _,v in pairs(items) do
    --     local item = v:getChildByTag(100):release()
    -- end
    self:removeAllListCell()
end

function RecoveryPanel:update(dt)
    for _,v in ipairs(self.rooms) do
        -- dump(v)
        if v.overTime > dt*1000 then
            v.overTime = v.overTime - dt*1000
            local s = v.overTime / 1000
            local th = s / 3600
            local tm = math.mod(s, 3600) / 60
            local ts = math.mod(math.mod(s, 3600), 60)
            v.infoTimeLabel:setString(string.format("%d:%d:%d", th, tm ,ts))
        end
    end

    if self.overDelay > dt*1000 then
        self.overDelay = self.overDelay - dt*1000
    else
        if self.delay ~= 0 then
            print("UPDAETE:",self.delay)
            local pb    = pbBuilder:build({
                  proto = "data/pb/interface/updateDiff.pb",
                  desc  = "interface.updateDiff.Request",
                  input ={ scene      = "SHOWER" } })
            self.overDelay = 5 * 1000
            ws:send( "UPDATE_DIFF", pb, function()
                self:refreshTime()
                self:refresh()
            end)
        end
    end

end

function RecoveryPanel:onListener(resultCode, des, data)
    if resultCode == 0 then
        local rep = pbBuilder:decode({ proto = "data/pb/interface/listener.pb",
                                        desc  = "interface.listener.Response",
                                        input = data})
        self.delay = rep.delay
        self.overDelay = self.delay
        printInfo(self.delay..self.overDelay)
    end
end

function RecoveryPanel:onRecoveryClicked(sender)
    print("onRecoveryClicked")
    print(sender.target:getTag())
    self.selectIndex = sender.target:getTag()
    -- local room = self.rooms[self.selectIndex]
    self:showList()
end

function RecoveryPanel:onExpandClicked(sender)
    print("onExpandClicked")
    print(sender.target:getTag())
    local room = self.rooms[sender.target:getTag()]

    local pb    = pbBuilder:build({
          proto = "data/pb/interface/expandEnergy.pb",
          desc  = "interface.expandEnergy.Request",
          input = { position = room.id } })

    ws:send( "EXPAND_ENERGY", pb, function(resultCode, des, data)
        if resultCode == 0 then
            self:refresh()
        end
    end)
end

function RecoveryPanel:onQuickClicked(sender)
    print("onQuickClicked")
    print(sender.target:getTag())

    local room = self.rooms[sender.target:getTag()]

    local pb    = pbBuilder:build({
          proto = "data/pb/interface/addEnergy.pb",
          desc  = "interface.addEnergy.Request",
          input = { soul_id  = room.soul_id,
                    position = room.id,
                    quick    = true } })

    ws:send( "ADD_ENERGY", pb, function(resultCode, des, data)
        if resultCode == 0 then
            self:refreshTime()
            self:refresh()
        end
    end)
end

function RecoveryPanel:removeAllListCell()
    self.listView:removeAllItems()
end

function RecoveryPanel:showList()
    if self.listView:isVisible() == false then
        local fadein = cc.FadeIn:create(0.5)
        self.listView:runAction(fadein)
        self.bottonNode:runAnimation("in", false, function()
            self.listView:show()
        end)
        self.backNode:runAnimation("UP")
    else
        self.listView:show()
    end
end

function RecoveryPanel:hideList()
    if self.listView:isVisible() == true then
        local fadeout = cc.FadeOut:create(0.3)
        self.listView:runAction(fadeout)
        self.bottonNode:runAnimation("out", false, function()
            self.listView:hide()
        end)
        self.backNode:runAnimation("down")
    else
        self.listView:hide()
    end
end

function RecoveryPanel:refresh()
    -- dump(playerMgr.showers)
    for _,v in pairs(playerMgr.showers) do
        -- dump(v)
        -- print(v.posStatue.pos,":",v.posStatue.status)
        local room = self.rooms[v.posStatue.pos]
        room.soul_id = v.soul_id
        room.state = v.posStatue.status
        if v.posStatue.status == "OPEN" then
            room.recoveryButton:show()
            room.airNode:show()
            room.airNode:runAnimation("loop", true)
            room.expandNode:hide()
            if room.infoNode:isVisible() == true then
                room.infoNode:runAnimation("out", false, function()
                    room.infoNode:hide()
                    room.doorNode:runAnimation("out")
                end)
            end
        elseif v.posStatue.status == "CLOSE" then
            room.recoveryButton:hide()
            room.expandNode:show()
            room.infoNode:hide()
            room.airNode:hide()
        elseif v.posStatue.status == "USING" then
            room.recoveryButton:hide()
            room.expandNode:hide()
            if room.infoNode:isVisible() == false then
                room.doorNode:runAnimation("in", false, function()
                    room.infoNode:show()
                    room.infoNode:runAnimation("in")
                    room.girlQNode:runAnimation("loop" , true)
                    room.infoShadowNode:runAnimation("loop" , true)
                end)
            end

            local pb = playerMgr.souls[room.soul_id]
            room.infoNameLabel:setString(pb.info.name)
            room.infoStarLabel:setString(pb.star)
            room.infoProgressLabel:setString(string.format("%d/%d",pb.currentEnergy, pb.info.maxEnergy))
            room.infoLoadingBar:setPercent(pb.currentEnergy*100/pb.info.maxEnergy)
            room.infoLevelLabel:setString(pb.level)
            room.girlQSprite:setTextureByPlist(resMgr:getIconPath(resMgr.IconType.SOUL_Q, pb.class_id, pb.class_id))
            -- room.infoTimeLabel:setString(pb.star)
        end
    end

    self:removeAllListCell()

    local function pairsTable(t)
        local a = {}
        for _,v in pairs(t) do
            -- print(v.class_id..":"..v.status)
            if v.currentEnergy < v.info.maxEnergy and v.status ~= 2 then
                table.insert(a, v)
            end
        end
        return a
    end

    self.souls = pairsTable(playerMgr.souls)

    for i=1,#self.souls do
    -- for i=1,30 do
        local event_banner = GirlHead.create({type = GirlHead.Type.NORMAL, pb = self.souls[i]})
        event_banner:setTag(self.CellTag)
        -- event_banner:retain()
        event_banner:refresh()
        -- event_banner:runAnimation("select")

        local custom_item = ccui.Layout:create()
        custom_item:setTag(self.LayoutTag + i)
        -- custom_item:retain()
        custom_item:setTouchEnabled(true)
        custom_item:setContentSize(cc.size( event_banner:getCascadeBoundingBox().width, event_banner:getCascadeBoundingBox().height))
        -- dump( event_banner:getCascadeBoundingBox())
        event_banner:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
        custom_item:addChild(event_banner)
        self.listView:pushBackCustomItem(custom_item)
    end

end

function RecoveryPanel:progressGirlToRoom(girl, room)
    dump(girl.pb)
    dump(room)

    local pb    = pbBuilder:build({
          proto = "data/pb/interface/addEnergy.pb",
          desc  = "interface.addEnergy.Request",
          input = { soul_id  =  girl.pb.class_id,
                    position = room.id } })
    ws:send( "ADD_ENERGY", pb, function(resultCode, des, data)
        if resultCode == 0 then
            self:refreshTime()
            self:refresh()
        end
    end)
end

function RecoveryPanel:addAllTouchEventListener()
    girl.addTouchEventListener(self,{swallow = true})

    -- self.listView:addEventListener(handler(self, self.onListEvent))

    local node = display.newNode():addTo(self,20000)
    self.listener = girl.addTouchEventListener(node, {swallow = false,
    onBegan = function(touch, event)
        -- print("onBegan")
        if self.listView:isVisible() == false then
            return false
        end
        local touchPos = touch:getLocation()

        -- item碰撞
        local items = self.listView:getItems()
        for i,v in ipairs(items) do
            local item = v:getChildByTag(self.CellTag)
            local pos = item:convertToWorldSpace(cc.p(item:getPositionX(), item:getPositionY()))
            local size = item:getCascadeBoundingBox()
            local rect = cc.rect(pos.x - size.width, pos.y - size.height, size.width, size.height)
            if cc.rectContainsPoint(rect,touchPos) then
                -- print("tttt!!!!:"..i)
                self.selectIndex = i
                self.selectItem = item
                self.listener:setSwallowTouches(false)
                return true
            end
            -- dump(pos)
            -- dump(size)
            -- girl.createTestRect( rect ):addTo(self, 500+i)
        end

        -- listView碰撞
        local listSize = self.listView:getCascadeBoundingBox()
        if not cc.rectContainsPoint(listSize,touchPos) then
            self:hideList()
        end

        self.listener:setSwallowTouches(true)
        return false
    end,
    onMoved = function(touch, event)
        -- print("onMoved")
        if self.listView:isVisible() == false then
            return
        end
        local touchPos = touch:getLocation()
        -- dump(touchPos)

        -- listView碰撞
        local listSize = self.listView:getCascadeBoundingBox()
        if cc.rectContainsPoint(listSize,touchPos) then
            if self.cloneItem ~= nil then
                self.cloneItem:setPosition(touchPos)
            end
        else
            if self.cloneItem ~= nil then
                self.cloneItem:setPosition(touchPos)
                self.listener:setSwallowTouches(false)
            else
                local item = self.selectItem
                local pos = item:convertToWorldSpace(cc.p(item:getPositionX(), item:getPositionY()))
                local size = item:getCascadeBoundingBox()
                self.cloneItem = GirlHead.create({type = GirlHead.Type.NORMAL, pb = item.pb}):addTo(self)
                self.cloneItem:refresh()
                self.cloneItem:setPosition(cc.p(pos.x - size.width/2, pos.y - size.height/2))
            end
            self.listener:setSwallowTouches(true)
        end
    end,
    onEnded = function(touch, event)
        if self.listView:isVisible() == false then
            return
        end
        -- print("onEnded")
        local touchPos = touch:getLocation()
        self.listener:setSwallowTouches(false)
        if self.cloneItem ~= nil then
            -- 门碰撞
            for i=1,4 do
                local expandSize = self.rooms[i].expandNode:getCascadeBoundingBox()
                if cc.rectContainsPoint(expandSize,touchPos) then
                    -- print("room:",i)
                    self:progressGirlToRoom(self.selectItem, self.rooms[i])
                end
            end
            self.cloneItem:removeSelf()
            self.cloneItem = nil
        end
        -- dump(pos)
    end})

end

function RecoveryPanel:refreshTime()
    for _,v in pairs(playerMgr.showers) do
        dump(v)
        self.rooms[v.posStatue.pos].overTime = v.overTime
    end
end

return RecoveryPanel

local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode       = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase           = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory        = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerManager       = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local ws                  = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance("CHAT")
local pbBuilder           = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()

local BarragePanel = class("BarragePanel", PanelBase)

function BarragePanel.create(scene)
    return BarragePanel.new({scene = scene})
end

BarragePanel.MaxSpeed          = 10.0
BarragePanel.MinSpeed          = 5.0
BarragePanel.MaxContent        = 20
BarragePanel.UnitSpeed         = (BarragePanel.MaxSpeed - BarragePanel.MinSpeed) / BarragePanel.MaxContent
BarragePanel.MaxLinePercent    = 0.7
-- BarragePanel.MaxLine        = 15
BarragePanel.LineSpaces        = 10
BarragePanel.FontSize          = 32
BarragePanel.FontOutline       = 2
BarragePanel.UpdateMinSpeed    = 65
BarragePanel.UpdateMaxSpeed    = 1200
BarragePanel.ChangeUpdateSpeed = 30
BarragePanel.FixTime           = 0.1
BarragePanel.Font              = "fonts/STHeiti-Medium_1.ttf"

function BarragePanel:ctor(params)
    BarragePanel.super.ctor(self, params)
    self:enableNodeEvents()

    self.scene = params.scene or "SHOWER"
end

function BarragePanel:onEnter()
    BarragePanel.super.onEnter(self)

    -- 播放一个包的索引
    self.index = 1
    -- 换速度的索引
    self.changeIndex = 1
    -- 插入速度
    self.updateSpeed = math.random(self.UpdateMinSpeed, self.UpdateMaxSpeed)
    -- 插入累计
    self.updateDt = 0
    -- 是否onUpdate
    self.bUpdate = false

    self.pools = {}

    self.serverId = 0

    local label = cc.Label:createWithTTF("测试", self.Font, self.FontSize)
    label:enableOutline(display.COLOR_BLACK, 2)
    local size = label:getContentSize()

    self.MaxLine = math.ceil(display.height * self.MaxLinePercent / (size.height + self.FontOutline))

    for i=1, self.MaxLine do
        self.pools[i] = {}
        local poolData = self.pools[i]
        poolData.pool = {}
        poolData.y = display.height - i * size.height + self.LineSpaces
    end

    ws:send( "ENTER_BARRAGE", "", function(resultCode, des, data)
        -- print("ENTER_BARRAGE:"..resultCode)
        if resultCode == 0 then
            self:updatePool()
        end
    end)

    self:initTalk()

    ws:addListener("BARRAGE_SEND", handler(self, self.onListener))
    self:onUpdate(handler(self, self.run))
end

function BarragePanel:onExit()
    ws:removeListener("BARRAGE_SEND")
end

function BarragePanel:run(dt)
    if (self.bUpdate == false) or (playerManager.config.barrageOn ~= 0) then
        return
    end

    if self.index > #self.pb then
        self.bUpdate = false
        self:updatePool()
        return
    end
    -- print("321321321")
    self.updateDt = self.updateDt + (dt * 1000)

    for i=1,self.MaxLine do
        self:gc(self.pools[i])
    end

    if self.updateDt > self.updateSpeed then
        self.updateDt = 0

        if math.mod(self.changeIndex, self.ChangeUpdateSpeed) == 0 then
            self.changeIndex = 1
            self.updateSpeed = math.random(self.UpdateMinSpeed, self.UpdateMaxSpeed)
            -- printInfo("updateSpeed:"..self.updateSpeed)
        end

        for i=1,self.MaxLine do
            if self:runLine(self.pools[i]) == true then
                return
            end
        end

    end
end

function BarragePanel:runLine(poolData)

    if self.index > #self.pb then
        return true
    end

    local content = self.pb[self.index]
    local before = poolData.pool[1]

    if #poolData.pool > 0 and before.node ~= nil then
        local beforeSize = before.node:getContentSize()
        local bs = before.s - before.node:getPositionX()
        -- 前一个已走路程
        if bs == 0 then
            return
        end
        -- 前一个已走时间
        local bt = bs / before.v
        -- 前一个到站时间
        local ot = before.t - bt

        -- 下一个走过自己的时间
        local label = cc.Label:createWithTTF(content, self.Font, self.FontSize)
        local nsize = label:getContentSize()

        -- 进站判断
        if before.node:getPositionX() > display.width then
            return
        end

        local ns = display.width + nsize.width
        local ncc = string.len(content) / 3
        local nt = self.MinSpeed + (self.UnitSpeed * (self.MaxContent - ncc))
        local nv = ns / nt

        local it = ((ns - nsize.width) / nv)

        -- 出站判断
        if ot + self.FixTime < it then
            self:createLabel(content, poolData)
            return true
        else
            return false
        end
    else
        self:createLabel(content, poolData)
        return true
    end
end

function BarragePanel:createLabel(content, poolData)
    local item = {}

    item.node = cc.Label:createWithTTF(content, self.Font, self.FontSize)
    item.node:enableOutline(display.COLOR_BLACK, self.FontOutline)
    local size = item.node:getContentSize()
    item.node:setAnchorPoint(cc.p(1, 0.5))
    item.node:setPosition(cc.p(display.width + size.width, poolData.y ))
    self:addChild(item.node)

    item.s = item.node:getPositionX()
    item.cc = string.len(content) / 3
    item.t = self.MinSpeed + (self.UnitSpeed * (self.MaxContent - item.cc))
    item.v = item.s / item.t

    local moveTo = cc.MoveTo:create( item.t, cc.p( 0, item.node:getPositionY() ))
    item.node:runAction(cc.Sequence:create(moveTo,cc.CallFunc:create( function()
        item.node:removeSelf()
        item.node = nil
    end),nil))
    item.node:runAction(moveTo)
    table.insert(poolData.pool, 1, item)
    self.index = self.index + 1
    self.changeIndex = self.changeIndex + 1
end

function BarragePanel:gc(poolData)
    for i,v in ipairs(poolData.pool) do
        if v.node == nil then
            table.remove(poolData.pool, i)
        end
    end
end

function BarragePanel:onListener(resultCode, des, data)
    if resultCode == 0 and data ~= nil then
        -- print("BarragePanel:onListener == 0")
        dump(data)
        local rep = pbBuilder:decode({ proto = "data/pb/interface/sendBarrage.pb",
                                        desc  = "interface.sendBarrage.Response",
                                        input = data})
        -- print("BarragePanel:onListener")
        for _,v in ipairs(rep.content) do
            -- dump(v)
            table.insert(self.pb, self.index, v)
            self.bUpdate = true
        end
    end
end

function BarragePanel:updatePool()
    local pb    = pbBuilder:build({
          proto = "data/pb/interface/updateBarrage.pb",
          desc  = "interface.updateBarrage.Request",
          input = { scene = self.scene, id = self.serverId }
    })
    ws:send( "BARRAGE_UPDATE", pb, function(resultCode, des, data)
        -- print("BARRAGE_UPDATE:"..resultCode)
        if resultCode == 0 then
            local rep = pbBuilder:decode({ proto = "data/pb/interface/updateBarrage.pb",
                                            desc  = "interface.updateBarrage.Response",
                                            input = data})
            if rep ~= nil and #rep.barragePool.content > 0 then
                -- dump(rep)
                self.serverId = rep.id
                self.pb = rep.barragePool.content
                self.bUpdate = true
                self.index = 1
            else
                printInfo("Barrage over!")
                self.bUpdate = false
            end
        else
            self.bUpdate = false
        end
    end)
end

function BarragePanel:initTalk()
    self.talk = AnimationNode.load("nodes/home/btn_chat.csb"):addTo(self)
    self.talk:setPosition(cc.p(300, 300))

    girl.addTouchEventListener(self,{swallow = true,
    onBegan = function(touch, event)
        local rect = self.talk:getCascadeBoundingBox()
        local touchPos = touch:getLocation()
        self.talkMoveX = 0
        self.talkMoveY = 0
        if cc.rectContainsPoint(rect, touchPos) then
            return true
        else
            return false
        end
    end,
    onMoved = function(touch, event)
        local touchPos = touch:getLocation()
        local pos = cc.p(self.talk:getPositionX(), self.talk:getPositionY())
        self.talkMoveX = self.talkMoveX + math.abs(pos.x - touchPos.x)
        self.talkMoveY = self.talkMoveY + math.abs(pos.y - touchPos.y)
        self.talk:setPosition(cc.p(touchPos.x, touchPos.y))
    end,
    onEnded = function(touch, event)
        local rect = self.talk:getCascadeBoundingBox()
        if self.talkMoveX < 16 and self.talkMoveY < 16 then
            -- print("send!!!!")
            panelFactory:createPanel( panelFactory.Panels.BarrageBoxPanel):addTo(self)
            -- SendBarrage.create():addTo(self):setPosition(cc.p(display.width / 2, display.height / 2))
        end
    end})
end

return BarragePanel

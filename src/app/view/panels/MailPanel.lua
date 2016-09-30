local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GridView     = import("..controls.GridView", CURRENT_MODULE_NAME)
local IconNode     = import("..fragment.IconNode", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr             = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()

--[[
    list item
]]
local MailItem = class("MailItem", AnimationNode)

function MailItem.create()
    return MailItem.new({csbName = "nodes/email/email.csb"})
end

function MailItem:ctor()
    self:enableNodeEvents()
    local uiElements = {"contentLabel", "dateLabel", "titleLabel", "importantNode"}
    self:mapUiElements(uiElements)

    for i=1,3 do
        self:mapUiElement("itemNode"..i, function()
            return IconNode.seek(self, "itemNode"..i)
        end)
    end
end

function MailItem:refresh(pb)

    local function _writeContent(content)
        self.contentLabel:setString(content)
    end

    local function _writeDate(date)
        local dt = os.date("*t", date)
        self.dateLabel:setString(string.format(Strings.DATE, dt.year, dt.month, dt.day, dt.hour, dt.min))
    end

    local function _writeTitle(title)
        self.titleLabel:setString(title)
    end

    local function _writeLevel(level)
        self.importantNode:runAnimation(level)
    end

    local function _writeItems(items)
        for i,v in ipairs(items) do
            self["itemNode"..i]:show()
            self["itemNode"..i]:refresh(v)
        end
    end

    if pb.content then
        _writeContent(pb.content)
    end
    if pb.date then
        _writeDate(pb.date)
    end
    if pb.title then
        _writeTitle(pb.title)
    end
    if pb.level then
        _writeLevel(pb.level)
    end
    if pb.items then
        _writeItems(pb.items)
    end
end

--[[
    MailPanel
]]
local MailPanel = class("MailPanel", PanelBase)

function MailPanel.create()
    return MailPanel.new({ csbName = "layers/Email.csb"})
end

MailPanel.PAGE_MAIL_TOTAL = 10
MailPanel.PAGE_TOTAL = 20
MailPanel.MAIL_TOTAL = 200

function MailPanel:ctor(params)
    MailPanel.super.ctor(self, params)
    self:enableNodeEvents()

    local uiElements = {"mailNode", "listView", "left", "right","pageCountLabel","totalCountLabel","nullMailLabel"}
    self:mapUiElements(uiElements)

    -- 当前页
    self.page = 1
    -- 所有item
    self.items = {}
    self.pool = {}
    -- 数据源
    local mailsSrc = clone(playerMgr.mails)
    local index = 1
    self.mails = {}
    for k,v in pairs(mailsSrc) do
        self.mails[index] = v
        index = index + 1
    end

    -- dump(playerMgr.mails)
    -- dump(self.mails)

end

function MailPanel:onEnter()
    MailPanel.super.onEnter(self)
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
    self.mailNode:runAnimation("in",false)
    self.left:runAnimation("loop",true)
    self.right:runAnimation("loop",true)
    girl.addTouchEventListener(self,{swallow = true})

    for i=1,#self.mails do
        local event_banner = MailItem.create()
        event_banner:setTag(888)
        event_banner:retain()
        event_banner:refresh(self.mails[i])

        local custom_item = ccui.Layout:create()
        custom_item:setTag(8888)
        custom_item:retain()
        custom_item:setTouchEnabled(true)
        custom_item:setContentSize(cc.size( event_banner:getCascadeBoundingBox().width, event_banner:getCascadeBoundingBox().height))
        event_banner:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
        custom_item:addChild(event_banner)

        table.insert(self.items, custom_item)
        table.insert(self.pool, custom_item)
    end

    self.listView:addEventListener(function(sender, eventType)
        if eventType ~= 0 then
            print("select child index = ",sender:getCurSelectedIndex())
            print("select child id = ",self.mails[sender:getCurSelectedIndex()+1].id)
            -- 收取一个
            self:requestMail({id = {self.mails[sender:getCurSelectedIndex()+1].id}}, function(resultCode)
                if resultCode == 0 then
                    print("RECEIVEMAIL SUCCESS!!!")
                    local index = self.startIndex + sender:getCurSelectedIndex()
                    table.remove(self.items, index)
                    table.remove(self.mails, index)
                    self:refresh()

                    panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message =Strings.SUCCESS}):addTo(self)
                else
                    panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message =tostring(resultCode)}):addTo(self)
                end
            end)
        end
    end)

    self.left:onButtonClicked("arrowButton", function()
        self.page = self.page - 1
        self:refresh()
        self.listView:jumpToTop()
    end)

    self.right:onButtonClicked("arrowButton", function()
        self.page = self.page + 1
        self:refresh()
        self.listView:jumpToTop()
    end)

    self:onButtonClicked("pullButton", function()
        if #self.mails > 0 then
            -- 所有收取
            local ids = {}
            for _,v in ipairs(self.mails) do
                table.insert(ids, v.id)
            end
            dump(ids)

            self:requestMail({id = ids}, function(resultCode)
                if resultCode == 0 then
                    self.page = self.page - 1
                    for i = self.startIndex,self.endIndex do
                        table.remove(self.items, self.startIndex)
                        table.remove(self.mails, self.startIndex)
                    end
                    self:refresh()

                    panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message =Strings.SUCCESS}):addTo(self)
                else
                    panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message =tostring(resultCode)}):addTo(self)
                end
            end)
        end
    end)

    self:refresh()
end

function MailPanel:onExit()
    MailPanel.super.onExit(self)
    for _,v in ipairs(self.items) do
        v:getChildByTag(888):release()
        v:release()
    end
end

function MailPanel:refresh()

    if #self.mails <= 0 then
        self.nullMailLabel:show()
        self.listView:hide()
        self.right:hide()
        self.left:hide()
        self.totalCountLabel:setString(string.format("%d/%d", 0, self.MAIL_TOTAL))
        return
    else
        self.nullMailLabel:hide()
        self.listView:show()
        self.right:show()
        self.left:show()
    end

    local count = table.getn(self.listView:getItems())

    if count > 0 then
        self.listView:removeAllItems()
    end

    self.totalPage = math.ceil(#self.mails / self.PAGE_MAIL_TOTAL)
    self.remainder = math.mod(#self.mails, self.PAGE_MAIL_TOTAL)

    print("#self.items:"..#self.items)
    print("self.totalPage:"..self.totalPage)
    print("self.remainder:"..self.remainder)

    -- 标签显示控制
    if self.page <= 1 then
        self.page = 1
        self.left:hide()
        if self.page == self.totalPage then
            self.right:hide()
        else
            self.right:show()
        end
    elseif self.page == self.totalPage then
        self.left:show()
        self.right:hide()
    else
        self.left:show()
        self.right:show()
    end

    -- 数量文字
    self.totalCountLabel:setString(string.format("%d/%d", #self.mails, self.MAIL_TOTAL))
    self.pageCountLabel:setString(string.format("%d/%d", self.page, self.totalPage))

    -- 显示内容
    self.startIndex = (self.page - 1) * self.PAGE_MAIL_TOTAL + 1
    self.endIndex = 0

    if self.page == self.totalPage and self.remainder ~= 0 then
        self.endIndex =  self.startIndex + self.remainder - 1
    else
        self.endIndex = self.startIndex + self.PAGE_MAIL_TOTAL - 1
    end

    print("startIndex:"..self.startIndex)
    print("endIndex:"..self.endIndex)
    for i = self.startIndex,self.endIndex do
        self.listView:pushBackCustomItem(self.items[i])
    end

end

function MailPanel:requestMail(param, cb)

    local pb    = pbBuilder:build({
          proto = "data/pb/interface/receiveMail.pb",
          desc  = "interface.receiveMail.Request",
          input = param
    })
    self.load = panelFactory:createPanel(panelFactory.Panels.LoadingPanel,nil)
                                :addTo(self,600)
    self.load:showBackGround(false)

    ws:send( "RECEIVEMAIL", pb, function(resultCode, des, data)
        self.load:close()
        if cb then cb(resultCode) end
    end)

end

return MailPanel

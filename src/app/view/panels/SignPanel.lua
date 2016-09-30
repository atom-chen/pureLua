local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local LiveNode      = import("..controls.LiveNode", CURRENT_MODULE_NAME)
-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerManager = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()

local SignItem = class("SignItem", AnimationNode)

function SignItem.seek( parentNode, nodeName, type)
    return SignItem.new({
            parentNode 	 = parentNode,
            nodeName	 = nodeName,
            type         = type })
end

function SignItem:ctor(params)
    SignItem.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({"tagLabel","countLabel","itemIconSprite","iconNode"})
end

function SignItem:refresh(pb)
    local function _writeCount(count)
        self.countLabel:setString("x"..count)
    end

    local function _writeTag(tag)
        self.tagLabel:setString(tag)
    end

    local function _writeIcon(path)
        self.itemIconSprite:setTexture(path)
    end

    local function _writeSigned(signed)
        if signed then
            self:runAnimation("get")
        else
            self:runAnimation("1")
        end
    end

    if pb.class_id then
        _writeTag(pb.class_id)
    end
    if pb.signed then
        _writeSigned(pb.signed)
    end
    if pb.path then
        _writeIcon(pb.path)
    end
    if pb.item then
        if pb.item.count then
            _writeCount(pb.item.count)
        end
    end
    if pb.quality >= 0 and pb.quality <= 5 then
        self.iconNode:runAnimation(pb.quality)
    elseif pb.quality == -1 then
        self.iconNode:runAnimation("item")
    else
        self.iconNode:runAnimation("0")
    end
end

local SignPanel = class("SignPanel", PanelBase)

function SignPanel.create()
    return SignPanel.new({ csbName = "layers/7day.csb"})
end

function SignPanel:ctor(params)
    SignPanel.super.ctor(self, params)
    self:enableNodeEvents()

    for i=1,7 do
        self["item" .. i] = SignItem.seek(self, "signNode_" .. i)
    end

    self.next = nil
end

function SignPanel:onEnter()
    SignPanel.super.onEnter(self)

    self:runAnimation("in")
    local function onPanelClosed(reason)
        self:runAnimation("out", false, function()
            self:close("sign")
        end)
    end
    -- dump(playerManager.signs)
    local signsData = table.values(playerManager.signs)
    -- dump(signsData)
    for i,v in ipairs(signsData) do
        local item = self["item" .. i]
        if item then
            --loading info
            local data = resMgr:getItemData(v.item)
            v.path = data.path
            v.quality = data.quality
            v.name = data.name
            item:refresh(v)
        end
        if v.signed == false and self.next == nil then
            self.next = item
            self.next.pb = v
        end
    end

    if self.next ~= nil then
        self.next:runAnimation("selected")
    end

    self.pb = playerManager.souls[playerManager.config.showSoul]

    local script = panelFactory:createPanel(panelFactory.Panels.StoryScriptPanel,function()end):addTo(self)
    script:runScript(resMgr:getIconPath(resMgr.IconType.SIGN_7_DAY,self.pb.class_id), function()
        print("runScript end")
        script:close()
        if playerManager.signed == false then
            local pb    = pbBuilder:build({ proto = "data/pb/interface/receiveSign.pb",
                                            desc  = "interface.receiveSign.Request",
                                            input = {id = self.next.pb.class_id}})

            ws:send( "RECEIVESIGN", pb, function(resultCode, des, data)
                if resultCode == 0 then
                    -- if  self.next.type == "SOUL" then
                    --     panelFactory:createPanel(panelFactory.Panels.DeedResultPanel,onPanelClosed,{id = self.pb.class_id})
                    --        :addTo(self)
                    -- else
                    panelFactory:createPanel( panelFactory.Panels.GetPanel, onPanelClosed,self.next.pb):addTo(self)
                    -- end
                    playerManager.signed = true
                else
                    -- 服务器错误
                    self:runAnimation("out", false, function()
                        self:close("sign")
                    end)
                end
            end)
        else
            self:runAnimation("out", false, function()
                self:close("sign")
            end)
        end
    end, false, false)
end


return SignPanel

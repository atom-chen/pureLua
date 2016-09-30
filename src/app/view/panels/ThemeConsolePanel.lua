local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local StatesButton  = import("..fragment.StatesButton", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local playerMgr  = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resMgr  = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()


local ThemeItem = class("ThemeItem", AnimationNode)

function ThemeItem.create()
    return ThemeItem.new({csbName = "nodes/theme/theme_list.csb"})
end

function ThemeItem:ctor()
    self:enableNodeEvents()

    self:mapUiElements({"titleLabel1","titleLabel2","stateNode"})
end

function ThemeItem:onEnter()
    -- self:runAnimation("in")
end

function ThemeItem:refresh(pb)
    local function _writeInfo(info)
        self.titleLabel1:setString(info.name)
        self.titleLabel2:setString(info.name)
    end

    local function _writeState(state)
        self.stateNode:runAnimation(state)
    end

    if pb.info then
        _writeInfo(pb.info)
    end
    if pb.state then
        _writeState(pb.state)
    end
end


local ThemeConsolePanel = class("ThemeConsolePanel", PanelBase)


function ThemeConsolePanel.create(params)
    params.csbName = "layers/theme.csb"
    return ThemeConsolePanel.new(params)
end

function ThemeConsolePanel:ctor(params)
    ThemeConsolePanel.super.ctor(self, params)
    self:enableNodeEvents()

    girl.addTouchEventListener(self,{swallow = true})

    self.cb = params.cb
    self:mapUiElements({"listView", "titleLabel", "infoLabel", "viewImage"})

    for i=1,6 do
        self:mapUiElement("btn"..i, function()
            return StatesButton.seek( self, "p"..i, i.."_on", "normalTakeButton" )
        end)
        self["btn" .. i]:setButtonTag(i)
    end
    self.selectPage = 1
    self.selectIndex = 1
end

function ThemeConsolePanel:onEnter()
    ThemeConsolePanel.super.onEnter(self)

    -- self.btn1:setState("")
    self:runAnimation("in")

    self:onButtonClicked("returnButton", function()
        self:runAnimation("out", false, function()
             display.popScene()
        end)
    end)

    self:onButtonClicked("shopButton", function()
    end)

    self:onButtonClicked("useButton", function()
        -- dump(self.group[self.selectIndex])
        local itemPb = self.group[self.selectIndex]
        if itemPb.state == "SELECTED" then
            return
        end

        local pb = pbBuilder:build({   proto = "data/pb/interface/useDecoration.pb",
                                       desc  = "interface.useDecoration.Request",
                                       input = { id = itemPb.class_id  } })

        ws:send( "USE_DECORATION", pb, function(resultCode, des, data)
            if resultCode == 0 then
                if self.cb then
                    self.cb("use", self.group[self.selectIndex])
                end
                self:refresh(false)
            end
        end)

    end)

    self:onButtonClicked("showButton", function()
        self:runAnimation("backin")
        if self.cb then
            self.cb("show", self.group[self.selectIndex])
        end
    end)

    self:onButtonClicked("returnButton", function()
        self:runAnimation("backout")
        if self.cb then
            self.cb("back")
        end
    end)

    for i=1,6 do
        self["btn" .. i]:onClicked(function(event)
            self.selectPage = event.target:getTag()
            self.selectIndex = 1
            self:refresh(true)
        end)
    end

    self.listView:addEventListener(function(sender, eventType)
        if eventType ~= 0 then
            self.selectIndex = sender:getCurSelectedIndex()+1
            local itemPb = self.group[self.selectIndex]
            -- print("select child index = ",self.selectIndex)
            if itemPb.state == "NEW" then
                local pb = pbBuilder:build({   proto = "data/pb/interface/lookDecoration.pb",
                                               desc  = "interface.lookDecoration.Request",
                                               input = { id = itemPb.class_id  } })

                ws:send( "LOOK_DECORATION", pb, function(resultCode, des, data)
                    if resultCode == 0 then
                        self:refresh(false)
                    end
                end)
            else
                self:refresh(false)
            end
        end
    end)

    self:refresh(true)
end

function ThemeConsolePanel:onExit()
    ThemeConsolePanel.super.onExit(self,"ThemeConsolePanel")
    self:removeAllListCell()
end

function ThemeConsolePanel:removeAllListCell()
    -- local items = self.listView:getItems()
    -- for _,v in pairs(items) do
    --     local item = v:getChildByTag(100):release()
    -- end
    self.listView:removeAllItems()
end

ThemeConsolePanel.DecorationType = {
    WINDOWS              = 1;
    TABLE                = 2;
    FURNITURE			 = 3;
    WALLPAPER			 = 4;
    FLOOR				 = 5;
    DECORATION           = 6;
    SCENERY 	         = 7;
}

function ThemeConsolePanel:getDecorationGroup(type)
    local group = {}
    -- dump(playerMgr.decorations)
    for _,v in pairs(playerMgr.decorations) do
        if self.DecorationType[v.info.type] == type then
            table.insert(group, v)
        end
    end
    return group
end

function ThemeConsolePanel:refresh(rl)
    -- 刷新下面的分类
    for i=1,6 do
        self["btn" .. i]:setState(i.."_off")
    end
    self["btn" .. self.selectPage]:setState(self.selectPage.."_on")

    -- 获取分类列表数据
    self.group = self:getDecorationGroup(self.selectPage)
    -- dump(playerMgr.decorations)
    -- dump(self.group)
    if #self.group <= 0 then
        return
    end

    -- 刷新listview
    if rl then
        -- self.selectIndex = 1
        self:removeAllListCell()

        for i=1,#self.group do
            local event_banner = ThemeItem.create()
            event_banner:setTag(100)
            -- event_banner:retain()
            event_banner:runAnimation("select")

            local custom_item = ccui.Layout:create()
            custom_item:setTag(1000+i)
            -- custom_item:retain()
            custom_item:setTouchEnabled(true)
            custom_item:setContentSize(cc.size( event_banner:getCascadeBoundingBox().width, event_banner:getCascadeBoundingBox().height))
            event_banner:setPosition(cc.p(custom_item:getContentSize().width / 2.0, custom_item:getContentSize().height / 2.0))
            custom_item:addChild(event_banner)
            self.listView:pushBackCustomItem(custom_item)
        end
    end

    for _,v in pairs(self.listView:getItems()) do
        local itemTag = v:getTag() - 1000
        local banner = v:getChildByTag(100)
        banner:refresh(self.group[itemTag])
    end

    -- 刷新详情
    self.titleLabel:setString(self.group[self.selectIndex].info.name)
    self.infoLabel:setString(self.group[self.selectIndex].info.instruction)
    self.viewImage:setTexture(resMgr:getIconPath(resMgr.IconType.THEME_VIEW, self.group[self.selectIndex].class_id))

    -- 刷新item状态
    for i=1,#self.group do
        local item = self.listView:getChildByTag(1000+i):getChildByTag(100)
        if self.selectIndex == i then
            item:runAnimation("select")
        else
            item:runAnimation("normal")
        end
    end
end

return ThemeConsolePanel

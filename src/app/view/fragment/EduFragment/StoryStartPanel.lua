
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase              = import("...controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode          = import("...controls.CocostudioNode", CURRENT_MODULE_NAME)
local HomePanel              = import("...panels.HomePanel", CURRENT_MODULE_NAME)

-- singleton
local panelFactory           = import("...controls.PanelFactory", CURRENT_MODULE_NAME) :getInstance()
local musicManager           = import("...controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

--
-- 主界面
--
local StoryStartPanel = class("StoryStartPanel", PanelBase)

function StoryStartPanel.create( params )
    params.csbName = "layers/quest/talk_title.csb"
    return StoryStartPanel.new(params)
end

function StoryStartPanel:ctor(params)
    StoryStartPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self.pb = params.pb

    -- self:mapUiElements({"contentText", "numberLabel"})
    -- dump(self.pb)

end

function StoryStartPanel:onEnter( )
    StoryStartPanel.super.onEnter(self)
    self:runAnimation("in")
    self:refresh()
    self.tempDo = false
    girl.addTouchEventListener(self,{swallow = true,
    onEnded = function(touch, event)
        if self.tempDo then
            return
        end
        self:runAnimation("out", false, function()
            self:close()
        end)
        -- girl.removeAllEventListeners(self)
        self.tempDo = true
    end})
end

function StoryStartPanel:onExit()
    StoryStartPanel.super.onExit(self)
end

function StoryStartPanel:refresh()

    local function _writeContent(content)
        -- self.contentText:setString(content)
    end

    local function _writeNumber(num)
        -- self.numberLabel:setText(tostring(num))
    end

    if self.pb then
        _writeContent(self.pb.name)
        _writeNumber(2)
    end
end

return StoryStartPanel

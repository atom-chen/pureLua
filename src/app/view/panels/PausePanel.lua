local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local battleManager = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local PausePanel = class("PausePanel", PanelBase)

function PausePanel.create()
  return PausePanel.new({ csbName = "layers/battle/pause.csb"})
end

PausePanel.Events = table.enumTable
{
    -- 返回按键
    "ON_BUTTON_BACK",
    "ON_SKILL_SOUL",
}

function PausePanel:ctor(params)
  PausePanel.super.ctor(self, params)
  self:enableNodeEvents()

  self.cb = params.cb

  self:mapUiElements({"pauseMiddleNode","pauseLeftNode","pauseRightNode","leftRoundNode","rightRoundNode","pauseBackNode",
                       "pauseContinueNode","sliderEffectMusic","sliderBackMusic"})

end

function PausePanel:onEnter()
    PausePanel.super.onEnter(self)
    musicManager:play(girl.UiMusicId.PAUSE)
    girl.addTouchEventListener(self, {swallow = true})
    self.pauseLeftNode:runAnimation("in", false)
    self.pauseRightNode:runAnimation("in", false)
    self.pauseMiddleNode:runAnimation("in", false)
    self.leftRoundNode:runAnimation("loop", true)
    self.rightRoundNode:runAnimation("loop", true)
    self:onButtonClicked("pause_Button_right", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.pauseContinueNode:runAnimation("click",false)
        self.pauseLeftNode:runAnimation("out", false)
        self.pauseRightNode:runAnimation("out", false)
        self.pauseMiddleNode:runAnimation("out", false)
        self:runAnimation("out", false, function()
            self:close("resume")
        end)
    end)

    self:onButtonClicked("pause_Button_left", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.pauseBackNode:runAnimation("click",false)
        self:runAnimation("out", false, function()
            self:getParent():callfunc({ event = self.Events.ON_BUTTON_BACK})
            self:close()
        end)
    end)

    self.sliderBackMusic:setPercent(musicManager:getMusicVolume()*100)
    self.sliderEffectMusic:setPercent(musicManager:getEffectsVolume()*100)

    local function effmChangedEvent(sender,eventType)
        if eventType == ccui.SliderEventType.percentChanged then
            local slider = sender
            local percent = "Percent " .. slider:getPercent()
            print(percent)
            musicManager:setEffectsVolume(slider:getPercent()/100.0)
        end
    end 

    local function bgmChangedEvent(sender,eventType)
        if eventType == ccui.SliderEventType.percentChanged then
            local slider = sender
            local percent = "Percent " .. slider:getPercent()
            musicManager:setMusicVolume(slider:getPercent()/100.0)
            print(percent)
        end
    end 

    self.sliderBackMusic:addEventListener(bgmChangedEvent)
    self.sliderEffectMusic:addEventListener(effmChangedEvent)
end

return PausePanel

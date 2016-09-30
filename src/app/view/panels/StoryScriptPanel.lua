local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local BgImageNode   = import("..fragment.BgImageNode", CURRENT_MODULE_NAME)
-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local storyScript   = import("..edu.StoryScript", CURRENT_MODULE_NAME):getInstance()

local StoryScriptPanel = class("StoryScriptPanel", PanelBase)


function StoryScriptPanel.create()
    return StoryScriptPanel.new({ csbName = "layers/quest/Quest_talk.csb"})
end

function StoryScriptPanel:ctor(params)
    StoryScriptPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self:mapUiElements({"skipButton"})
    self.bgImage = BgImageNode.seek(self,"bgImage")
end

function StoryScriptPanel:onEnter()
    StoryScriptPanel.super.onEnter(self)
    self:onButtonClicked("logButton", function()
    end)
end

function StoryScriptPanel:runScript(path, cb, showBg, showSkip, gate)
    if showBg == nil then
        showBg =  true
    end

    if showSkip == nil then
        showSkip =  true
    end

    if showBg == true then
        self.bgImage:show()
    else
        self.bgImage:hide()
    end

    if showSkip == true then
        self.skipButton:show()
    else
        self.skipButton:hide()
    end

    if gate then
        panelFactory:createPanel( panelFactory.Panels.StoryStartPanel, nil, { pb = gate } ):addTo(self, storyScript.Z_START)
    end

    self:onButtonClicked("skipButton", function()
        if cb then cb() end
    end)

    storyScript:setRootNode(self)
    storyScript:run(path, cb)
end

return StoryScriptPanel

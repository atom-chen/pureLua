local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local StatesButton  = import("..fragment.StatesButton", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local SmallMapPanel = class("SmallMapPanel", PanelBase)

function SmallMapPanel.create()
  return SmallMapPanel.new({ csbName = "layers/quest/Quest_part.csb"})
end


function SmallMapPanel:ctor(params)
  SmallMapPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self.select = 0

  self:mapUiElements({"mapEnterNode","mapEnterButton","mapEnterBackButton","mapBackButton"})

  for i=1,4 do
    -- self:mapUiElement("story_"..i)
    self["onButton"..i] = StatesButton.seek(self,"story_"..i)
  end

end

function SmallMapPanel:onEnter()

  SmallMapPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {swallow = true})
  self:runAnimation("in")

 -- self.arrowNode = AnimationNode.new({csbName = "nodes/quest/arrow.csb"})
 -- self.arrowNode:hide()

  local function onPanelClosed(reason)
    if reason == "fight" then
       --self.battle:resumeAll()
       --print("恢复 BattlePanel")
    end
  end

  for i = 1,4 do
    self["onButton"..i]:setButtonTag(i)

    self["onButton"..i]:onClicked(function(event)
      musicManager:play(6000008)
        -- print(i)
       print(event.target:getTag())
       self.select = event.target:getTag()
       --  self.arrowNode:show()
       --  self.arrowNode:addTo(event.target)
       --  self.arrowNode:setPosition(cc.p(0,80))
       self.mapEnterNode:runAnimation("in")
        --self.mapEnterButton:show()
       self.mapEnterNode:show()

    end)

  end
  self.mapBackButton:onClicked(function()
     -- self:removeFromParent()
      self:close("smallMap")
    end)

    --self.enter = 0
    self.mapEnterButton:onClicked(function()
       --print("enter")
       musicManager:play(6000004)

       self.mapEnterNode:hide()
       self.mapEnterNode:runAnimation("out", false, function()
       end)
       local questTeam = panelFactory:createPanel(panelFactory.Panels.QuestTeamPanel,onPanelClosed,{gateId = "110"..self.select}):addTo(self:getParent())
       questTeam:setLocalZOrder(100)





  end)

  self.mapEnterBackButton:onClicked(function()
      musicManager:play(6000006)

      self.mapEnterNode:runAnimation("out",false,function()
        self.mapEnterNode:hide()
       end )


  end)
end

return SmallMapPanel

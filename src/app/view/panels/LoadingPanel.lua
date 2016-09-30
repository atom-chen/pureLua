local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()



local LoadingPanel = class("LoadingPanel", PanelBase)


function LoadingPanel.create(params)
  return LoadingPanel.new({ csbName = "layers/loading.csb"})
end

function LoadingPanel:ctor(params)

  LoadingPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({ "loading", "musicGirl", "bg", "loadingPanel"})

    local num = math.random(10)

    local numTable = { [1] = 1, [2] = 3, [3] = 5, [4] = 7 ,[5] = 14,[6] = 19,[7] = 23,[8] = 24,[9] = 29,[10] = 30}

    self.girl = AnimationNode.new({csbName = string.format("nodes/loading/girl_%02d.csb",numTable[num] )  }):addTo(self)

 end

function LoadingPanel:onEnter()

   LoadingPanel.super.onEnter(self)
   girl.addTouchEventListener(self, {swallow = true})
   self.loadingPanel:hide()
   self.girl:setPosition(self.musicGirl:getPosition())
   self.loading:runAnimation("loop",true)
   self.girl:runAnimation("loop",true)

   -- local callfun = cc.CallFunc:create(function()
   --     self:stopAllActions()
   --     self:hide()
   --     self:getParent():closeSelf()
   -- end)

   -- local seq  = cc.Sequence:create(cc.DelayTime:create(3),callfun)
   -- self:runAction(seq)
end

function LoadingPanel:showBackGround(bShow)
    self.bg:setVisible(bShow)
end



return LoadingPanel

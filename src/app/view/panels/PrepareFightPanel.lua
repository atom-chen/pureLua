local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local PrepareFightPanel = class("PrepareFightPanel", PanelBase)

function PrepareFightPanel.create()
  return PrepareFightPanel.new({ csbName = "layers/battle/battlestart.csb"})
end

function PrepareFightPanel:ctor(params)
  PrepareFightPanel.super.ctor(self, params)
  self:enableNodeEvents()

end

function PrepareFightPanel:onEnter()
	 PrepareFightPanel.super.onEnter(self)
	 girl.addTouchEventListener(self, {swallow = true})
     self:runAnimation("in",false,function()
     self:close("fight")
  end)
     musicManager:play(girl.UiMusicId.BATTLE_START)
end


function PrepareFightPanel:onExit()

	PrepareFightPanel.super.onExit(self)
	--printInfo("[PrepareFightPanel] onExit")
	MessageManager.sendMessage(girl.MessageLayer.BATTLE,girl.BattleMessage.BATTLE_RUNAI)

end

return PrepareFightPanel

local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local panelFactory = import("..controls.PanelFactory"):getInstance()
local musicMgr     = import("..controls.MusicManager"):getInstance()


local BattleScene = class("BattleScene", import(".SceneBase", CURRENT_MODULE_NAME))

-- BattleScene.RESOURCE_FILENAME = "scenes/GameMain.csb"

function BattleScene:onCreate()

end

function BattleScene:onEnter()
end

function BattleScene:onExit()

end

return BattleScene

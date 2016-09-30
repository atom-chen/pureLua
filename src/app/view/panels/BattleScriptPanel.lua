local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)


-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local battleScript  = import("..edu.BattleScript", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()


local BattleScriptPanel = class("BattleScriptPanel", PanelBase)


function BattleScriptPanel.create()
    return BattleScriptPanel.new({ csbName = "layers/battle/battleTalk.csb"})
end

function BattleScriptPanel:ctor(params)
    BattleScriptPanel.super.ctor(self, params)
    self:enableNodeEvents()
    dump(params)
end

function BattleScriptPanel:onEnter()
    BattleScriptPanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})
    battleScript:setRootNode(self)
end

function BattleScriptPanel:runScript(path, cb)
    battleScript:run(path, cb)
end


return BattleScriptPanel


local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase     = import("..controls.PanelBase")
local AnimationNode = import("..controls.CocostudioNode")
local Hero 		    = import("..battle.Hero", CURRENT_MODULE_NAME)

-- singleton
local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory"):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local playerManager = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local battleManager = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
--
--
local ResultWinPanel = class("ResultWinPanel", PanelBase)

function ResultWinPanel.create( params )

    return ResultWinPanel.new({csbName = "layers/result/Result_competed.csb"})

end

function ResultWinPanel:ctor(params)
    ResultWinPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self.inEnd = false
   
end

function ResultWinPanel:onEnter( )

      ResultWinPanel.super.onEnter(self)
      girl.addTouchEventListener(self, {
                               swallow = true,
                               onBegan = function()
                                    if self.inEnd then
                                      self:runAnimation("out", false, function()
                                          self:close()
                                      end)
                                      self.inEnd = false
                                    else
                                       return
                                    end
                               end
                               })

      self:runAnimation("in", false,function()
          self.inEnd = true
      end)
      
end


return ResultWinPanel

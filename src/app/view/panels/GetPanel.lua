local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local GetPanel = class("GetPanel", PanelBase)


function GetPanel.create(pb)
    return GetPanel.new({ csbName = "layers/draw/getOther.csb",pb = pb})
end

function GetPanel:ctor(params)
    GetPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self:mapUiElements({"equipNameText","equipNode","itemIconSprite"})
    self.pb = params.pb
end

function GetPanel:onEnter()
    GetPanel.super.onEnter(self)
    self:runAnimation("10")
    musicManager:play(girl.UiMusicId.ITEM_GET)

    girl.addTouchEventListener(self,{
        onBegan = function(touch,event)
            self:close()
            return true
        end
    })
    self:refresh(self.pb)
end


function GetPanel:refresh(pb)
    -- dump(pb)
    -- local data = resMgr:getItemData(pb)
    -- dump(data)
    self.itemIconSprite:setTexture(pb.path)
    self.equipNameText:setString(pb.name)
end
return GetPanel

local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local Soul          = import("..battle.Soul", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager",CURRENT_MODULE_NAME):getInstance()
local resManager    = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local battleManager = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
local EXskillPanel  = class("EXskillPanel", PanelBase)

function EXskillPanel.create(params)
  local colorType = {"Red","Yellow","Blue","Green","Purple"}
  local exName = "layers/battle/EXskill"..colorType[params.soul.info.color]..".csb" --params.soul.info.type..
  return EXskillPanel.new({ csbName = exName,soul = params.soul})
end

function EXskillPanel:ctor(params)
    EXskillPanel.super.ctor(self, params)
    --dump(params)
    self.soul = params.soul
    self.targets = {}
    self:enableNodeEvents()
    self:mapUiElements({"skillNameNode","girlSprite","girlSprite_1"})

    local nameSprite  = AnimationNode.seek(self.skillNameNode,"skillName")
   
    nameSprite:setTextureByPlist(resManager:getIconPath(resManager.IconType.SOUL_SKILL,self.soul.info.class_id))

    self.objNode = cc.Node:create()
    self.objNode:addTo(self,190)
    --self.aa = nil
    MessageManager.addMessage(self, girl.MessageLayer.EXSKILL, girl.BattleMessage.ADD_FRONT_EFF,handler(self, self.addFrontEff))
    MessageManager.addMessage(self, girl.MessageLayer.EXSKILL, girl.BattleMessage.ADD_BG_EFF,handler(self, self.addBgEff))
    MessageManager.addMessage(self, girl.MessageLayer.EXSKILL, girl.BattleMessage.SET_LAYER_FOR_MONSTER,handler(self, self.setLayerForObj))
end


function EXskillPanel:onEnter()

    EXskillPanel.super.onEnter(self)
    girl.addTouchEventListener(self, {swallow = true})
    --self.showSoulPic = self.girl_01_1
    self.girlSprite:setTexture(resManager:getIconPath( resManager.IconType.SOUL_ORIGIN,self.soul.info.class_id))
    self.girlSprite_1:setTexture(resManager:getIconPath( resManager.IconType.SOUL_ORIGIN,self.soul.info.class_id))
    self:runAnimation("in",false,function()
      	--self:close("aoyi")
        --dump(self.soul)

        local drawNode = cc.DrawNode:create()
        local polygon = {cc.p(0, 0), cc.p(display.width ,0), cc.p(display.width, display.height), cc.p(0, display.height)}
        drawNode:drawPolygon(polygon, 4, cc.c4f(0,0,0,1),1,cc.c4f(0,0,0,0))
        drawNode:setPosition(0,0)
        drawNode:addTo(self,0)

        self.cloneSoul = Soul.clone(self.soul)
        self.cloneSoul:retain()
        self.cloneSoul:addTo(self,200,999)
        self.cloneSoul:setPosition(display.width/2,display.height/2- 120 )
        self.cloneSoul:changeStatus(Soul.statusType.STATUS_EX,1)
        self.cloneSoul.isInExSkill = true
        self.cloneSoul.shadow:setVisible(false)
        --dump(self.cloneSoul.exSkillInfo)
        --背景层
        if self.cloneSoul.exSkillInfo.bgId>0 then
            local bgScbName = resManager:getResPath(self.cloneSoul.exSkillInfo.bgId)
            local bg = AnimationNode.new({csbName = bgScbName });
            -- dump(bg)
            bg:addTo(self)
            bg:setPosition(display.width/2,display.height/2 - 120)
            bg:runAnimation(bg.DefaultAnimation, false, function()
            end)
        end
        musicManager:play(self.soul.exSkillInfo.musicEffId) --3224711 施法音效
        self:onUpdate(handler(self,self.updateMonster))
        -- local rt = cc.rect(0,
        --     0,
        --     32,
        --     32)
        -- self.aa =  girl.createTestRect(rt):addTo(self,203)
    end)
    musicManager:play(self.soul.exSkillInfo.musicId) --施法语音

end
function EXskillPanel:onExit()

    EXskillPanel.super.onExit(self)
    self.cloneSoul:release()
    MessageManager.removeMessageByLayer(girl.MessageLayer.EXSKILL)

    battleManager.isAoyiAction = false

end
function EXskillPanel:updateMonster(dt)

    --dump(self.cloneSoul:getBonePosition("monster"))
    local bone = self.cloneSoul:getBoneData("monster")
    local x = self.cloneSoul:getPositionX()+bone.x
    local y = self.cloneSoul:getPositionY()+bone.y
    --printInfo("x:"..x.."    y:"..y)
    self.objNode:setPosition(x,y)
    self.objNode:setScaleX(bone.sx)
    self.objNode:setScaleY(bone.sy)
    self.objNode:setRotation(bone.r)
    --dump(bone)

end

--前景层特效
function EXskillPanel:addFrontEff()

    --dump(self.cloneSoul)
    -- dump(self.cloneSoul.exSkillInfo)
    local frontEffScbName = resManager:getResPath(self.cloneSoul.exSkillInfo.frontEffId)
    local frontEff = AnimationNode.new({csbName = frontEffScbName});
    frontEff:addTo(self,256)
    frontEff:setPosition(display.width/2,display.height/2 - 120)
    frontEff:runAnimation(frontEff.DefaultAnimation, false, function()
      end)

end
--背景层特效
function EXskillPanel:addBgEff()

    local bgEffScbName = resManager:getResPath(self.cloneSoul.exSkillInfo.bgEffId)
    local eff = AnimationNode.new({csbName = bgEffScbName });
    eff:addTo(self,10)
    eff:setPosition(display.width/2,display.height/2 - 120)
    eff:runAnimation(eff.DefaultAnimation, false, function()
      end)
end

--怪和释放者的顺序
function EXskillPanel:setLayerForObj(body,layer,msg,data)

    if data.type == "SET_LAYER_B" then
      self.objNode:setLocalZOrder(190)
    elseif data.type == "SET_LAYER_F" then
      self.objNode:setLocalZOrder(210)
    end

end

return EXskillPanel

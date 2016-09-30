local CURRENT_MODULE_NAME = ...

-- classes
local Bullet = import(".Bullet",CURRENT_MODULE_NAME)
local WarningNode = import(".WarningNode",CURRENT_MODULE_NAME)

-- singleton
local infoManager = import("...data.information.InfoManager"):getInstance()
local battleManager = import(".BattleManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()

local MapEvent = class("MapEvent", display.newNode)

function MapEvent.createWithId(id, pos)
  return MapEvent.new({id = id, pos = pos})
end

function MapEvent:ctor(params)
  self:enableNodeEvents()
  self.pos = params.pos
  self.pb  = infoManager:findInfo("mapevents","class_id",params.id)

  local size  = 25
  local drawNode = cc.DrawNode:create()
  local polygon = {cc.p(0, 0), cc.p(0, size ), cc.p(size , size), cc.p(size, 0)}
  drawNode:drawPolygon(polygon, 4, cc.c4f(1,0,0,1), 1,  cc.c4f(0,1,0,1))
  drawNode:setPositionY(300)
  --self:addChild(drawNode, 2000)

  -- test code end

end

function MapEvent:trigger()
  local node = self:getParent()
  --event类型为子弹

  if self.pb.event_type == 2 then

    -- print("创建warning，创建warning")
    MessageManager.sendMessage(girl.MessageLayer.BATTLE,girl.BattleMessage.ADD_WARNING,
                                { pos = self.pos,
                                  id = self.pb.bullet_id,
                                  angle = self.pb.bullet_angle,
                                  dmgValue = self.pb.bullet_damage,
                                  range = self.pb.bullet_width,
                                  height = self.pb.bullet_height,
                                  speed = self.pb.bullet_speed,
                                  camp = 1,
                                  target =node})


    -- print("创建warning结束，创建warning结束")
    -- event类型为BOSS出现警告动画
   elseif self.pb.event_type== 3 then
 
   -- dump(self.pb)
     MessageManager.sendMessage(girl.MessageLayer.BATTLE,girl.BattleMessage.BOSSCOMING_ADD,{bgmId = self.pb.changebgm_id})
    --bossComing:setPosition(self.pos)
  end

  self:removeFromParent()
end

function MapEvent:onEnter()
  self:onUpdate(handler(self, self.onUpdateSelf))
  table.insert(battleManager.eventPool, self)
end

function MapEvent:onUpdateSelf()
  for i,v in ipairs(battleManager.eventPool) do
    if v:getPositionX() <= battleManager.hero:getPositionX() then
      v:trigger()
      table.remove(battleManager.eventPool, i)
    end
  end
end


return MapEvent

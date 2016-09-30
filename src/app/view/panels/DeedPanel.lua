local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local TakeDeed      = import("..fragment.DeedPanelFragment.TakeDeed", CURRENT_MODULE_NAME)
local Hero          = import("..battle.Hero", CURRENT_MODULE_NAME)
local Soul          = import("..battle.Soul", CURRENT_MODULE_NAME)
-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local resMgr        = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()

local DeedPanel = class("DeedPanel", PanelBase)

function DeedPanel.create()
  return DeedPanel.new({ csbName = "layers/draw/draw.csb"})
end


function DeedPanel:ctor(params)
  DeedPanel.super.ctor(self, params)
  self:enableNodeEvents()
  self:mapUiElements({"heroPos", "rockGirlNode", "rockGirlSelfNode", "heroSit","leftArrowNode","rightArrowNode","girl_01_1","voiceButton",
  "colorNode","nameText","heroSit","star1","star2","star3","star4","star5","star6","drawTenceText","drawOnceText","bd_free1_1",
  "allNameText","allNameText_0","skillDetailButton","skillDetailNode","dexNameText","dexInsText","dskillNameText","dskillInsText"})
  self.rightArrowBtn = AnimationNode.seek(self["rightArrowNode"],"arrowButton")
  self.leftArrowBtn  = AnimationNode.seek(self["leftArrowNode"],"arrowButton")
  self:mapUiElement("takeDeed", function()
      return TakeDeed.seek(self, "takeDeedNode", handler(self, self.onTakeDeedEvents))
  end)
  self.getSoulId = 0

  self.canChange = true --是否能切换girl
end

function DeedPanel:onEnter()
  local bg =  panelFactory:createPanel(panelFactory.Panels.SceneBgPanel, onPanelClosed):addTo(self)
  bg:setLocalZOrder(-100)
  DeedPanel.super.onEnter(self)
  girl.addTouchEventListener(self, {
          swallow = true,
          onBegan = function(touch, event)
            self.recTouchPos = touch:getLocation()
            print(self.recTouchPos.x)
            print(self.recTouchPos.y)
            return true
          end,

          onMoved = function( touch, event)
              
          end,
          
          onEnded = function(touch, event)
                local touchedLoc = touch:getLocation()
                print(touchedLoc.x)
                print(touchedLoc.y)
                if touchedLoc.x - self.recTouchPos.x > 50 then
                 
                     print("大于50向右划")
                     self:changeGirlRight()
                elseif touchedLoc.x - self.recTouchPos.x < -50 then
                     print("向左划")
                     self:changeGirlLeft()
                end
          end
  })

  self.bd_free1_1:setVisible(false)
  self:runAnimation("in")
  MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
  self.loopNode  = AnimationNode.seek(self.heroSit, "loopNode")
  self.loopNode:runAnimation("loop",true)
  self.heroSit:runAnimation("loop",true)
  self.soulTable = { [1] = 3, [2] = 5, [3] = 6, [4] = 7 ,[5] = 8,[6] = 24,[7] = 29}

  dump(self.soulTable)
  self.drawOnceText :setString(girl.Price.DRAWONCE)
  self.drawTenceText:setString(girl.Price.DRAWTENCE)
  self.index = 1
  self.showSoulSpine = Soul.createOnUiWithId(self.soulTable[1])
  self.showSoulSpine:addTo(self.heroPos)
  self.heroSit:runAnimation("loop", true)
  self.rockGirlSelfNode:runAnimation("rock", true)
  self.leftArrowNode:runAnimation("loop", true)
  self.rightArrowNode:runAnimation("loop", true)

  self.showSoulPic = self.girl_01_1
  -- sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.showSoulSpine.info.class_id))
  self.showSoulPic:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.showSoulSpine.info.class_id))
  self.nameText:setString(self.showSoulSpine.info.name)
  self.colorNode:runAnimation(string.format(self.showSoulSpine.info.type..self.showSoulSpine.info.color))


  self:refreshStar(self.showSoulSpine.info.star,self.showSoulSpine.info.class_id)


  self.leftArrowBtn:onClicked(function()
      musicManager:play(girl.UiMusicId.CLICK_BTN)
      self:changeGirlLeft()
  end)

  self.rightArrowBtn:onClicked(function()
      musicManager:play(girl.UiMusicId.CLICK_BTN)
      self:changeGirlRight()
  end)

  -- self.skillDetailButton:onClicked(function()
  -- self.skillDetailNode:runAnimation("in", false)
  -- end)

  self.voiceButton:onClicked(function()
    print("fkjdshfkjsodmmmmmmmmmmmmmmm")
    if self.showSoulSpine == nil then
        return
    end
       musicManager:playEx(string.format("sound/battle/z_soul%02d.mp3",self.showSoulSpine.info.class_id))
  end)

  self.operate = true
end


function DeedPanel:onExit()
  DeedPanel.super.onExit(self,"DeedPanel")
end

function DeedPanel:changeGirlLeft()

  if self.showSoulSpine == nil then
    print("太快了")
    return
  end

  self.showSoulSpine:removeFromParent()
  self.showSoulSpine = nil
  self.rockGirlNode:runAnimation("next_out",false,function()
      self.index = self.index+1
      if self.index >= table.getn(self.soulTable)+1 then
        self.index = 1
      end
      print("当前显示的元魂"..self.soulTable[self.index])
      self.showSoulSpine = Soul.createOnUiWithId(self.soulTable[self.index])
      --self.canChange = true
      self.showSoulSpine:addTo(self.heroPos)

      --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.showSoulSpine.info.class_id))
      self.showSoulPic:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.showSoulSpine.info.class_id))
      self.nameText:setString(self.showSoulSpine.info.name)
      self.colorNode:runAnimation( string.format(self.showSoulSpine.info.type..self.showSoulSpine.info.color))

      self:refreshStar(self.showSoulSpine.info.star,self.showSoulSpine.info.class_id)
      self.rockGirlNode:runAnimation("next_in",false)
  end)
end

function DeedPanel:changeGirlRight()

  if self.showSoulSpine == nil then
    print("太快了")
    return
  end

  self.showSoulSpine:removeFromParent()
  self.showSoulSpine = nil
  self.rockGirlNode:runAnimation("per_out",false,function()
      self.index = self.index-1
      if self.index == 0 then
        self.index = table.getn(self.soulTable)
      end

      print("当前显示的元魂"..self.soulTable[self.index])
      self.showSoulSpine = Soul.createOnUiWithId(self.soulTable[self.index])
      self.showSoulSpine:addTo(self.heroPos)

      --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.showSoulSpine.info.class_id))
      self.showSoulPic:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN,self.showSoulSpine.info.class_id))
      self.nameText:setString(self.showSoulSpine.info.name)
      self.colorNode:runAnimation( string.format(self.showSoulSpine.info.type..self.showSoulSpine.info.color))

      self:refreshStar(self.showSoulSpine.info.star,self.showSoulSpine.info.class_id)
      self.rockGirlNode:runAnimation("per_in",false)
 end)
end

function DeedPanel:refreshStar(num,id)

  for i=1,6 do
    self["star"..i]:setVisible(false)
  end

  local breachId = tonumber(id.."0"..num)
  self.breachInfo = infoManager:findInfo("breachs","class_id",breachId)
  dump(self.breachInfo)

  self.skillInfo = infoManager:findInfo("skills","class_id",self.breachInfo.skill1_id)
  self.allNameText:setString(self.skillInfo.name)

  --奥义名，奥义描述
  self.exSkillInfo = infoManager:findInfo("exSkills","class_id",id)
  self.allNameText_0:setString(self.exSkillInfo.exName)
end


function DeedPanel:onTakeDeedEvents(event)

  if not self.operate then
    return
  end

  if event == TakeDeed.Events.ON_BUTTON_NORMAL_ONCE then
    self.operate =  false
    print("gold:",playerMgr.status.diamond)
    if playerMgr.status.diamond < 60 then
      local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "奥辰能源不足",code = 999})
                      :addTo(self,200)
      self.operate =  true
      return
    end
    MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_OUT)
    local pb = pbBuilder:build({
          proto = "data/pb/interface/takecard.pb",
          desc  = "interface.takecard.Request",
          input = { times = "ONCE", coin = "DIMOND" }
        })
    ws:send( "STOREHOUSE", pb, function(resultCode, des, data)
         
      if resultCode == 102 then
         local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "金币不足",code = 999})
                     :addTo(self,200)
         self.operate =  true
      end

      local rep = pbBuilder:decode({ proto = "data/pb/interface/takecard.pb",
                                             desc  = "interface.takecard.Response",
                                             input = data})
      -- dump(rep.items)
      for k,v in pairs(rep.items) do
        print("id",v.id,"class_id:",v.class_id,"|type:",v.type,"count:",v.count)
        --table.insert(self.resultTable,1,v.class_id)
        self.getSoulId = v.class_id
        self.getType   = v.type
        self.getCount  = v.count
      end

    end)

    local parent = self:getParent()
    local function UUclosed(reason)
      print(reason)
      local function onResultClosed(reason)
          MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
          self.operate =  true
          self:setVisible(true)
      end
      if self.getType == "FRAGMENT" then
         local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,
                         {message = string.format("已经拥有%s，将获得%d个%s的记忆碎片",playerMgr.souls[self.getSoulId].info.name,
                         self.getCount,playerMgr.souls[self.getSoulId].info.name),
                         code = girl.MessageCode.GET_FRAGMENT})
                         :addTo(parent,200)
      end
      local result = panelFactory:createPanel(panelFactory.Panels.DeedResultPanel,onResultClosed,{id = self.getSoulId})
                     :addTo(parent)
                     :setLocalZOrder(150)
      self:setVisible(false)
           
    end

    local uu = panelFactory:createPanel(panelFactory.Panels.UUPanel,UUclosed)
                               :addTo(self)
                               :setLocalZOrder(150)
                               

    elseif event == TakeDeed.Events.ON_BUTTON_NORMAL_TEN  then
        return  
    end

end

return DeedPanel

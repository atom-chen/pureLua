local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local infoManager   = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local resMgr   = import("...data.information.ResManager", CURRENT_MODULE_NAME):getInstance()


local DeedResultPanel = class("DeedResultPanel", PanelBase)

function DeedResultPanel.create(params)
  return DeedResultPanel.new({csbName = "layers/draw/getGirl.csb",id = params.id})
end


function DeedResultPanel:ctor(params)
  DeedResultPanel.super.ctor(self, params)
  self:enableNodeEvents()

  self:mapUiElements({"skipButton","starColorBgNode","starColorBgNode","girlNode","girlinfoNode","typeNode","girlNameText","girl_01_1",
                      "starNode1","starNode2","starNode3","starNode4","starNode5","starNode6","Button_1"})

  self.single = false
  self.id     = params.id
  print("self.id"..self.id)

  self.info   = infoManager:findInfo("souls","class_id",self.id)
  dump(self.info)

  self.outTime = 1

end

function DeedResultPanel:onEnter()
  DeedResultPanel.super.onEnter(self)

    girl.addTouchEventListener(self, {
                               swallow = true,
                               onBegan = function()
                                     print(self.single)
                                     print(self.outTime)
                                    if self.single == false then
                                        self:runAnimation("single", false, function()
                                        self.single = true
                                        print("single")

                                        end)

                                    else
                                      self.outTime = self.outTime + 1 
                                      if self.outTime > 2 then
                                         return
                                      end
                                      self:runAnimation("out", false, function()
                                        -- local parent = self:getParent()
                                         self:close("result")
                                         -- parent.operate = true
                                         -- print("true")
                                      end)
                                    
                                    end
                                    return true
                               end
})
  --self.girl_01_1
  musicManager:play(girl.UiMusicId.DRAW_GET)
  --local sprite = cc.Sprite:create(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN, self.id))
  self.girl_01_1:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_ORIGIN, self.id))

  self.girlNameText:setString(self.info.name)
  self.typeNode:runAnimation(string.format(self.info.type..self.info.color),false)

  --   for i=self.info.star+1,6 do
  --     self["starNode"..i]:setVisible(false)
  -- end

  self:runAnimation("in",false,function()
      self.single = true
  end)
  --单抽隐藏skipButton
  self.Button_1:setVisible(false)




end

function DeedResultPanel:refresh()
--   girl.addTouchEventListener(self, {
--                                swallow = true,
--                                onBegan = function()
--                                      print(self.single)
--                                      print(self.outTime)
--                                     if self.single == false then
--                                         self:runAnimation("single", false, function()
--                                         self.single = true
--                                         print("single")
--                                         end)

--                                     else
--                                       self.outTime = self.outTime + 1 
--                                       if self.outTime > 2 then
--                                          return
--                                       end
--                                       self:runAnimation("out", false, function()
--                                         -- local parent = self:getParent()
--                                          self:close("result")
--                                          -- parent.operate = true
--                                          -- print("true")
--                                       end)

--                                     end
--                                end
-- })
end


return DeedResultPanel

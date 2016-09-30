local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)

local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()


local MessageBoxPanel = class("MessageBoxPanel", PanelBase)


function MessageBoxPanel.create(params)
  return MessageBoxPanel.new({ csbName = "layers/QuestionMessageBox.csb",message = params.message,code = params.code })
end

function MessageBoxPanel:ctor(params)

  MessageBoxPanel.super.ctor(self, params)
  self:enableNodeEvents()
  self:mapUiElements({"MessageBoxNode","messageText","rightNodeButton","leftNodeButton","Image_replace","confirmButton","cancelButton"})

  --self.rightButton =  AnimationNode.seek(self.rightNodeButton, "button")
  self.rightText = AnimationNode.seek(self.rightNodeButton, "text")

  self.rightText :setString("确定")

  self.leftText = AnimationNode.seek(self.leftNodeButton, "text")

  --self.rightText :setString("确定")

 -- print(params.message)
  self.message = params.message
  self.code = params.code 

 end

function MessageBoxPanel:onEnter()

   MessageBoxPanel.super.onEnter(self)
   girl.addTouchEventListener(self, {swallow = true})

   if self.code == girl.MessageCode.CHANGE_ASSEMBLAGE then

          self:twoButton()  

   elseif self.code == girl.MessageCode.CHANGE_SOULWASH then

       if self.message == girl.Message.SOULWASH2 or self.message == girl.Message.SOULWASH3 then
          self:oneButton()
       else
          self:twoButton() 
       end 
  else
      self.MessageBoxNode:runAnimation("1", false)
      self.messageText:setString(self.message)
      print(self.message)
      self:runAnimation("enter", false,function()
      end)
  

      self.confirmButton:onClicked(function()
         self.confirmButton:setTouchEnabled(false)
         musicManager:play(girl.UiMusicId.CLICK_BTN)
         print(self.code)
         if self.code == 0 then
             self:runAnimation("exit",false,function()
                  self.confirmButton:setTouchEnabled(true)
                  self:close("success")
             end)
         else 
             self:runAnimation("exit",false,function()
                  self.confirmButton:setTouchEnabled(true)
                  self:close()
             end)
         end
      end)  
   end



end

function MessageBoxPanel:oneButton()

   self.MessageBoxNode:runAnimation("1", false)
   self.messageText:setString(self.message)
   print(self.message)
   self:runAnimation("enter", false,function()
   end)
   self.confirmButton:onClicked(function()
       self.confirmButton:setTouchEnabled(false)
       musicManager:play(girl.UiMusicId.CLICK_BTN)
       self:runAnimation("exit",false,function()
            self.confirmButton:setTouchEnabled(true)
            self:close()
            print("哦，我知道了")
       end)
   end)


end

function MessageBoxPanel:twoButton()

  self.MessageBoxNode:runAnimation("2", false)
  self.messageText:setString(self.message)
  print(self.message)
  self:runAnimation("enter", false,function()
  end)
  -- 确定按钮
  self.confirmButton:onClicked(function()
      musicManager:play(girl.UiMusicId.CLICK_BTN)
      print(self.code)
      self:runAnimation("exit",false,function()
           self:close("yes")
      end)
  end)
  -- 取消按钮
  self.leftText:setString("取消")
  self.cancelButton:onClicked(function()
       musicManager:play(girl.UiMusicId.CLICK_BTN)
       self:runAnimation("exit",false,function()
            self:close("no")
       end)
  end)    


end



return MessageBoxPanel

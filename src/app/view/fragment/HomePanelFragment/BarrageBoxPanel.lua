
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase           = import("...controls.PanelBase", CURRENT_MODULE_NAME)
local AnimationNode       = import("...controls.CocostudioNode", CURRENT_MODULE_NAME)
local EditBoxNode         = import("...fragment.EditBoxNode", CURRENT_MODULE_NAME)

-- singleton
local panelFactory        = import("...controls.PanelFactory", CURRENT_MODULE_NAME) :getInstance()
local ws                  = import("....extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance("CHAT")
local pbBuilder           = import("....extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr           = import("....data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()


--
-- 主界面
--
local BarrageBoxPanel = class("BarrageBoxPanel", PanelBase)

function BarrageBoxPanel.create(cb)
    return BarrageBoxPanel.new({ csbName = "layers/BarrageBox.csb"})
end

function BarrageBoxPanel:ctor(params)
    BarrageBoxPanel.super.ctor(self, params)
    self:enableNodeEvents()

    self:mapUiElements({ "messageText", "textImageView", "onOffButton", "onImage", "offImage"})

    self.on = (playerMgr.config.barrageOn == 0)
end

function BarrageBoxPanel:onEnter()
    BarrageBoxPanel.super.onEnter(self)

    girl.addTouchEventListener(self,{swallow = true})

    cc.Director:getInstance():pause()

    local size = self.textImageView:getCascadeBoundingBox()
    self.edit     = EditBoxNode.create({
        size      = size,
        fontSize  = 20,
        maxLength = 20,
        fontColor = cc.c3b(255,255,255),
        inputMode = cc.EDITBOX_INPUT_MODE_ANY,
        defaultText = Strings.BARRAGE_INPUT
    }):addTo(self.textImageView)

    self:onButtonClicked("confirmButton", function()
        local message = self.edit:getText()
        if string.len(message) > 0 then
            print("BARRAGE_SEND message:", message)
            local pb    = pbBuilder:build({
                  proto = "data/pb/interface/sendBarrage.pb",
                  desc  = "interface.sendBarrage.Request",
                  input = { scene = "SHOWER", content = {message} }
            })

            ws:send( "BARRAGE_SEND", pb, function(resultCode, des, data)
                print("BARRAGE_SEND:"..resultCode)
            end)
        end
        self:close()
    end)

    self:onButtonClicked("onOffButton", function()
        local onValue

        if not self.on then
            onValue = 0
        else
            onValue = 1
        end
        print("onV:"..onValue)
        local pb    = pbBuilder:build({
              proto = "data/pb/interface/modifyConfig.pb",
              desc  = "interface.modifyConfig.Request",
              input ={ params = { {key= "barrageOn", value = tostring(onValue)} } }
          })

        ws:send( "MODIFY_CONFIG", pb, function(resultCode, des, data)
            if resultCode == 0 then
            end
        end)
        self:close()
    end)

    self:onButtonClicked("closeButton", function()
        self:close()
    end)
    self:refresh()
end

function BarrageBoxPanel:onExit()
    BarrageBoxPanel.super.onExit(self)
    cc.Director:getInstance():resume()
end

function BarrageBoxPanel:refresh()
    if self.on then
        self.onImage:show()
        self.offImage:hide()
    else
        self.onImage:hide()
        self.offImage:show()
    end
end

return BarrageBoxPanel

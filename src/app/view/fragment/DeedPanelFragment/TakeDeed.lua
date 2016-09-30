local CURRENT_MODULE_NAME = ...

local AnimationNode = import("...controls.CocostudioNode")

local TakeDeed = class("TakeDeed", AnimationNode)

local FilePath = "node/draw/draw_right.csb"

function TakeDeed.create(callback)
  return TakeDeed.new({
      callback = callback,
      csbName = FilePath
  })
end

function TakeDeed.seek(parentNode, nodeName, callback)
  return TakeDeed.new({
      parentNode = parentNode,
      nodeName = nodeName,
      callback = callback,
      csbName = FilePath
  })
end

function TakeDeed:ctor(params)
  TakeDeed.super.ctor(self, params)
  self:enableNodeEvents()

  self.cb = params.callback

  self:mapUiElements({"tenNode"})
end

TakeDeed.Events = table.enumTable
{
  "ON_BUTTON_NORMAL_ONCE",
  "ON_BUTTON_NORMAL_TEN"
}

function TakeDeed:onEnter()
  self:runAnimation("in")
  self.tenNode:runAnimation("loop", true)
 -- self.moneyTakeNode:runAnimation("normal")
  --self.normalTakeNode:runAnimation("select")

 --  self:onButtonClicked("normalTakeButton", function()
 --                         self:runAnimation("out", false, function()
 --                                             self.moneyTakeNode:runAnimation("normal")
 --                                             self.normalTakeNode:runAnimation("select")
 --                                             self:runAnimation("in")
 --                         end)
 -- end)

 --  self:onButtonClicked("moneyTakeButton", function()
 --                         self:runAnimation("out", false, function()
 --                                             self.moneyTakeNode:runAnimation("select")
 --                                             self.normalTakeNode:runAnimation("normal")
 --                                             self:runAnimation("in")
 --                         end)
 --  end)

  self:onButtonClicked("onceButton", function()
                       self.cb(self.Events.ON_BUTTON_NORMAL_ONCE)
  end)

  self:onButtonClicked("tenButton", function()
                        self.cb(self.Events.ON_BUTTON_NORMAL_TEN)
  end)
end


return TakeDeed

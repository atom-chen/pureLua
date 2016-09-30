local CURRENT_MODULE_NAME = ...

local AnimationNode    = import("...controls.CocostudioNode")

local BloodLabel = class("BloodLabel",AnimationNode)

BloodLabel.Type = {
  Critical  = 1,
  Rating    = 2,
  AddHp     = 3,--加血
}

function BloodLabel.create( type, num )
    return BloodLabel.new({
        csbName = "nodes/battle/hitNum.csb",
        type = type,
        num = num
        })
end


function BloodLabel:ctor(params)
    BloodLabel.super.ctor(self,params)
    self:enableNodeEvents();

    self.type = params.type
    self.num = params.num

    self:mapUiElements({"RatingLabel", "CriticalLabel","CriticalLabel_0"})
end

function BloodLabel:onEnter()
  self:setNumber(self.num)
  if self.type == self.Type.Rating then
    self:runAnimation("hit", false, function()
        self:removeFromParent()
    end)
  elseif self.type == self.Type.Critical then
    self:runAnimation("baoji", false, function()
        self:removeFromParent()
    end)
  elseif self.type == self.Type.AddHp then
    self:runAnimation("hp", false, function()
        self:removeFromParent()
    end)
  end
end

function BloodLabel:setNumber( num )
  --printInfo("blood num :"..num)
  local number = string.format("%d",num)
  if self.type == self.Type.Rating then
    self.RatingLabel:setString(number)
  elseif self.type == self.Type.Critical then
    self.CriticalLabel:setString(number)
  elseif self.type == self.Type.AddHp then
    self.CriticalLabel_0:setString(number)
  end
end




return BloodLabel

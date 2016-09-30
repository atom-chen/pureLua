local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode		= import("..controls.CocostudioNode")


local ImageLabel = class("ImageLabel", AnimationNode)

function ImageLabel.seek( parentNode, nodeName)
    return ImageLabel.new({
            parentNode 	= parentNode,
            nodeName	= nodeName,
    })
end

function ImageLabel:ctor(params)
	ImageLabel.super.ctor(self, params)
    self:enableNodeEvents()
    self:mapUiElements({"textLabel"})
    self.running = false
end

function ImageLabel:onExit()
    self:stopAllActions()
    -- self:unscheduleEx(self.scheduler)
end

function ImageLabel:setString(str)
    self.textLabel:setString(str)
end

-- function ImageLabel:setString(strings, func)
--     self.content = strings
--     self.contentLength = string.len(strings)
--     self.current = 0
--     self.textLabel:setString("")
--
--     local function refresh()
--         self.current = self.current + 3
--         local str = string.sub(self.content, 0, self.current)
--         self.textLabel:setString(str)
--
--         if self.current >= self.contentLength then
--             self:unscheduleEx(self.scheduler)
--             self.running = false
--             if func then
--                 local  seq = cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(func))
--                 self:runAction(seq)
--             end
--         end
--     end
--
--     if self.running == false then
--         self.scheduler = self:scheduleEx(refresh, 0.03)
--         self.running = true
--     end
-- end

return ImageLabel

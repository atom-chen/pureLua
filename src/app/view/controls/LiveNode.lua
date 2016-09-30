local fileUtils = cc.FileUtils:getInstance()



local LiveNode = class("LiveNode", function(params)
    dump(params)
    local LiveNode = nil
    if params.jsonName ~= nil and params.dir ~= nil then
        LiveNode = Live2DNode:load(params.dir,params.jsonName)
    else
        printError("[live2d] create Error params nil")
    end
    return LiveNode
end)

function LiveNode.load( fullPath )
	return LiveNode.new({   dir = string.match(fullPath,"(.+)/[^/]*%.%w+$") .. "/",
                            jsonName = string.match(fullPath,".+/([^/]*%.%w+)$") })
end

function LiveNode:ctor(params)
    -- self.ff = function ()
    --     self:say("music/27.mp3","music/27.moth", self.ff)
    --     print("**********************")
    -- end
    -- self:say("music/27.mp3","music/27.moth", self.ff)
    -- local cilp = cc.ClippingNode:create()

    self:setSacle(1.05)
end

function LiveNode:setSacle(s)
    local winRatio = display.width / display.height
    local designRatio = CC_DESIGN_RESOLUTION.width / CC_DESIGN_RESOLUTION.height
    self:setSacleX(s*(designRatio/winRatio))
end

LiveNode.TouchEvent = {
    NORMAL = "normal",  -- 正常状态
    HEAD   = "hair",    -- 头部
    BODY   = "body",    -- 身体
    CHEST  = "chest",   -- 胸部
    FACE   = "mouth",   -- 脸
    ALL    = "all"      -- 全身
}

function LiveNode:processTouch(x, y)
    if self:hitTest("head", x, y) then
        printInfo("touch head")
        self:runRandomExpression()
    elseif self:hitTest("body", x, y) then
        printInfo("touch body")
        self:runRandomMotion("tap_body_01", 2)
    elseif self:hitTest("chest", x, y) then
        printInfo("touch chest")
        self:runRandomMotion("tap_chest_01", 2)
    elseif self:hitTest("hair", x, y) then
        printInfo("touch hair")
        self:runRandomMotion("tap_hair_01", 2)
    elseif self:hitTest("mouth", x, y) then
        printInfo("touch mouth")
        self:runRandomMotion("tap_mouth_01", 2)
    end
end

function LiveNode:hit(x, y, event)

    if event then
        if self:hitTest(event, x, y) then
            return true
        else
            return false
        end
    end

    if self:hitTest(self.TouchEvent.HEAD, x, y) then
        return self.TouchEvent.HEAD
    elseif self:hitTest(self.TouchEvent.BODY, x, y) then
        return self.TouchEvent.BODY
    elseif self:hitTest(self.TouchEvent.CHEST, x, y) then
        return self.TouchEvent.CHEST
    elseif self:hitTest(self.TouchEvent.FACE, x, y) then
        return self.TouchEvent.FACE
    else
        return self.TouchEvent.NORMAL
    end
end

return LiveNode

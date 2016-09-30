local fileUtils = cc.FileUtils:getInstance()

-- 记录所有的Timeline
local CocostudioNode = class("CocostudioNode", function(params)
	-- dump(params)
	local CocostudioNode = nil
	if not params.parentNode then
		if not params.csbName then
			CocostudioNode = display.newLayer()
		else
			CocostudioNode = cc.CSLoader:createNode(params.csbName)
			if CocostudioNode then
				CocostudioNode.timeline = cc.CSLoader:createTimeline(params.csbName)
				CocostudioNode:runAction(CocostudioNode.timeline)
			else
				printInfo("[AN] createNode is nil filename:%s", params.csbName)
			end
		end
	else
		CocostudioNode = Helpers:seekNodeByName(params.parentNode,params.nodeName)
		if CocostudioNode then
			CocostudioNode.timeline = CocostudioNode:getActionByTag(CocostudioNode:getTag())
		else
			printInfo("[AN] seekNode is nil nodeName:%s", params.nodeName)
		end
	end

	if not CocostudioNode then
		dump(params,"[ERROR] CocostudioNode dump params :")
	end

	return CocostudioNode
end)

local timelines_data = nil

-- 默认播放所有的动画序列
CocostudioNode.DefaultAnimation = "DefaultAnimation"

function CocostudioNode.load(filename)
	return CocostudioNode.new({ csbName = filename })
end

function CocostudioNode.seek( parent, nodeName, filename)
	return CocostudioNode.new({csbName = filename,parentNode = parent,nodeName = nodeName})
end

function CocostudioNode:ctor( params )
	self:enableNodeEvents()
	self.csbName = params.csbName
end

function CocostudioNode:getActionTimeline(  )
	self:checkCocostudioNode()
	return self.timeline
end

function CocostudioNode:setActionTimeline( tl )
	self.timeline = tl
end

function CocostudioNode:onEnter()
	self:checkCocostudioNode()
end

function CocostudioNode:checkCocostudioNode(  )
	if self.csbName and nil == self.timeline then
		local tl = cc.CSLoader:createTimeline(self.csbName)
		self:setActionTimeline(tl)
		self:runAction(tl)
	end
end

function CocostudioNode:onExit()
	if self.csbName then
		self:setActionTimeline(nil)
	end
end

function CocostudioNode:runAnimation( action, loopParam, callback )
	-- 传数字进来统一转换
	if "string" ~= type(action) then
		action = tostring(action)
	end

	local loop = loopParam or false
    local tl = self:getActionTimeline()
	local duration = tl:getDuration() / 60.0

    if action == self.DefaultAnimation then
    	tl:gotoFrameAndPlay(0, loop)

	    if false == loop then
			tl:setLastFrameCallFunc(function()
				if callback then callback() end
			end)
	    end
	    return duration
    elseif tl:IsAnimationInfoExists(action) then
		local tl = self:getActionTimeline()
		tl:play(action, loop)

		if  false == loop then
			tl:setLastFrameCallFunc(function()
				if callback then callback() end
			end)
		end
	    return duration
    else
    	printError("[ERROR] timeline action name:"..action)
    	printError("[ERROR] timeline csbname:"..self.csbName)
    end
end

--[[
添加FrameEvent
params：
eventName = func
]]
function CocostudioNode:setFrameEventCallFunc(params)
	local function onFrameEvent(frame)
		if nil == frame or nil == params then
			return
		end

		local eventName = frame:getEvent()
		-- print("onFrameEvent:"..eventName)
		local func = params[eventName]
		if nil ~= func and "function" == type(func) then
			func({	type 	= girl.AnimationNodeEventType.ANIMATION_EVENT,
					params 	= eventName })
			return
		end

		-- 如果不存在对应的callback，则检查是不是存在 "_all"的callback
		local allEventFunc = params["_all"]
		if nil ~= allEventFunc and "function" == type(allEventFunc) then
			allEventFunc({	type 	= girl.AnimationNodeEventType.ANIMATION_EVENT,
							params 	= eventName })
		end
	end

	self:getActionTimeline():setFrameEventCallFunc(onFrameEvent)
end

function CocostudioNode:pause()
	self:getActionTimeline():pause()
	return self
end

function CocostudioNode:resume()
	self:getActionTimeline():resume()
	return self
end





return CocostudioNode

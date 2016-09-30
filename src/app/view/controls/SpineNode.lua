local fileUtils = cc.FileUtils:getInstance()



local SpineNode = class("SpineNode",display.newNode)

function SpineNode:ctor(params)
	if params.jsonName ~= nil or params.atlasName ~= nil then
		self.spineNode = sp.SkeletonAnimation:create(params.jsonName, params.atlasName, 1.0):addTo(self)
	else
		printError("[spine] create Error params nil")
	end
	self.flashCb = true
	self:enableNodeEvents()
	-- self.schedulePool = {}
end

function SpineNode.load( jsonName, atlasName )
	return SpineNode.new( {jsonName = jsonName, atlasName = atlasName} )
end

function SpineNode:onAnimation( callback )

	-- 开始
	if not callback  then
		return
	end
	if callback.onBegan then
		self.spineNode:registerSpineEventHandler(function (event)
			-- print(string.format("[spine] %d start: %s",
			-- event.trackIndex,
			-- event.animation))
			if callback.onBegan then
				callback.onBegan({type = girl.AnimationNodeEventType.ANIMATION_START,
							params 	= event.trackIndex })
			end

		end, sp.EventType.ANIMATION_START)
	end

	-- 中断
	if callback.onEnded then
		self.spineNode:registerSpineEventHandler(function (event)
			-- print(string.format("[spine] %d end:",
			-- event.trackIndex))
			if callback.onEnded then
				callback.onEnded({ 	type 	= girl.AnimationNodeEventType.ANIMATION_END,
							params 	= event.trackIndex })
			end
		end, sp.EventType.ANIMATION_END)
	end

	-- 正常完成
	if callback.onComplete then
		self.spineNode:registerSpineEventHandler(function (event)
			-- print(string.format("[spine] %d complete: %d",
			-- event.trackIndex,
			-- event.loopCount))
			if callback.onComplete then
				callback.onComplete({ 	type 	= girl.AnimationNodeEventType.ANIMATION_COMPLETE,
							params 	= event.trackIndex })
			end
		end, sp.EventType.ANIMATION_COMPLETE)
	end

end

function SpineNode:unRegisterSpineNode(type)
	self.spineNode:unregisterSpineEventHandler(type)
end

--
-- callback.onBegan
-- callback.onEnded
-- callback.onComplete
--
function SpineNode:addAnimation(action, loop, callback)
	self.spineNode:addAnimation( 0, action, loop )
	self:onAnimation(callback)
end

--
-- callback.onBegan
-- callback.onEnded
-- callback.onComplete
--
function SpineNode:runAnimation( action, loop, callback )
	self.spineNode:setAnimation( 0, action, loop )
	self:onAnimation(callback)
end

function SpineNode:setTimeScale(scale)
	self.spineNode:setTimeScale(scale)
end

function SpineNode:getTimeScale()
	self.spineNode:getTimeScale()
end

--[[
添加FrameEvent
params：
eventName = func
]]
function SpineNode:setFrameEventCallFunc(params)
	local function onFrameEvent(event)
		if nil == event or nil == params then
			return
		end
		-- print(string.format("[spine] %d event: %s, %d, %f, %s",
		-- event.trackIndex,
		-- event.eventData.name,
		-- event.eventData.intValue,
		-- event.eventData.floatValue,
		-- event.eventData.stringValue))

		local eventName = event.eventData.name
		-- print("onFrameEvent:"..eventName)


		-- local eventParam = nil
		-- if event.eventData.intValue ~= 0 then
		-- 	eventParam = event.eventData.intValue
		-- elseif event.eventData.floatValue ~= 0 then
		-- 	eventParam = event.eventData.floatValue
		-- elseif event.eventData.stringValue ~= nil then
		-- 	eventParam = event.eventData.stringValue
		-- end

		local func = params[eventName]
		if nil ~= func and "function" == type(func) then
			func(eventName, {intValue = event.eventData.intValue, floatValue = event.eventData.floatValue, stringValue = event.eventData.stringValue})
			return
		end

		-- 如果不存在对应的callback，则检查是不是存在 "_all"的callback
		local allEventFunc = params["_all"]
		if nil ~= allEventFunc and "function" == type(allEventFunc) then
			allEventFunc(eventName, {intValue = event.eventData.intValue, floatValue = event.eventData.floatValue, stringValue = event.eventData.stringValue})
		end
	end

	self.spineNode:registerSpineEventHandler(onFrameEvent, sp.EventType.ANIMATION_EVENT)
end

function SpineNode:setScaleX(scaleX)
	self.spineNode:setScaleX(scaleX)
end

function SpineNode:getSize()
	return self.spineNode:getBoundingBox()
end

function SpineNode:getBonePosition(bone)
	return self.spineNode:getBonePosition(bone)
end

function SpineNode:getBoneScale(bone)
	return self.spineNode:getBoneScale(bone)
end

function SpineNode:getBoneRotation(bone)
	return self.spineNode:getBoneRotation(bone)
end

function SpineNode:getBoneData(bone)
	--[[
		table x,y,sx,sy,r
	--]]
	return self.spineNode:getBoneData(bone)
end

function SpineNode:onExit()
	-- for i,v in ipairs(self.schedulePool) do
	-- 	local scheduler = cc.Director:getInstance():getScheduler()
	-- 	scheduler:unscheduleScriptEntry(v.schedule)
	-- 	v.schedule = nil
	-- 	table.remove(self.schedulePool, i)
	-- end
end

-- other node use onUpdate
-- function SpineNode:schedule(cb, dt)

-- 	local param = {cb = cb, dt = (dt or (1 / 60.0))}

-- 	if cb then
--     	param.schedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(cb,param.dt,false)
--     	table.insert( self.schedulePool, param )
-- 	end
-- end

-- function SpineNode:unschedule(cb)
-- 	for i,v in ipairs(self.schedulePool) do
-- 		if v.cb == cb then
-- 			local scheduler = cc.Director:getInstance():getScheduler()
-- 			scheduler:unscheduleScriptEntry(v.schedule)
-- 			v.schedule = nil
-- 			table.remove(self.schedulePool, i)
-- 		end
-- 	end
-- end


SpineNode.FLASH_RED = {r = 0, g = -255, b = -255}
SpineNode.FLASH_WHITE = {r = -255, g = -255, b = -255}

function SpineNode:flash( color, time )

	if self.flashCb == false then
		return
	end

	self.flashCb = false

	local time = time or 0.1
	local color = color or SpineNode.FLASH_RED
	local action = cc.TintBy:create(time, color.r, color.g, color.b)
	local action_back = action:reverse()
	local func = cc.CallFunc:create(function() self.flashCb = true end)
	
	-- self.spineNode:runAction( cc.RepeatForever:create(seq) )
	self.spineNode:runAction( cc.Sequence:create( action, action_back,func) )
end

return SpineNode

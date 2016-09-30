local CURRENT_MODULE_NAME = ...


local DevScript = class("DevScript",import(".ScriptMachine", CURRENT_MODULE_NAME))


local s_inst        = nil

function DevScript:getInstance()
	if nil == s_inst then
		s_inst = DevScript.new()
	end
	return s_inst
end

function DevScript:initGirls(data)
	printInfo("[id:%04d]:", self.index)
	for k,v in pairs(data) do
		printInfo("          初始化妹子:%s", k)
	end
	-- dump(data)
end

function DevScript:runScriptEnter(data)
	-- printInfo("runScriptEnter")
	printInfo("[id:%04d]:", self.index)
	for _,v in ipairs(data) do
		printInfo("          %s 妹子来了站在位置:%d",v.id,v.pos)
	end
	self:next()
end

function DevScript:runScriptExit(data)
	-- printInfo("runScriptExit")
	printInfo("[id:%04d]:", self.index)
	for _,v in ipairs(data) do
		printInfo("          妹子走了:%s",v.id)
	end
	self:next()
end

function DevScript:runScriptEnd(data)
	-- printInfo("runScriptEnd")
	printInfo("[id:%04d]:", self.index)
	printInfo("          结束脚本")
	-- self:next()
end

function DevScript:runScriptTalk(data)
	-- printInfo("runScriptThink")
	printInfo("[id:%04d]:", self.index)
	for _,v in ipairs(data.id) do
		printInfo("          %s 说: %s",v,data.talk)
	end
	if data.action then
		printInfo("          全部换个姿势: %s",data.action)
	end
	if data.expressions then
		printInfo("          全部换个表情: %s",data.expressions)
	end

	self:next()
end

function DevScript:runScriptThink(data)
	-- printInfo("runScriptThink")
	printInfo("[id:%04d]:", self.index)
	for _,v in ipairs(data.id) do
		printInfo("          %s 想: %s",v,data.talk)
	end
	if data.action then
		printInfo("          全部换个姿势: %s",data.action)
	end
	if data.expressions then
		printInfo("          全部换个表情: %s",data.expressions)
	end


	self:next()
end

function DevScript:runScriptSelect(data)
	-- printInfo("runScriptSelect")
	printInfo("[id:%04d]:", self.index)
	for i,v in ipairs(data) do
		printInfo("          选项{%d}: %s 跳转到剧情id: %04d",i, v.choice, v.go)
	end
	self:next()
end

function DevScript:runScriptJump(data)
	-- printInfo("runScriptJump")
	printInfo("[id:%04d]:", self.index)
	printInfo("          跳转剧本: %s",data)
	self:next()
end

function DevScript:runScriptChangeRes(data)
	printInfo("[id:%04d]:", self.index)
	for _,v in ipairs(data) do
		printInfo("          %s 更换资源: %s",v.id,v.res)
	end
	self:next()
end

function DevScript:runScriptChangeBg(data)
	printInfo("[id:%04d]:", self.index)
	printInfo("          更换场景: %s",data)
	self:next()
end

return DevScript

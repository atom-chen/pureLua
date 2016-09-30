local CURRENT_MODULE_NAME = ...


-- classes
--local Bullet      = import("...view.battle.Bullet", CURRENT_MODULE_NAME)
-- singleton
local panelFactory  = import("..controls.PanelFactory"):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local musicMgr      = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local ScriptMachine = class("ScriptMachine")

local s_inst        = nil

function ScriptMachine:getInstance()
	if nil == s_inst then
		s_inst = ScriptMachine.new()
	end
	return s_inst
end

function ScriptMachine:ctor()

end

function ScriptMachine:setRootNode(root)
	self.root = root
	print("setRootNode")
	girl.addTouchEventListener(self.root, {
								 swallow = true,
							 	 onEnded = handler(self,self.onTouchEnded)})
end

function ScriptMachine:run(path, func)
	self.index = 0
	-- 剧情脚本锁，广度遍历运行
	self.lock = 0
	-- struct
	self.girls = {}

	self.monsters = {}
	-- 是否自动
	self.auto = true
	-- 是否结束
	self.over = false
	-- 是否开启触摸
	self.onTouch = true

	local script = import(path, CURRENT_MODULE_NAME)

    self.func  = func

	local FUNCTIONS = {
		INIT 		= function(data) self:init(data) end,
		SCRIPT      = function(data) self:runScript(data) end,}

	local list = {}

	for k,v in pairs(script) do
		local func  = FUNCTIONS[k]
		if func then
			list[k] = {}
			list[k].func = func
			list[k].data = v
		else
			printInfo("Unhandled run func:"..k)
		end
	end

	list.INIT.func(list.INIT.data)
	list.SCRIPT.func(list.SCRIPT.data)

end

function ScriptMachine:init(data)
	local FUNCTIONS = {
		GIRLS       = function(data) self:initGirls(data) end,
		MONSTER     = function(data) self:initMonsters(data) end}

	for k,v in pairs(data) do
		print(k,v)
		local func  = FUNCTIONS[k]
		if func then
			func(v)
		else
			printInfo("Unhandled init func:"..k)
		end
	end
end

function ScriptMachine:runScript(data)
	printInfo("[sm] using base script {runScript}")
	self.script = data
	printInfo("[id:%04d]:", self.index)
	printInfo("          开始脚本", self.index)
	self:next()
end

function ScriptMachine:next()
	-- printInfo("self.lock:"..self.lock)
	-- if self.auto then
	-- 	printInfo("self.auto:"..tostring(self.auto))
	-- end
	-- printInfo("self.index:"..self.index)
	-- printInfo("self.over:"..tostring(self.over))

	if self.auto == true and
		self.over == false then

		self.index = self.index + 1
		self.lock = 0
	else
		if self.lock > 0 then
			self.lock = self.lock - 1
			printInfo("locked return")
			return
		else
			self.index = self.index + 1
			self.lock = 0
		end
	end
    -- printInfo("self.index"..self.index)
	local events    = self.script[self.index]

	-- printInfo("event func index :%d ", self.index)
	dump(events)
	local FUNCTIONS    = {
		ENTER          = function(data) self:runScriptEnter(data) end,
		CHANGE_BG	   = function(data) self:runScriptChangeBg(data) end,
		EXIT           = function(data) self:runScriptExit(data) end,
		END            = function(data) self:runScriptEnd(data) end,
		TALK           = function(data) self:runScriptTalk(data) end,
		THINK          = function(data) self:runScriptThink(data) end,
		SELECT         = function(data) self:runScriptSelect(data) end,
		JUMP           = function(data) self:runScriptJump(data) end,
        CHANGE_RES     = function(data) self:runScriptChangeRes(data) end,
		ADD_MONSTER    = function(data) self:runScriptAddMonster(data) end,
		REMOVE_MONSTER = function(data) self:runScriptRemoveMonster(data) end,
		PLAY_BGM       = function(data) self:runScriptPlayBgm(data) end,
		PLAY_SOUND     = function(data) self:runScriptPlaySound(data) end,
		CHANGE_POS     = function(data) self:runScriptChangePos(data) end,
		DO             = function(data) self:runScriptDo(data) end,
	}

	local list = {}
	for k,v in pairs(events) do
		-- printInfo("event func:%s ", k)
		local eventFunc  = FUNCTIONS[k]
		if eventFunc then
			self.lock = self.lock + 1
			table.insert(list, {func = eventFunc, data = v })
			-- func(v)
		else
			printInfo("Unhandled event func:"..k)
		end
	end

	local auto = true
	for _,v in ipairs(list) do
		dump(v.data)
		print(type(v.data))
		if type(v.data) == "table" and v.data.auto ~= nil then
			auto = v.data.auto
		end
	end
	-- print("ending:"..tostring(auto))
	self:setAuto(auto)
	for _,v in ipairs(list) do
		v.func(v.data)
	end
	-- dump(self)
end

function ScriptMachine:setIndex(index)
	self.index = index - 1
end

function ScriptMachine:enableTouch(enable)
	self.onTouch = enable
end

function ScriptMachine:onTouchEnded()
	printInfo("[sm] using base script {onTouchEnded}")
	if self.onTouch then
		-- self.auto = true
		self:next()
	end
end

function ScriptMachine:setAuto(auto)
	printInfo("[sm] using base script {setAuto}:"..tostring(auto))
	self.auto = auto
end

function ScriptMachine:initGirls(data)
	printInfo("[sm] using base script {initGirls}")
	self:next()
end

function ScriptMachine:initMonsters(data)
	printInfo("[sm] using base script {initMonsters}")
	self:next()
end


function ScriptMachine:runScriptEnter(data)
	printInfo("[sm] using base script {runScriptEnter}")
	self:next()
end

function ScriptMachine:runScriptExit(data)
	printInfo("[sm] using base script {runScriptExit}")
	self:next()
end

function ScriptMachine:runScriptEnd(data)
	printInfo("[sm] using base script {runScriptEnd}")
	self.over = true
	if self.func then
		self.func()
	end
end

function ScriptMachine:runScriptTalk(data)
	printInfo("[sm] using base script {runScriptTalk}")
	self:next()
end

function ScriptMachine:runScriptThink(data)
	printInfo("[sm] using base script {runScriptThink}")
	self:next()
end

function ScriptMachine:runScriptSelect(data)
	printInfo("[sm] using base script {runScriptSelect}")
	self:next()
end

function ScriptMachine:runScriptJump(data)
	printInfo("[sm] using base script {runScriptJump}")
	self:next()
end

function ScriptMachine:runScriptChangeRes(data)
	printInfo("[sm] using base script {runScriptChangeRes}")
	self:next()
end

function ScriptMachine:runScriptChangeBg(data)
	printInfo("[sm] using base script {runScriptChangeBg}")
	self:next()
end

function ScriptMachine:runScriptChangePos(data)
	printInfo("[sm] using base script {runScriptChangePos}")
	self:next()
end

function ScriptMachine:runScriptPlayBgm(data)
	printInfo("[sm] using base script {runScriptPlayBgm}")
	self:next()
end

function ScriptMachine:runScriptPlaySound(data)
	printInfo("[sm] using base script {runScriptPlaySound}")
	self:next()
end

function ScriptMachine:runScriptAddMonster(data)
	printInfo("[sm] using base script {runScriptAddMonster}")
	self:next()
end

function ScriptMachine:runScriptRemoveMonster(data)
	printInfo("[sm] using base script {runScriptRemoveMonster}")
	self:next()
end

function ScriptMachine:runScriptDo(data)
	printInfo("[sm] using base script {runScriptDo}")
	self:next()
end


return ScriptMachine

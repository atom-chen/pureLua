
local CURRENT_MODULE_NAME = ...

local s_database = nil
local InfoManager = class("InfoManager")

function InfoManager:getInstance()
	if nil == s_database then
		s_database = InfoManager.new()
	end
	return s_database
end

function InfoManager:ctor()
	self.files = { }		-- 加载的PB文件
end

local FILES = {
	heros = {
		proto    = "data/pb/game/hero.pb",
		message  = "tg.pb.Hero.All",
		filename = "data/bin/hero.bin"
	},
	roles = {
		proto    = "data/pb/game/role.pb",
		message  = "tg.pb.Role.All",
		filename = "data/bin/role.bin"
	},
	ress = {
		proto    = "data/pb/game/res.pb",
		message  = "tg.pb.Res.All",
		filename = "data/bin/res.bin"
	},
	souls = {
		proto    = "data/pb/game/soul.pb",
		message  = "tg.pb.Soul.All",
		filename = "data/bin/soul.bin"
	},
	monsters = {
		proto    = "data/pb/game/monster.pb",
		message  = "tg.pb.Monster.All",
		filename = "data/bin/monster.bin"
	},
	mapinfos = {
		proto    = "data/pb/game/mapinfo.pb",
		message  = "tg.pb.MapInfo.All",
		filename = "data/bin/mapinfo.bin"
	},
	skills = {
		proto    = "data/pb/game/skill.pb",
		message  = "tg.pb.Skill.All",
		filename = "data/bin/skill.bin"
	},
	bullets = {
	    proto    = "data/pb/game/bullet.pb",
	    message  = "tg.pb.Bullet.All",
	    filename = "data/bin/bullet.bin"
	},
	gates = {
	    proto    = "data/pb/game/gate.pb",
	    message  = "tg.pb.Gate.All",
	    filename = "data/bin/gate.bin"
	},
	stages = {
	    proto    = "data/pb/game/stage.pb",
	    message  = "tg.pb.Stage.All",
	    filename = "data/bin/stage.bin"
	},
	chapters = {
	    proto    = "data/pb/game/chapter.pb",
	    message  = "tg.pb.Chapter.All",
	    filename = "data/bin/chapter.bin"
	},
	breachs = {
	    proto    = "data/pb/game/breach.pb",
	    message  = "tg.pb.Breach.All",
	    filename = "data/bin/breach.bin"
	},
	buffs = {
	    proto    = "data/pb/game/buff.pb",
	    message  = "tg.pb.Buff.All",
	    filename = "data/bin/buff.bin"
	},
	gunpoints = {
	    proto    = "data/pb/game/gunpoint.pb",
	    message  = "tg.pb.GunPoint.All",
	    filename = "data/bin/gunpoint.bin"
	},
	mapevents = {
	    proto = "data/pb/game/mapevent.pb",
	    message = "tg.pb.MapEvent.All",
	    filename = "data/bin/mapevent.bin"
	},
	monsterais = {
	    proto = "data/pb/game/monsterai.pb",
	    message = "tg.pb.MonsterAi.All",
	    filename = "data/bin/monsterai.bin"
	},
	exSkills = {
	    proto = "data/pb/game/exSkill.pb",
	    message = "tg.pb.ExSkill.All",
	    filename = "data/bin/exSkill.bin"
	},
	rewards = {
	    proto = "data/pb/game/reward.pb",
	    message = "tg.pb.Reward.All",
	    filename = "data/bin/reward.bin"
	},
	expSouls = {
	    proto = "data/pb/game/expsoul.pb",
	    message = "tg.pb.ExpSoul.All",
	    filename = "data/bin/exp_soul.bin"
	},
	sps = {
	    proto = "data/pb/game/sp.pb",
	    message = "tg.pb.Sp.All",
	    filename = "data/bin/sp.bin"
	},
	assemblages = {
	    proto = "data/pb/game/assemblage.pb",
	    message = "tg.pb.Assemblage.All",
	    filename = "data/bin/assemblage.bin"
	},
	intensifys = {
	    proto = "data/pb/game/intensifySoul.pb",
	    message = "tg.pb.IntensifySoul.All",
	    filename = "data/bin/intensify_soul.bin"
	},
	materials = {
	    proto = "data/pb/game/material.pb",
	    message = "tg.pb.Material.All",
	    filename = "data/bin/material.bin"
	},
	props = {
	    proto = "data/pb/game/prop.pb",
	    message = "tg.pb.Prop.All",
	    filename = "data/bin/prop.bin"

    },
   equipments = {
	    proto = "data/pb/game/equipment.pb",
	    message = "tg.pb.Equipment.All",
	    filename = "data/bin/equipment.bin"

	},
	decorations = {
		proto = "data/pb/game/decoration.pb",
		message = "tg.pb.Decoration.All",
		filename = "data/bin/decoration.bin"
	},
	eqIntensifys = {
	    proto = "data/pb/game/intensifyHero.pb",
	    message = "tg.pb.IntensifyHero.All",
	    filename = "data/bin/intensify_equipment.bin"
	},
	secrets = {
	    proto = "data/pb/game/secret.pb",
	    message = "tg.pb.Secret.All",
	    filename = "data/bin/developSecret.bin"
	},
	devExps = {
		proto = "data/pb/game/devExp.pb",
		message = "tg.pb.DevExp.All",
		filename = "data/bin/developExp.bin"
	},
	projects = {
		proto = "data/pb/game/project.pb",
		message = "tg.pb.Project.All",
		filename = "data/bin/developProject.bin"
	},
	fashions = {
		proto = "data/pb/game/fashion.pb",
		message = "tg.pb.Fashion.All",
		filename = "data/bin/fashion.bin"
	},
	devProps = {
		proto = "data/pb/game/devProp.pb",
		message = "tg.pb.DevProp.All",
		filename = "data/bin/developProp.bin"
	},
	actionTouchs = {
		proto = "data/pb/game/actionTouch.pb",
		message = "tg.pb.ActionTouch.All",
		filename = "data/bin/action_touch.bin"
	},
	actions = {
		proto = "data/pb/game/action.pb",
		message = "tg.pb.Action.All",
		filename = "data/bin/action.bin"
	}
}

--
-- catalog:[knights,equipments]
--
function InfoManager:findInfo(catalog, key, value)
	if nil == self.files[catalog] then
		self:loadInfo(catalog)
	end

	-- 如果不传class id则返回所有的信息
	if not key or not value then
		return self.files[catalog]
	end

	local db = self.files[catalog]

	for _,v in pairs(db) do
		if v[key] == value then
			return v
		end
	end
	girl.MsgBox(string.format("找不到资源->table:%s->key:%s->value:%s",tostring(catalog),tostring(key),tostring(value)) , 2)
 --  	printError("Can't find info for key:%s,value:%s,catalog:%s",key,value,catalog)

	return { }
end

--
-- ... must be {key,value}
--
function InfoManager:findInfoEx(catalog, ...)
	local params = {...}
	-- print(catalog)
	if nil == self.files[catalog] then
		self:loadInfo(catalog)
	end

	local db = self.files[catalog]

	for _,v in pairs(db) do
		local flag = true

		for _,vv in pairs(params) do
			if v[vv.key] ~= vv.value then
				flag = false
			end
		end

		if flag then
			-- dump(v, "findEx")
			return v
		end
	end
	-- girl.MsgBox(string.format("找不到资源->table:%s->key:%s->value:%s",tostring(catalog),tostring(key),tostring(value)) , 2)
	return nil
end

--
-- 处理同classId多数据的操作
--
function InfoManager:findInfos(catalog, key, value)
	if nil == self.files[catalog] then
		self:loadInfo(catalog)
	end

	-- 如果不传class id则返回所有的信息
	if not key or not value then
		return self.files[catalog]
	end

	local db = self.files[catalog]

	local vs = {}

	for _,v in pairs(db) do
		-- dump(v[key])
		if v[key] == value then
			table.insert(vs,v)
		end
	end

	if table.nums(vs) == 0 then
		girl.MsgBox(string.format("找不到资源->table:%s->key:%s->value:%s",tostring(catalog),tostring(key),tostring(value)) , 2)
		-- printError("Can't find info for key:%s,value:%s,catalog:%s",key,value,catalog)
	end

	return vs
end

--
-- 加载文件
--
function InfoManager:loadInfo(catalog)
	assert(nil == self.files[catalog])

	local pbBuilder = import("...extra.ProtobufBuilder",CURRENT_MODULE_NAME):getInstance()
	print(catalog)
	local FILE = FILES[catalog]
	local pb = pbBuilder:loadFromFile(FILE.proto,FILE.message,FILE.filename)

	if pb then
		self.files[catalog] = pb[catalog]
		print("Info["..catalog.."] loaded")
	end
end



return InfoManager

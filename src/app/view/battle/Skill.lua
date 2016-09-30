local CURRENT_MODULE_NAME = ...

-- classes

-- singleton
local infoMgr = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()

local  Skill = class("Skill")

Skill.Types =
{
	-- 物理输出
	ADC,
	-- 魔法输出
	APC,
}

function Skill.create(params)
	return Skill.new(params)
end

-- [LUA-print] icon	1
-- [LUA-print] level	1
-- [LUA-print] atkTimes	0
-- [LUA-print] coldTime	4
-- [LUA-print] type	2
-- [LUA-print] checkMod	1
-- [LUA-print] crossTimes	0
-- [LUA-print] atk1	10000
-- [LUA-print] atkDurTime	0
-- [LUA-print] bulletSpeed	1000
-- [LUA-print] effId	0
-- [LUA-print] musicId	3224111
-- [LUA-print] bulletId	2400
-- [LUA-print] shotWidth	-1
-- [LUA-print] buffId	0
-- [LUA-print] name	爱薇普攻1
-- [LUA-print] screenEffId	0
-- [LUA-print] findInfo:	2400
-- [LUA-print] atk2	0
-- [LUA-print] shotHight	0
-- [LUA-print] onceBulletNum	1
-- [LUA-print] class_id	2400
-- [LUA-print] sanBu	0
-- [LUA-print] skillInstruction	技能描述爱薇普攻1
function Skill:ctor(params)

	self.class_id  = params.class_id
	self.source = params.source

	local pb = infoMgr:findInfo("skills","class_id",self.class_id)
	self.info = pb

end

function Skill:getAtkTimes()
	return pb.atkTimes
end

function Skill:onEnter()

end

return Skill

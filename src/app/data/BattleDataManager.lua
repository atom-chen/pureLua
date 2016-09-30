local CURRENT_MODULE_NAME = ...

-- classes


-- singleton
local infoManager   = import(".information.InfoManager", CURRENT_MODULE_NAME):getInstance()


local s_inst = nil
local BattleDataManager = class("BattleDataManager")


function BattleDataManager:getInstance()
	if nil == s_inst then
		s_inst = BattleDataManager.new()
	end
	return s_inst
end

local function copyRepeatedWithClass(repeated,cls,key)
	local result = { }
	for _,item in ipairs(repeated) do
		local data = cls.new(item)
		result[item[key]] = data
	end
	return result
end

-- temp code
function BattleDataManager:ctor()
    local playerNetPb =
    {

    }
    self:setData(playerNetPb)
end

function BattleDataManager:setData(data)

	-- self.monsters =

  if DEBUG > 0 then
    -- printInfo("Number of knights:"..#storage.knights)
  end
end





return BattleDataManager

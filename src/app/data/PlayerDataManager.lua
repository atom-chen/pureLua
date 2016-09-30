local CURRENT_MODULE_NAME = ...

-- classes
local HeroData      = import(".information.HeroData", CURRENT_MODULE_NAME)
local SoulData      = import(".information.SoulData", CURRENT_MODULE_NAME)
local DecorationData      = import(".information.DecorationData", CURRENT_MODULE_NAME)

-- singleton
local infoManager   = import(".information.InfoManager", CURRENT_MODULE_NAME):getInstance()

local s_inst = nil
local PlayerDataManager = class("PlayerDataManager")

function PlayerDataManager:getInstance()
	if nil == s_inst then
		s_inst = PlayerDataManager.new()
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

local function copyRepeatedWithPb(repeated,key)
    local result = { }
    for _,item in ipairs(repeated) do
        -- local data = cls.new(item)
        result[item[key]] = item
    end
    return result
end

function PlayerDataManager:setData(data)
    -- dump(data.materials)
    if data.status then
		self.status = data.status
    else
        self.status = {}
	end
    -- dump(data.heros)
	if #data.heros > 0 then
		self.heros = copyRepeatedWithClass(data.heros,HeroData,"class_id")
		--dump(self.heros)
    else
        self.heros = {}
	end

	if #data.souls > 0 then
		self.souls = copyRepeatedWithClass(data.souls,SoulData,"class_id")
    else
        self.souls = {}
	end

	if #data.soulFragments > 0 then
		self.soulFragments = copyRepeatedWithClass(data.soulFragments,SoulData,"class_id")
	else
		self.soulFragments = {}
	end

	if #data.assemblages > 0 then
		self.assemblages = copyRepeatedWithPb(data.assemblages,"id")
	else
		self.assemblages = {}
	end

	if #data.equipments > 0 then
		self.equipments = copyRepeatedWithPb(data.equipments,"class_id")
	else
		self.equipments = {}
	end

	if #data.props > 0 then
        self.props = copyRepeatedWithPb(data.props,"class_id")
    else
        self.props = {}
    end

    if #data.materials > 0 then
        self.materials = copyRepeatedWithPb(data.materials,"class_id")
    else
        self.materials = {}
    end

	if #data.gates > 0 then
		self.gates = copyRepeatedWithPb(data.gates,"class_id")
	else
		self.gates = {}
	end

	if #data.stages > 0 then
		self.stages = copyRepeatedWithPb(data.stages,"class_id")
	else
		self.stages = {}
	end

	if #data.stageRewards > 0 then
		self.stageRewards = copyRepeatedWithPb(data.stageRewards,"class_id")
	else
		self.stageRewards = {}
	end

	if #data.teams > 0 then
		self.teams = data.teams
    else
        self.teams = {}
	end

	if #data.mails > 0 then
		self.mails = copyRepeatedWithPb(data.mails, "id")
	else
		self.mails = {}

		-- 测试数据
		-- local temp = {"NORMAL","IMPORTANT"}
		-- for i=1,math.random(0, 200) do
		-- 	local mail = {id = 1, items = {},date = math.random(361784637, 36178463712), level = temp[math.random(1, 2)], content = "content"..i, title = "title"..i}
		-- 	for j=1,math.random(1, 3) do
		-- 		table.insert(mail.items,{id = 1})
		-- 	end
		-- 	table.insert(self.mails, mail)
		-- end
	end

	if #data.signs > 0 then
		self.signs = copyRepeatedWithPb(data.signs, "class_id")
	else
		self.signs = {}
	end

	if #data.decorations > 0 then
		self.decorations = copyRepeatedWithClass(data.decorations,DecorationData,"class_id")
	else
		self.decorations = {}

		-- 测试数据
		-- local tempData = {}
		-- for i=1,10 do
		-- 	table.insert(tempData,{class_id = tonumber(i.."01"),state = "NORMAL"})
		-- 	table.insert(tempData,{class_id = tonumber(i.."02"),state = "SELECTED"})
		-- end
		-- self.decorations = copyRepeatedWithClass(tempData,DecorationData,"class_id")
	end
	-- dump(self.decorations)

	if #data.showers > 0 then
		self.showers = copyRepeatedWithPb(data.showers, "id")
	else
		self.showers = {}

		-- 测试数据
		-- for i=1,4 do
		-- 	self.showers[i] = {}
		-- 	self.showers[i].id = i
		-- 	self.showers[i].tempEnergy = 200
		-- 	self.showers[i].overTime = 20000
		-- 	self.showers[i].posStatue = {}
		-- 	self.showers[i].posStatue.pos = i
		-- end
		--
		-- self.showers[1].soul_id = 8
		-- self.showers[2].soul_id = 8
		-- self.showers[3].soul_id = 8
		-- self.showers[4].soul_id = 8
		--
		-- self.showers[1].posStatue.status = "OPEN"
		-- self.showers[2].posStatue.status = "OPEN"
		-- self.showers[3].posStatue.status = "CLOSE"
		-- self.showers[4].posStatue.status = "CLOSE"
	end

	if #data.devProps > 0 then
		self.devProps = copyRepeatedWithPb(data.devProps, "class_id")
	else
		self.devProps = {}
	end
	-- dump(self.devProps)
	if #data.devPropShop > 0 then
		self.devPropShop = copyRepeatedWithPb(data.devPropShop, "class_id")
	else
		self.devPropShop = {}
	end

	if #data.actionTouch > 0 then
		self.actionTouch = data.actionTouch
	else
		self.actionTouch = {}
	end

	self.firstBlood = data.firstBlood

	self.config = data.config
	print("_____________")
	print(self.config.barrageOn)
	print(self.config.showSoul)

	-- 自定义数据
	-- 是否签到过
	self.signed = (not self.firstBlood)
end

function PlayerDataManager:updateStatusByDiff(status)
    self.status = status
end

function PlayerDataManager:updateSoulByDiff(diff)
	local iid = diff.id
	print("updateSoulByDiff")
	if self.souls[iid] then
		if "REPLACE" == diff.Method then
			print("updateSoulByDiff #diff.params-", #diff.params)
			if #diff.params > 0 then
				print("updateSoulByDiff > 0")
				self:updateParamsByDiff(diff.params, self.souls[iid])
				-- dump(self.souls[iid])
			else
				print("updateSoulByDiff else")
				self.souls[iid] = SoulData.new(diff.soul)
			end
		else
			self.souls[iid] = nil
		end
	else
		if "ADD" == diff.Method then
			self.souls[iid] = SoulData.new(diff.soul)
		else
			printError("Can't find soul for id:"..iid)
		end
	end
	--dump(self.souls[iid])
end

function PlayerDataManager:updateSoulFragmentByDiff(diff)
	local iid = diff.id
	--dump(self.soulFragments)

	if self.soulFragments[iid] then
		if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.soulFragments[iid])
			else
				self.soulFragments[iid] = SoulData.new(diff.soul)
			end
		else
			self.soulFragments[iid] = nil
		end
	else
		if "ADD" == diff.Method then
			self.soulFragments[iid] = SoulData.new(diff.soul)
		else
			printError("Can't find soul fragment for id:"..iid)
		end
	end
end

function PlayerDataManager:updateHeroByDiff(diff)
	local iid = diff.id

	if self.heros[iid] then
		print(diff.Method)
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.heros[iid])
				print("updateParamsByDiff")
			else
				self.heros[iid] = HeroData.new(diff.hero)
				print("HeroData.new(diff.hero)")
			end
	    else
	    	print("self.heros[iid] = nil")
	        self.heros[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.heros[iid] = HeroData.new(diff.hero)
	    else
		    printError("Can't find hero for id:"..iid)
		end
	end
end

function PlayerDataManager:updateHeroIntensifyByDiff(diff)
	local iid = diff.id
	local hid = diff.hid

	dump(diff.intensifyHero)

	if self.heros[hid] then
	    if "REPLACE" == diff.Method then
	    	print("enter REPLACE")
		    self.heros[hid].intensify[iid] = diff.intensifyHero
        else
	        printError("error")
	    end
	else
	    printError("Not REPLACE")
	end
end

function PlayerDataManager:updatePropByDiff(diff)
	local iid = diff.id
	print("prop diff Method", diff.Method)

	if self.props[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.props[iid])
			else
				self.props[iid] = diff.prop
			end
	    else
	        self.props[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.props[iid] = diff.prop
	    else
			printError("Can't find prop for id:"..iid)
		end
	end
end

function PlayerDataManager:updateMaterialByDiff(diff)
	local iid = diff.id
	print("Material diff Method", diff.Method)

	if self.materials[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.materials[iid])
			else
				self.materials[iid] = diff.material
			end
	    else
	        self.materials[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.materials[iid] = diff.material
	    else
			printError("Can't find material for id:"..iid)
		end
	end
end

function PlayerDataManager:updateGateByDiff(diff)
	local iid = diff.id

	if self.gates[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.gates[iid])
			else
				self.gates[iid] = diff.gate
			end
	    else
            self.gates[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.gates[iid] = diff.gate
	    else
		    printError("Can't find gate for id:"..iid)
		end
	end

end

function PlayerDataManager:updateStageByDiff(diff)
	local iid = diff.id
    --print("diff.Method",diff.Method)
	if self.stages[iid] then
		--print("self.stages[iid] 存在")
	    if "REPLACE" == diff.Method then
	    	--print("enter REPLACE")
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.stages[iid])
			else
				self.stages[iid] = diff.stage
			end
	    else
            self.stages[iid] = nil
	    end
	else
		--print("self.stages[iid] 不存在")
		if "ADD" == diff.Method then
			--print("enter ADD")
	        self.stages[iid] = diff.stage
	        dump(diff.stage)
	        dump(self.stages[iid])
	    else
	    	--print("error")
		    printError("Can't find stage for id:"..iid)
		end
	end
end

function PlayerDataManager:updateStageRewardByDiff(diff)
	local iid = diff.id

	if self.stageRewards[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.stageRewards[iid])
			else
				self.stageRewards[iid] = diff.stageReward
			end
	    else
	        self.stageRewards[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.stageRewards[iid] = diff.stageReward
	    else
		    printError("Can't find stage for id:"..iid)
		end
	end
end

function PlayerDataManager:updateMailByDiff(diff)
	local iid = diff.id

	if self.mails[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.mails[iid])
			else
				self.mails[iid] = diff.mail
			end
	    else
	        self.mails[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.mails[iid] = diff.mail
	    else
		    printError("Can't find mail for id:"..iid)
		end
	end
end

function PlayerDataManager:updateAssemblageByDiff(diff)
	local iid = diff.id

	print("diff.Method",diff.Method)
    print("diff.id",    diff.id)
	if self.assemblages[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.assemblages[iid])
			else
				self.assemblages[iid] = diff.assemblage
			end
	    else
	        self.assemblages[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.assemblages[iid] = diff.assemblage
	    else
		    printError("Can't find assemblage for id:"..iid)
		end
	end
end

function PlayerDataManager:updateSignByDiff(diff)
	local iid = diff.id
	dump(self.signs)

	if self.signs[iid] then
		if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.signs[iid])
			else
				self.signs[iid] = diff.signItem
			end
		else
			self.signs[iid] = nil
		end
	else
		if "ADD" == diff.Method then
			self.signs[iid] = diff.signItem
		else
			printError("Can't find sign for id:"..iid)
		end
	end
	--dump(self.signs)
end

function PlayerDataManager:updateSoulAssemblageByDiff(diff)
	local iid = diff.id
	local sid = diff.soulId
	-- dump(self)
	-- dump(self.souls)

	if self.souls[sid].assemblages[iid] then
		if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.souls[sid].assemblages[iid])
			else
				self.souls[sid].assemblages[iid] = diff.assemblage
			end
		else
			self.souls[sid].assemblages[iid] = nil
		end
	else
		if "ADD" == diff.Method then
			self.souls[sid].assemblages[iid] = diff.assemblage
		else
			printError("Can't find soul assemblage for id:"..iid .. "soul id:"..sid)
		end
	end
end

function PlayerDataManager:updateSoulIntensifyByDiff(diff)
	local iid = diff.id
	--local sid = diff.intensifySoul.soul_id

    if self.souls[iid].intensifys then
		if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.souls[iid].intensifys)
			else
				self.souls[iid].intensifys = diff.intensifySoul
				print("self.souls[iid].intensifys = diff.intensifySoul")
			end
		else
			printError("not REPLACE")
		end
	else
		printError("not self.souls[iid].intensifys exist")
	end
end

function PlayerDataManager:updateDecorationByDiff(diff)
	local iid = diff.id

	if self.decorations[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.decorations[iid])
			else
				self.decorations[iid] = DecorationData.new(diff.decoration)
			end
	    else
	        self.decorations[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.decorations[iid] = DecorationData.new(diff.decoration)
	    else
		    printError("Can't find decoration for id:"..iid)
		end
	end
end

function PlayerDataManager:updateShowerByDiff(diff)
	local iid = diff.id

	if self.showers[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.showers[iid])
			else
				self.showers[iid] = diff.shower
			end
	    else
	        self.showers[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.showers[iid] = diff.shower
	    else
		    printError("Can't find shower for id:"..iid)
		end
	end
end

function PlayerDataManager:updateDevPropByDiff(diff)
	local iid = diff.id

	if self.devProps[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.devProps[iid])
			else
				self.devProps[iid] = diff.devProp
			end
	    else
	        self.devProps[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.devProps[iid] = diff.devProp
	    else
		    printError("Can't find devProp for id:"..iid)
		end
	end
end

function PlayerDataManager:updateDevPropShopByDiff(diff)
	local iid = diff.id

	if self.devPropShop[iid] then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.devPropShop[iid])
			else
				self.devPropShop[iid] = diff.devProp
			end
	    else
	        self.devPropShop[iid] = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.devPropShop[iid] = diff.devProp
	    else
		    printError("Can't find devPropShop for id:"..iid)
		end
	end
end

function PlayerDataManager:updateActionTouch(diff)
	if self.actionTouch then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.actionTouch)
			else
				self.actionTouch = diff.actionTouch
			end
	    else
	        printError("Can't find actionTouch Method")
	    end
	else
		printError("Can't find actionTouch")
	end
end

function PlayerDataManager:updateSoulProjectDiff(diff)
	local soulId = diff.soulId
	local soul = self.souls[soulId]
	if soul then
		local iid = diff.id
		if soul.projects[iid] then
		    if "REPLACE" == diff.Method then
				if #diff.params > 0 then
					self:updateParamsByDiff(diff.params, soul.projects[iid])
				else
					soul.projects[iid] = diff.project
				end
		    else
		        soul.projects[iid] = nil
		    end
		else
			if "ADD" == diff.Method then
		        soul.projects[iid] = diff.project
		    else
			    printError("Can't find soulId:".. soulId .."project for id:"..iid)
			end
		end
	else
		printError("Can't find project soul for id:"..soulId)
	end
end

function PlayerDataManager:updateConfigDiff(diff)
	if self.config then
	    if "REPLACE" == diff.Method then
			if #diff.params > 0 then
				self:updateParamsByDiff(diff.params, self.config)
			else
				self.config = diff.config
			end
	    else
	        diff.config = nil
	    end
	else
		if "ADD" == diff.Method then
	        self.config = diff.config
	    else
		    printError("Can't find config")
		end
	end
end

function PlayerDataManager:updateShopFashionDiff(diff)
	local soulId = diff.soulId
	local soul = self.souls[soulId]
	if soul then
		local iid = diff.id
		if soul.shopFashions[iid] then
		    if "REPLACE" == diff.Method then
				if #diff.params > 0 then
					self:updateParamsByDiff(diff.params, soul.shopFashions[iid])
				else
					soul.shopFashions[iid] = diff.fashion
				end
		    else
		        soul.shopFashions[iid] = nil
		    end
		else
			if "ADD" == diff.Method then
		        soul.shopFashions[iid] = diff.fashion
		    else
			    printError("Can't find soulId:".. soulId .."shop fashion for id:"..iid)
			end
		end
	else
		printError("Can't find shop fashion soul for id:"..soulId)
	end
end

function PlayerDataManager:updateSoulFashionDiff(diff)
	local soulId = diff.soulId
	local soul = self.souls[soulId]
	if soul then
		local iid = diff.id
		if soul.fashions[iid] then
		    if "REPLACE" == diff.Method then
				if #diff.params > 0 then
					self:updateParamsByDiff(diff.params, soul.fashions[iid])
				else
					soul.fashions[iid] = diff.fashion
				end
		    else
		        soul.fashions[iid] = nil
		    end
		else
			if "ADD" == diff.Method then
		        soul.fashions[iid] = diff.fashion
		    else
			    printError("Can't find soulId:".. soulId .."fashion for id:"..iid)
			end
		end
	else
		printError("Can't find fashion soul for id:"..soulId)
	end
end

function PlayerDataManager:updateSoulSecretDiff(diff)
	local soulId = diff.soulId
	local soul = self.souls[soulId]
	if soul then
		local iid = diff.id
		if soul.secrets[iid] then
		    if "REPLACE" == diff.Method then
				if #diff.params > 0 then
					self:updateParamsByDiff(diff.params, soul.secrets[iid])
				else
					soul.secrets[iid] = diff.secret
				end
		    else
		        soul.secrets[iid] = nil
		    end
		else
			if "ADD" == diff.Method then
		        soul.secrets[iid] = diff.secret
		    else
			    printError("Can't find soulId:".. soulId .."secret for id:"..iid)
			end
		end
	else
		printError("Can't find secret soul for id:"..soulId)
	end
end

function PlayerDataManager:updateParamsByDiff(params, data)
	for _,v in ipairs(params) do
		-- print("REPLACE params:",v.key..":"..v.value)

		if type(data[v.key]) == "string" then
			data[v.key] = v.value
		elseif type(data[v.key]) == "number" then
			data[v.key] = tonumber( v.value)
		elseif type(data[v.key]) == "boolean" then
			printError("updateParamsByDiff unknow tyep")
		else
			printError("updateParamsByDiff unknow tyep")
		end
	end
	--dump(data)
end

function PlayerDataManager:setGoTeam(team)
    local  goTeam = clone(team)
     for k,v in pairs(goTeam) do
        if v.type =="HERO" then
            table.remove(goTeam,k)
        end
     end
	 self.goTeams = goTeam
end

function PlayerDataManager:setServer(data)
	self.servers = data.servers
	table.sort(self.servers, function ( a,b )
		return a.class_id < b.class_id
	end)
	self.commend = data.commend
end

return PlayerDataManager

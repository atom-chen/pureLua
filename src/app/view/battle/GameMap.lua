local CURRENT_MODULE_NAME = ...

local infoMgr = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local Monster = import(".Monster", CURRENT_MODULE_NAME)
local Trap 	  = import(".Trap", CURRENT_MODULE_NAME)
local MapEvent = import(".MapEvent", CURRENT_MODULE_NAME)
local AnimationNode = import("..controls.CocostudioNode")
local PanelBase = import("..controls.PanelBase")

local musicManager = import("..controls.MusicManager",CURRENT_MODULE_NAME):getInstance()
local battleManager = import(".BattleManager",CURRENT_MODULE_NAME):getInstance()

local GameMap = class("GameMap",PanelBase)

GameMap.offset_y 	= -32	--除远景层以外地图层偏移值
GameMap.screen_rate = 0.4	--英雄角色在屏幕中占比

local MOD_VALUE 	= 100000

function GameMap.create(params)
	-- dump(params)
	local gate = infoMgr:findInfo("gates","class_id",params.gateId)
	-- dump(gate)
	GameMap.maps_id = string.split(gate.maps_id,"#")
	-- dump(GameMap.maps_id)
	local mapid = tonumber(GameMap.maps_id[1])
	local dirId = math.floor(mapid/MOD_VALUE)
	--默认远景
	local csbName = string.format("maps/%d/%d.csb",dirId,dirId*10+3)
	return GameMap.new({gateId = params.gateId, gate = gate, csbName = csbName})
end



function GameMap:ctor(params)
	GameMap.super.ctor(self,params)
	self:enableNodeEvents()

	--生成关卡信息
	self.gateInfo = params.gate
	-- self.maps_id = params.gate.maps_id

	self.mapWidth  = 0 	    --地图长度
	self.mapNumber = 0 		--地图块数
	self.mapPieceWidth = 0  --最新生成的地块长度

	self.mapIdx = 1 		--本关卡生成的第几张地图
	self.frontWidth = 0   	--前景记录的长度

	self.mapMidds 	= {}		--存入所有中景地块对像（动态变化的）
	self.mapMidd2s 	= {}		--存入所有中景2地块对像（动态变化的）
	self.mapNears 	= {}		--存入所有近景地块对像（动态变化的）
	self.mapFronts 	= {}		--存入所有前景地块对像（动态变化的）
	self.recordMapsId = {}		--记录地块id，可能会用到

	self.middLayer = cc.Node:create()
	self.middLayer:setAnchorPoint(cc.p(0,0))

	self.midd2Layer = cc.Node:create()
	self.midd2Layer:setAnchorPoint(cc.p(0,0))

	self.nearLayer = cc.Node:create()
	self.nearLayer:setAnchorPoint(cc.p(0,0))

	self.frontLayer = cc.Node:create()
	self.frontLayer:setAnchorPoint(cc.p(0,0))

	--生成中景和近景()
	self:addMapWithId(tonumber(self.maps_id[self.mapIdx]))
	self.mapIdx = self.mapIdx + 1
	--self:addAllMapCell()

end


function GameMap:addMapWithId(id)

	local mapData =  infoMgr:findInfos("mapinfos", "class_id", id)

	--当前地块内所有的怪或事件或其他对像信息
	--dump(mapData.info)

	--当前场景中近景层id  : 取地块信息的第一行数据可mapData.info[1]
	local near_id = mapData[1].near_id
	local midd_id = mapData[1].midd_id
	local midd2_id= mapData[1].midd2_id
	local front_id= mapData[1].front_id

	table.insert(self.recordMapsId,id)

	local midCsbName 	= string.format("maps/%d/%d.csb",id/MOD_VALUE,midd_id)
	local mid2CsbName 	= string.format("maps/%d/%d.csb",id/MOD_VALUE,midd2_id)
	local nearCsbName 	= string.format("maps/%d/%d.csb",id/MOD_VALUE,near_id)
	local frontCsbName 	= string.format("maps/%d/%d.csb",id/MOD_VALUE,front_id)


	local middLayer = AnimationNode.new({csbName = midCsbName})  --:addTo(self)
	local midd2Layer= AnimationNode.new({csbName = mid2CsbName})  --:addTo(self)
	local nearLayer = AnimationNode.new({csbName = nearCsbName}) --:addTo(self)
	local frontLayer= AnimationNode.new({csbName = frontCsbName}) --:addTo(self)

	self.mapPieceWidth = nearLayer:getBoundingBox().width
	printInfo("mapPieceWidth:"..self.mapPieceWidth)
	self.mapNumber= self.mapNumber+1


	middLayer:setPosition(self.mapWidth,GameMap.offset_y)
	midd2Layer:setPosition(self.mapWidth,GameMap.offset_y)
	nearLayer:setPosition(self.mapWidth,GameMap.offset_y)
	frontLayer:setPosition(self.mapWidth,GameMap.offset_y)

	--加载怪物或对象结点〜
	for i,v in ipairs(mapData) do
		--[{obj_type} 1:怪物 2:地图事件]
	    if v.obj_type == 1 then
	      	-- monster
	      	if(v.obj_id>0) then

		      	local monster = Monster.createWithId(v.obj_id)
		      	monster:retain()
		        :setPosition(cc.p(v.obj_x+self.mapWidth,v.obj_y))
		        monster.aiId = v.ai_id
		        monster.dropId = v.drap_id
		        if monster.objType == Monster.OBJ_TYPE.MONSTER or monster.objType == Monster.OBJ_TYPE.BOSS then --怪(&BOSS)，可以被破坏
		        	table.insert(battleManager.monsterPool,monster)
		        	if self.gateInfo.success_type == 1 and monster.pb.id == self.gateInfo.success_condition then --1: boss
		        		battleManager.target = monster
		        	end

		        elseif monster.objType == Monster.OBJ_TYPE.BARRIER then --栅栏类，可以被破坏

		        	local trap = Trap.createWithId(v.obj_id)
			        :setPosition(cc.p(v.obj_x+self.mapWidth,v.obj_y))
			        trap.otherHalfObj = monster
			        self.nearLayer:addChild(trap,1000)
			        table.insert(battleManager.trapPool,trap)
			        table.insert(battleManager.monsterPool,monster)

			    elseif monster.objType == Monster.OBJ_TYPE.ELECTRICITY_NET then --电网类，不可以破坏

			    	local trap = Trap.createWithId(v.obj_id)
			        :setPosition(cc.p(v.obj_x+self.mapWidth,v.obj_y))
			        trap.otherHalfObj = monster
			        self.nearLayer:addChild(trap,1000)
			        table.insert(battleManager.trapPool,trap)

		        end
		        table.insert(battleManager.recMonster,monster)
		     	self.nearLayer:addChild(monster, 1)
		    end

	    elseif v.obj_type == 2 then
	      	-- event
	      	if(v.obj_id > 0) then
		      	local mapEvent = MapEvent.createWithId(v.obj_id, cc.p(v.event_x + self.mapWidth + v.obj_x, v.event_y))
		        :setPosition(cc.p(v.obj_x + self.mapWidth, v.obj_y))
		      	self.nearLayer:addChild(mapEvent,200)
		    end

	    end
	end

	self.mapWidth   = self.mapWidth+self.mapPieceWidth
	self.frontWidth = self.mapWidth
	battleManager.mapW = self.mapWidth

	self.middLayer:addChild(middLayer)
	self.midd2Layer:addChild(midd2Layer)
	self.nearLayer:addChild(nearLayer)
	self.frontLayer:addChild(frontLayer)
	table.insert(self.mapMidds,middLayer)
	table.insert(self.mapMidd2s,midd2Layer)
	table.insert(self.mapNears,nearLayer)
	table.insert(self.mapFronts,frontLayer)
	printInfo(string.format("mapNumber:%d,mapw:%d",self.mapNumber,self.mapWidth))

end

------前景层比玩家路面层速度快1.2倍，所以会先跑到尽头，导致地图后期刷出前景已刷完，画面感不真实-----
------方案：最后一地块前景层循环补刷出，直到路面层真实结束------------------------------------
function GameMap:addFrontMap(id)

	local mapData  =  infoMgr:findInfos("mapinfos", "class_id", id)
	local front_id = mapData[1].front_id
	local frontCsbName 	= string.format("maps/%d/%d.csb",id/MOD_VALUE,front_id)
	local frontLayer= AnimationNode.new({csbName = frontCsbName})
	self.mapPieceWidth = frontLayer:getBoundingBox().width
	frontLayer:setPosition(self.frontWidth,GameMap.offset_y)
	self.frontWidth = self.frontWidth+self.mapPieceWidth
	self.frontLayer:addChild(frontLayer)
	table.insert(self.mapFronts,frontLayer)

end

function GameMap:onEnter()
	GameMap.super.onEnter(self)
	-- musicManager:play(self.gateInfo.music_id)
	self:onUpdate(handler(self,GameMap.checkAddNextMap))
end

function GameMap:onExit()
    GameMap.super.onExit(self)
	--printInfo("[------GameMap:onExit-----]")
	musicManager:play(5000016)


end


function GameMap:move(dt)

	local offset = -display.width*0.5  --aoyi锚点(0.5,0.5) 地块相对偏移(-display.width*0.5,-display.height*0.5) 
	local deltaDis  =  battleManager.cameraPos.x - (display.width*GameMap.screen_rate - battleManager.cameraTarget:getPositionX()) 
	if deltaDis >0 then
		battleManager.cameraPos.x = display.width*GameMap.screen_rate - battleManager.cameraTarget:getPositionX()
	else
	 	--printInfo("被击退 dis:"..deltaDis)
	end
	if battleManager.cameraPos.x + self.mapWidth <= display.width then
		battleManager.cameraPos.x = display.width - self.mapWidth
	elseif battleManager.cameraPos.x >= 0 then
		battleManager.cameraPos.x = 0
	end
	self.midd2Layer:setPositionX(math.floor(offset + (battleManager.cameraPos.x)*0.2))
	self.middLayer:setPositionX(math.floor(offset + (battleManager.cameraPos.x)*0.5))
	self.nearLayer:setPositionX(math.floor(offset + (battleManager.cameraPos.x)))
	self.frontLayer:setPositionX(math.floor(offset + (battleManager.cameraPos.x)*1.2))
end

--一次加载所有地块
function GameMap:addAllMapCell()

	for i=1,#self.maps_id do
		self:addMapWithId(tonumber(self.maps_id[self.mapIdx]))
		self.mapIdx = self.mapIdx + 1
	end
end

function GameMap:checkAddNextMap(dt)

	if self.frontLayer:getPositionX() + self.mapWidth < display.width + 64 then
			if self.mapIdx  <= #self.maps_id then
				self:addMapWithId(tonumber(self.maps_id[self.mapIdx]))
				self.mapIdx = self.mapIdx + 1
			else
				--self:addFrontMap(tonumber(self.maps_id[self.mapIdx-1]))
				self:addMapWithId(tonumber(self.maps_id[self.mapIdx-1]))	--最后块地图一直循环♻️
			end
	end

	--local offset = display.width*0.5  --aoyi锚点(0.5,0.5) 地块相对偏移(-display.width*0.5,-display.height*0.5)

	--近景释放

	if battleManager.cameraPos.x + self.mapNears[1]:getPositionX() + self.mapNears[1]:getBoundingBox().width < -64 then

			self.mapNears[1]:removeFromParent()
			table.remove(self.mapNears,1)
			self.mapNumber = self.mapNumber-1
			printInfo(string.format("release: mapNumber:%d,mapw:%d",self.mapNumber,self.mapWidth))
	end
	
	--中景释放
	if battleManager.cameraPos.x*0.5 + self.mapMidds[1]:getPositionX() + self.mapMidds[1]:getBoundingBox().width < -64 then
			self.mapMidds[1]:removeFromParent()
			table.remove(self.mapMidds,1)
			--printInfo("release: mapMidds")
	end
	-- --中景2释放
	if battleManager.cameraPos.x*0.2 + self.mapMidd2s[1]:getPositionX() + self.mapMidd2s[1]:getBoundingBox().width < -64 then
			self.mapMidd2s[1]:removeFromParent()
			table.remove(self.mapMidd2s,1)
			--printInfo("release: mapMidd2s")
	end
	-- --前景释放
	if battleManager.cameraPos.x*1.2 + self.mapFronts[1]:getPositionX() + self.mapFronts[1]:getBoundingBox().width < -64  then
			self.mapFronts[1]:removeFromParent()
			table.remove(self.mapFronts,1)
			--printInfo("release: mapFronts")
	end
	--print("+++++++++++++++++++++++++++self.mapNumber:"..self.mapNumber)
	self:move(dt)
end


return GameMap

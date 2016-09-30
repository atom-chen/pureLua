local CURRENT_MODULE_NAME = ...

local AnimationNode       = import("..controls.CocostudioNode")
local BaseRole            = import(".BaseRole",CURRENT_MODULE_NAME)

-- classes
local Bullet = class("Bullet",display.newNode)

-- singleton
local resManager = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local infoMgr = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local battleManager         = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
--[[
一般子弹创建 .new({id = bulletId})
触发子弹创建 .new({id = bulletId,type = ,dmgValue = ,range = ,height = ,speed = ,angle=})
]]
function Bullet:ctor(params)
    self:enableNodeEvents()
    self.pb =  infoMgr:findInfo("bullets","class_id",params.id)
	self.info = self.pb
    --dump(self.info)
    self.scale          =  self.info.scale/10000.0
    self.swing          =  self.info.swing
    self.swingFrequency =  self.info.swingFrequency
    self.musicId        =  self.info.musicId
    self.width          =  self.info.width
    self.height         =  self.info.height
    self.hitEffId       =  self.info.hitEffId
    self.atkRange       =  self.info.atkRange
    self.atkMusicId     =  self.info.atkMusicId
    self.buffId         =  self.info.buffId
    self.rotate         =  self.info.rotate
    self.type           =  self.info.type
    self.acc            = -self.info.acc            --加速度
    self.camp           =  params.camp
    self.checkMod       =  params.checkMod or 1      --判定类型[0、无效 1、对对象和地面判定 2、对地面判定]
    --如果是敌方则所有角度处理镜像
    if self.camp == BaseRole.campType.CAMP_MONSTER then
        self.angle = 180 - params.angle
        if self.rotate == 0 then --如果不随方向翻转，则右方飞入的子弹要镜像处理
           self:setScale(-self.scale)
        else
           self:setScale(self.scale)
        end
    else
        self.angle    = params.angle
        self:setScale(self.scale)
    end
    self.rad      = math.rad(self.angle)
    self.dmgValue = params.dmgValue
    --dump(params)
    self:setPosition(cc.p(params.pos))
    self.recPos  = cc.p(params.pos)
    self.lastPos = cc.p(params.pos)
    if params.range == -1 then
        self.range = display.width
    else
        self.range = params.range
    end
    self.speed    = params.speed
    --加载子弹资源
    local resId = self.info.resId
    local filename = resManager:getResPath(resId)
    self.bullet = AnimationNode.load(filename)
    if self.bullet == nil then
        printInfo("err: [Bullet] bullet resId: %d"..resId)
        return
    end
    self.bullet:runAnimation(AnimationNode.DefaultAnimation,true)
    self:addChild(self.bullet)
    --发射音效
    if self.musicId >0 then
        musicManager:play(self.musicId)
    end
    self.emanate = params.emanate
    if(self.emanate) then
        self.emanate:retain()
    end
    --测试矩形框
    -- local rt = cc.rect(-self.info.width/2,
    --         -self.info.height/2,
    --         self.info.width,
    --         self.info.height)
    -- girl.createTestRect(rt):addTo(self)

    --add new design edit by Jason
    self.vy = self.speed*math.sin(self.rad) -- y向初始速度
    self.vx = self.speed*math.cos(self.rad) -- x向初始速度
    self.moveDis = 0                        -- 位移累计s
    --跟踪弹目标
    self.target  = params.target
    --穿透次数
    self.crossTimes =  0
end

function Bullet:onExit()
    if self.emanate then
        self.emanate:release()
    end
end

function Bullet:onEnter()
    table.insert(battleManager.bulletPool,self)
    --[{self.type} 0 or 2:直线&抛物线 1、跟踪弹 3、波形（曲线）]
    if self.type == 1 then
        self:onUpdate(handler(self, self.followerMovitionUpdate))
    elseif self.type == 3 then
        self:onUpdate(handler(self, self.curveMovitionUpdate))
    else
        self:onUpdate(handler(self, self.normalMovitionUpdate))
    end
    self:schedule(self,handler(self, self.checkUpdate))
end


--子弹正常飞行处理（加入重力加速度处理）
function Bullet:normalMovitionUpdate(dt)
    local deltaY = self.vy*dt + 0.5*self.acc*dt*dt
    local deltaX = self.vx*dt
    --位移变化量 s = v0*t + 0.5*a*t*t  （真实轨迹）
    local deltaDis = (math.sqrt(deltaY*deltaY+(deltaX)*(deltaX)))
    self.vy = self.vy+self.acc*dt   --Ｙ向处理
    local pos = cc.p(self:getPosition())
    self.lastPos = pos --记录上次dt位置
    local angle =  (math.atan(deltaX/deltaY))/3.1415926*180 - 90
    local y = pos.y+ deltaY
    local x = pos.x+ deltaX
    self:setPosition(x,y)
    --是否时实处理翻转
    if self.info.rotate ==  1 then
      if deltaY < 0 then
        angle = angle + 180
      end
      self:setRotation(angle)
    end
    --print(">>>>>>>>deltaDis:"..deltaDis..">>>>>>>>>>>>deltaX:"..deltaX .."   deltaY:"..deltaY.."    vy:"..self.vy   .."      angle: "..angle)
    --检查销毁(出屏或到达飞行距离)
    self.moveDis = self.moveDis + deltaDis
end
--子弹跟踪处理
function Bullet:followerMovitionUpdate(dt)
    local pos = cc.p(self:getPosition())
    local targetPos = cc.p(self.target:getPosition())
    self.lastPos = pos --记录上次dt位置
    local angle  = 0
    if targetPos.x - pos.x > 0 then
        angle = (math.atan((targetPos.y- pos.y)/(targetPos.x - pos.x)))/3.1415926*180
    else
        angle = (math.atan((targetPos.y- pos.y)/(targetPos.x - pos.x)))/3.1415926*180 - 180
    end
    local rad = math.rad(angle)
    local deltaX = math.cos(rad)*self.speed*dt
    local deltaY = math.sin(rad)*self.speed*dt
    self:setPosition(cc.pAdd(pos,cc.p(deltaX,deltaY)))
    --是否时实处理翻转
    if self.info.rotate ==  1 then
        angle = - angle
        self:setRotation(angle)
    end
    --print(">>>>>>>>deltaX:"..deltaX .."     deltaY:"..deltaY  .."     angle: "..angle)
    --检查销毁(出屏或到达飞行距离)
    self.moveDis = self.moveDis + self.speed*dt
end

--曲线运动处理
function Bullet:curveMovitionUpdate(dt)

    local pos = cc.p(self:getPosition())
    self.lastPos = pos --记录上次dt位置
    local swingFrequency = self.info.swingFrequency/1000.0 or 1.0  --振频
    self.angle  = self.angle + 360/(swingFrequency*60)    -- 6 = 360度/s---> 6度/dt
    if self.angle >= 360 then
      self.angle = 0
    end
    local angle = self.angle
    local sign = 1
    if angle < 90 then
        angle = angle-90
        sign = 1
    elseif angle >=90 and  angle < 180 then
        angle = angle-90
        sign = -1
    elseif angle >=180 and  angle < 270 then
        angle = -angle-90
        sign = -1
    else
        angle = -angle-90
        sign = 1
    end
    --local rad = math.rad(angle)
    local deltaX = self.speed*dt*(self.camp == 0 and 1 or -1)
    local deltaY = self.info.swing * 4 * dt * sign   --注：4是sin曲线一个周期4次动作（上，下，下，上）
    --printf("-------------- deltaX:"..deltaX .. "    deltaY:"..deltaY  .."  angle:"..self.angle)
    self:setPosition(cc.pAdd(pos,cc.p(deltaX,deltaY)))
    --是否时实处理翻转
    if self.info.rotate ==  1 then
        self:setRotation(angle)
    end
    self.moveDis = self.moveDis + deltaX
end
---子弹检测自消毁处理--(碰到地面或越界或到达射程)
function Bullet:checkUpdate(dt)

    self:checkAttractTarget()
    --判定类型[0、无效 1、对对象和地面判定 2、对地面判定]
    if self.checkMod == 1 or self.checkMod == 2 then
        --注：有加速度的超过限定的高度则消毁
        if  self.info.acc ~= 0 and self:getPositionY() < BaseRole.HERO_POSITION.y then
            self:setPositionY(BaseRole.HERO_POSITION.y)
            if self.buffId >0 then
                MessageManager.sendMessage(girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,{emanate = self.emanate,camp = self.camp,buffId = self.buffId,emanateType = "BULLET",pos = cc.p(self:getPosition())})
            end
            self:destroy()
            return
        end
    end
    if (battleManager.cameraPos.x + self:getPositionX() >= display.width + 32 and  math.cos(self.rad) > 0) 
        or (battleManager.cameraPos.x + self:getPositionX() < -32  and math.cos(self.rad) < 0)
        or self.moveDis > self.range  then
            self:destroy()
            --print("子弹已经销毁")
    end
end

--寻导热源目标（热源弹或角色）
function Bullet:checkAttractTarget()
    --[[[
        0、不跟踪
        1、跟踪最近的目标
        2、作为跟踪子弹的最优先目标
        3、波状运动子弹（简谐振动）
    ]]
    --敌方子弹
    if self.camp == BaseRole.campType.CAMP_MONSTER then

        if self.type == 1 then
            for i,v in ipairs(battleManager.bulletPool) do      
                if v.type == 2 and v.camp ~= BaseRole.campType.CAMP_MONSTER then
                    self.target = v
                    return
                end
            end
            self.target = battleManager.hero
        end
    else --我方子弹
        if self.type == 1 then
            for i,v in ipairs(battleManager.bulletPool) do
                if v.type == 2 and v.camp == BaseRole.campType.CAMP_MONSTER then
                    self.target = v
                    return
                end
            end
            self.target = battleManager.hero.curTarget
        end
    end

end

function Bullet:destroy()
    local i = 1
    while battleManager.bulletPool[i] do
        if battleManager.bulletPool[i] == self then
            table.remove(battleManager.bulletPool,i)
            break
        else
            i= i+1
        end
    end
    self:removeFromParent()
end

return  Bullet

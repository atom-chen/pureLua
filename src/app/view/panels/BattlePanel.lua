
local CURRENT_MODULE_NAME = ...


-- classes
local PanelBase             = import("..controls.PanelBase")
local AnimationNode         = import("..controls.CocostudioNode")

local GameMap               = import("..battle.GameMap")
local Hero 					= import("..battle.Hero", CURRENT_MODULE_NAME)
local Soul 					= import("..battle.Soul", CURRENT_MODULE_NAME)
local Monster 			    = import("..battle.Monster", CURRENT_MODULE_NAME)
local Trap                  = import("..battle.Trap", CURRENT_MODULE_NAME)
local Skill 				= import("..battle.Skill", CURRENT_MODULE_NAME)
local Bullet                = import("..battle.Bullet",CURRENT_MODULE_NAME)
local Buff                  = import("..battle.Buff", CURRENT_MODULE_NAME)
local Effect 				= import("..controls.EffectManager", CURRENT_MODULE_NAME)
local BaseRole              = import("..battle.BaseRole", CURRENT_MODULE_NAME)
local WarningNode           = import("..battle.WarningNode",CURRENT_MODULE_NAME)
local BattleScriptPanel     = import(".BattleScriptPanel",CURRENT_MODULE_NAME)
local DropNode              = import("..battle.DropNode", CURRENT_MODULE_NAME)
-- singleton
local infoMgr               = import("...data.information.InfoManager", CURRENT_MODULE_NAME):getInstance()
local panelFactory          = import("..controls.PanelFactory"):getInstance()
local battleManager         = import("..battle.BattleManager",CURRENT_MODULE_NAME):getInstance()
local playerMgr             = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local musicManager          = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()

local resMgr                = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()
local ws                    = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder             = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()



local BattlePanel           = class("BattlePanel", PanelBase)

function BattlePanel.create( params )
  return BattlePanel.new(params)
end

local ANIMATIONS = {
    ENTER   = "in",
    EXIT    = "out"
}

-- 1 BOSS死亡
-- 2 杀敌数量
-- 3 到达终点
local BATTLE_RESULT = {
    RESULT_BOSS_DEAD = 1,
    RESULT_KILL_NUM  = 2,
    RESULT_END_POINT = 3,
}

function BattlePanel:ctor(params)
    BattlePanel.super.ctor(self, params)
    self:enableNodeEvents()
    battleManager:resetBattleManager()
    self.bulletupdate = bulletupdate

    self.gateId         = tonumber(params.gateId)
    printInfo("%%%%%%%%%%%%%%:".. params.gateId)

    self.souls         = {}
    self.exSkill       = nil     --大招奥义
    self.comboNum      = 0       --combo数量
    self.comboCodeTime = 0       --combo冷却时间
    self.recComboNum   = 0
    self.battleResultDelayTime = 0 --战斗结束后延时(s)
    --self.isPause = false
    self.map = panelFactory:createPanel(panelFactory.Panels.GameMap,onPanelClosed,{gateId = self.gateId}):addTo(self)

    self.cameraNode = cc.Node:create()
    self.cameraNode:setAnchorPoint(cc.p(0.5,0.5))
    self.cameraNode:setPosition(cc.p(display.width*0.5,display.height*0.5))
    self.cameraNode:addTo(self)
    
    self.map.midd2Layer:addTo(self.cameraNode):setPosition(cc.p(-display.width*0.5,-display.height*0.5))
    self.map.middLayer:addTo(self.cameraNode):setPosition(cc.p(-display.width*0.5,-display.height*0.5))
    self.map.nearLayer:addTo(self.cameraNode):setPosition(cc.p(-display.width*0.5,-display.height*0.5))
    self.map.frontLayer:addTo(self.cameraNode):setPosition(cc.p(-display.width*0.5,-display.height*0.5))

    self.heroNum = {}
    for k,v in girl.pairsByKeys(playerMgr.heros) do
       table.insert(self.heroNum,k)
    end
    self.hero = Hero.createWithId(self.heroNum[1])
    self.hero:addTo(self.map.nearLayer,1)
    :setPosition(cc.p(BaseRole.HERO_POSITION))
    battleManager.hero = self.hero
    battleManager:setCameraTarget(self.hero)
    
  
    local index = 1
    local count = #playerMgr.goTeams
    for i = 1, count do
     
        local soul = Soul.createWithId(playerMgr.goTeams[i].id)
        --dump(soul.info)
        soul.posId = playerMgr.goTeams[i].order
        soul:addTo(self.map.nearLayer,1)
        soul:setFollowerTarget(self.hero)
        soul:setPosition(soul:getDefaultPosition())
        table.insert(self.souls,soul)
      
    end

    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.BUFF_ADD,handler(self, self.addBuff))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.BULLET_ADD,handler(self, self.addBullet))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.BOSSCOMING_ADD,handler(self, self.addBosscoming))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.SHAKE_ADD,handler(self, self.addShakeScreen))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.BATTLE_RUNAI,handler(self, self.runAi))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.SCALE_CAMERA,handler(self, self.scaleCamera))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_WARNING,handler(self, self.addWarning))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.CLOSE_EXSKILL,handler(self, self.closeExSkill))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.SHOW_MONSTER,handler(self, self.showMonster))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.DMG_MONSTER,handler(self, self.dmgMonster))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_COMBO,handler(self, self.addComboAction))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_DROP,handler(self, self.addDropAction))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.PROCESS_BOSS,handler(self, self.updateBossBarAction))
    ---script---
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_MONSTER,handler(self, self.addMonster))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.REMOVE_MONSTER,handler(self, self.removeMonster))
    MessageManager.addMessage(self, girl.MessageLayer.BATTLE, girl.BattleMessage.ADD_HP_EFF,handler(self, self.addHpNumEff))
end

function BattlePanel:addWarning(body,layer,msg,data)

    local warning = WarningNode:create(data):addTo(self.cameraNode,2000)
    warning:setPosition(cc.p(display.width*0.5,data.pos.y-display.height*0.5))

end

function BattlePanel:addBosscoming(body,layer,msg,data)

    self:pauseAll()
    musicManager:stopAll()
    local bossComing = panelFactory:createPanel(panelFactory.Panels.BossComePanel,handler(self, self.onPanelClosed)):addTo(self:getParent())
    bossComing:setLocalZOrder(200)
    musicManager:play(girl.UiMusicId.BOSS_COMING)
    self.changeBgmId = data.bgmId

end

function BattlePanel:onPanelClosed(reason)

    if reason == "boss" then
       --printInfo("=======self.changeBgmId=========="..self.changeBgmId)
        self:resumeAll()
        musicManager:play(self.changeBgmId)
    elseif reason == "aoyi" then
        self:resumeAll()
        --musicManager:resume()
        -- printInfo("aoyi close")
    end
end

--[技能触发的Buff]
function BattlePanel:addBuff(body,layer,msg,data)

    local emanate   = data.emanate      --发射源(如角色,子弹，场景)
    local skillInfo = emanate.skill.info --data.skillInfo  --获取技能信息
     --dump(skillInfo)
    local buffId = data.buffId or skillInfo.buffId
    local buff = Buff.createWithId(buffId)
    --dump(buff)
    if data.emanateType ~= "BULLET" then

        if  skillInfo.isRandomGunOrder > 0 then
            data.order = math.random(skillInfo.isRandomGunOrder)
        end
        local gunPointInfo = infoMgr:findInfoEx("gunpoints",{key = "skill_id",value = skillInfo.class_id},{key = "order",value = data.order})
         --防错处理:如果循环的枪口order不存在，默认:1
        if gunPointInfo == nil then
            data.order = 1
            gunPointInfo = infoMgr:findInfoEx("gunpoints",{key = "skill_id",value = skillInfo.class_id},{key = "order", value = data.order})                   
        end
        if gunPointInfo == nil then
            buff:removeFromParent()
            return
        end
        --printInfo("++++++++++++++++++++++++++++order:"..data.order)
        --做方向判断处理枪口位置
        local gunX = gunPointInfo.x
        if emanate.dir == BaseRole.dirType.DIR_LEFT then
            gunX  = -gunPointInfo.x
        end
        -- --检测buff目标类型，确定挂在(作用于)什么对像上
        -- --[[1、怪物
        --     2、场景，只伤害怪物
        --     3、自身
        --     4、主角
        --     5、本队
        --     6、场景，只伤害主角
        -- --]]
        if not data.pos then
            -- printInfo("---产生的buff--")
            buff:setPosition(emanate:getPositionX() + gunX + skillInfo.shotWidth ,emanate:getPositionY() + gunPointInfo.y+ skillInfo.shotHeight)
        else
            -- dump(data.pos)
            buff:setPosition(cc.p(data.pos))
        end
    else
        buff:setPosition(data.pos)
    end
    
    self.map.nearLayer:addChild(buff,2048)

    --作用域处理
    --怪 or 场景(怪物)
    if buff.info.target_type == 1 then --作用于怪物（每个怪一个buff）
        --for _,v in ipairs(self.hero.curTargetPool) do
            buff:affectToTarget({emanate = emanate,target = data.target or self.hero.curTargetPool ,affectValue = data.addValue or 0 })
        --end
    elseif buff.info.target_type == 2 then --作用于场景（一个buff，处理n个怪）
        --for _,v in ipairs(self.hero.curTargetPool) do
            buff:affectToTarget({emanate = emanate,target = self.hero.curTargetPool ,affectValue = data.addValue or 0 })
        --end
    elseif buff.info.target_type == 3 then --自身

            buff:affectToTarget({emanate = emanate,target = emanate ,affectValue = data.addValue or 0 })

    elseif buff.info.target_type == 4 then --主角

            buff:affectToTarget({emanate = emanate,target = self.hero ,affectValue = data.addValue or 0 })

    elseif buff.info.target_type == 5 then --本队(如全体加防、加攻...)

        if data.camp == Hero.campType.CAMP_HERO or data.camp == Hero.campType.CAMP_SOUL then --我方全休
            local team = {}
            for _,v in pairs(self.souls) do
              table.insert(team,v)
            end
            table.insert(team,self.hero)
            buff:affectToTarget({emanate = emanate,target = team ,affectValue = data.addValue or 0 })
        elseif data.camp == Hero.campType.CAMP_MONSTER then --敌方全体
            --for _,v in ipairs(self.hero.curTargetPool) do
                buff:affectToTarget({emanate = emanate,target = self.hero.curTargetPool,affectValue = data.addValue or 0 })
            --end
        end

    elseif buff.info.target_type == 6 then --场景(主角)

        buff:affectToTarget({emanate = emanate,target = self.hero ,affectValue = data.addValue or 0 })

    end

    --buff 绘的圆形
    -- local rt = girl.createTestArc(cc.p(buff:getPositionX(),buff:getPositionY()),buff.info.check_dis)
    -- rt:addTo(self.map.nearLayer,2222)
end

--[技能触发的子弹]
function BattlePanel:addBullet(body,layer,msg,data)

    local emanate = data.emanate--发射源(如角色)
    local skillInfo = emanate.skill.info --data.skillInfo  --获取技能信息
    local bulletId = data.bulletId or skillInfo.bulletId

    if  skillInfo.isRandomGunOrder > 0 then
        data.order = math.random(skillInfo.isRandomGunOrder)
    end
    local gunPointInfo = infoMgr:findInfoEx("gunpoints",{key = "skill_id",value = skillInfo.class_id},{key = "order", value =  data.order})
    --防错处理:如果循环的枪口order不存在，默认:1
    if gunPointInfo == nil then
        data.order = 1
        gunPointInfo = infoMgr:findInfoEx("gunpoints",{key = "skill_id",value = skillInfo.class_id},{key = "order", value =  data.order})
        -- printInfo("gunPointInfo == nil  read again .....")
        -- dump(gunPointInfo)
    end
    -- printInfo("skillInfo :"..skillInfo.class_id.. "  order:"..data.order)
    --dump(gunPointInfo)
    --做方向判断处理枪口位置
    if gunPointInfo == nil then
        return
    end
    local gunX = gunPointInfo.x
    if emanate.dir == BaseRole.dirType.DIR_LEFT then
        gunX  = -gunX
    end
    --dump(skillInfo)
    --一次发射弹数
    for i=1,skillInfo.onceBulletNum do
        local randAngle =  skillInfo.sanBu>0 and 2 * math.random(skillInfo.sanBu) - skillInfo.sanBu or 0-- sanBu = 30 ->  angle:[-30,30]
        local bullet = Bullet:create({id = bulletId,dmgValue =skillInfo.atk1/10000.0 * emanate.atk+skillInfo.atk2,
                            range = skillInfo.shotWidth,height = skillInfo.shotHeight,speed = skillInfo.bulletSpeed ,angle = gunPointInfo.angle + randAngle,camp = data.camp
                            ,pos = cc.p(emanate:getPositionX()+gunX,emanate:getPositionY()+gunPointInfo.y),emanate = emanate,target = data.target,checkMod = skillInfo.checkMod})
        --给定穿透次数
        bullet.crossTimes = skillInfo.crossTimes
        self.map.nearLayer:addChild(bullet,emanate:getLocalZOrder()-1)
    end

end

function BattlePanel:addShakeScreen()

    local offset = display.height*0.5
    local times = 0
    local  shakeCall  = cc.CallFunc:create(function()
        if times%2==0 then
          self.cameraNode:setPositionY(offset+16)
        else
          self.cameraNode:setPositionY(offset-16)
        end
        times = times+1
    end)
    local seq  = cc.Sequence:create(cc.DelayTime:create(0.1),shakeCall)
    local actions = cc.Repeat:create(seq,6)
    self.cameraNode:runAction(cc.Sequence:create(actions,cc.CallFunc:create(function()
    self.cameraNode:setPositionY(offset)
    end),nil))

end


function BattlePanel:scaleCamera()

    local  aoyiCall = cc.CallFunc:create(function() 
          self:resumeAll()
      end)
    local scaleTo = cc.ScaleTo:create(0.2,1.5)
    local reverse = cc.ScaleTo:create(0.2,1.0)
    local seq  = cc.Sequence:create(scaleTo,cc.DelayTime:create(1),reverse,aoyiCall,nil)
    self.cameraNode:runAction(seq)

end

function BattlePanel:runAi()

    self:resumeAll()
    musicManager:play(self.map.gateInfo.music_id)
    self.hero:changeStatus(Hero.statusType.STATUS_MOVE,1)
    --self:schedule(self,handler(self, self.updateSelf),0.5)
    self:schedule(self,function()
        self:updateAi(0.5)
    end,0.5)
    self:schedule(self,handler(self,self.update))
end

function BattlePanel:addBattleStart()

    local onBattleStart = panelFactory:createPanel(panelFactory.Panels.PrepareFightPanel,onPanelClosed):addTo(self:getParent())
    onBattleStart:setLocalZOrder(220)
end

--战斗前剧情入口--
function BattlePanel:addBattleScript()

    self:pauseAll()
    if self.map.gateInfo.story_id>0 and playerMgr.gates[self.gateId].attackTimes <= 1 then
        local script = panelFactory:createPanel(panelFactory.Panels.BattleScriptPanel,onPanelClosed):addTo(self)
            script:runScript(resMgr:getResPath(self.map.gateInfo.story_id),function()
            -- printInfo("script close...")
            script:close()
            self:addBattleStart()
        end)
    else
        self:addBattleStart()
    end

end

-- function BattlePanel:updateSelf(dt)
--     --处理游戏
--     self:updateAi(dt)
-- end

function BattlePanel:update()
    --处理镜头
    local target = nil
    for _,v in ipairs(self.souls) do
        if v:getPositionX() > self.hero:getPositionX()  then
            target = v
        end
    end
    if target == nil then
        target = self.hero
    end
    self:soulAtkInOrderUpdate()
    battleManager:setCameraTarget(target)
    --更新combo
    self.ui:setBarInfo({hpText= ""..math.floor(self.hero.curHp) .."/"..math.floor(self.hero.topHp),spText = "100/100",hpPercent = (self.hero.curHp*100.0/self.hero.topHp),spPercent =100/100.0*100,souls = self.souls})
    self.comboCodeTime = self.comboCodeTime + 1/60.0
    if self.comboCodeTime > 1 and self.comboNum >0 then
        self.comboCodeTime = 0
        self.comboNum = 0
        self.ui.comboNode:runAnimation("out",false,function() 
          self.ui.comboNode:hide()
        end)
    end

end

--检测战斗结束
function BattlePanel:checkBattleResult()

    local gateInfo = self.map.gateInfo
    local type = gateInfo.success_type
    local resultCode = -1
    --[[
        1 BOSS死亡
        2 杀敌数量
        3 到达终点
    ]]--
    if type == BATTLE_RESULT.RESULT_BOSS_DEAD then
        if battleManager.isKilledTarget then
            resultCode = 1
        end
    elseif type == BATTLE_RESULT.RESULT_KILL_NUM then
        if battleManager.killNum >= gateInfo.success_condition then
            resultCode = 1
        end
    elseif type == BATTLE_RESULT.RESULT_END_POINT then

        if self.map.mapIdx >= #self.map.maps_id and self.hero:getPositionX() > self.map.mapWidth - self.map.mapPieceWidth then       
            resultCode = 1
        end
    elseif self.hero.curHp <= 0 then
        resultCode = 0
    end
    return resultCode
end

--need add
function BattlePanel:updateAi(dt)

    --printInfo(">>>>>>>>>>>>>>>>>>>battleResultCode:"..battleManager.battleResultCode)
    if battleManager.battleResultCode == -1 then
        local target = self.hero:getCloseTarget(battleManager.monsterPool)
        --dump(target)
        self.hero:setTargetObj(target)
        --dump(self.souls)
        for i,v in ipairs(self.souls) do
           -- dump(v)
            v:setTargetObj(target)
        end
        --胜利处理 跳场景 --need add check map over...
        battleManager.battleResultCode = self:checkBattleResult()
    else
        -- printInfo("battleResultCode:"..battleManager.battleResultCode)
        self.battleResultDelayTime = self.battleResultDelayTime + dt
        if self.battleResultDelayTime < 2.0 then
            -- printInfo("结束延时："..self.battleResultDelayTime)
            return
        end
        self.battleResultDelayTime = 0
        if battleManager.battleResultCode == 1 then --胜利
            printInfo("Battle Win .....")
            printInfo("--check add End-script story -- ")
            self:pauseAll()
            if self.map.gateInfo.story_end_id>0 then
                local script = panelFactory:createPanel(panelFactory.Panels.BattleScriptPanel,onPanelClosed):addTo(self)
                    script:runScript(resMgr:getResPath(self.map.gateInfo.story_end_id),function()
                    printInfo("script close...")
                    script:close()
                    self:resumeAll()
                    self:battleWinResultProcess()
                end)
            else
                self:battleWinResultProcess()
            end
        elseif battleManager.battleResultCode == 0 then --失败
            printInfo("battle lose ...")
            self:pauseAll()
            
            ----失败 啥都不给
            local heroExpTable = {}
            table.insert(heroExpTable,{id = self.hero.class_id, curLv =self.hero.pb.level, curExp = self.hero.pb.exp,
            lastLevel = self.hero.pb.level, lastExp = self.hero.pb.exp, getExp = 0 , getGold = 0})
            -- dump(heroExpTable)
            panelFactory:createPanel(panelFactory.Panels.ResultPanel, onPanelClosed, {id = self.gateId,heroExpTable = heroExpTable ,result = false,lastPanel = self })
            :addTo(self:getParent(),222)
        end
    end
end


function BattlePanel:battleWinResultProcess()

    self:stopAllActions()
    if #self.souls>0 then
        local randIdx = math.random(#self.souls)
        local soundId = self.souls[randIdx].info.success_sound_id
        if soundId>0 then
            musicManager:play(soundId)
        end
    end

    local pb = pbBuilder:build({
    proto = "data/pb/interface/resultBattle.pb",
    desc  = "interface.resultBattle.Request",
    input =  { gate_id = self.gateId,
                star = 4,
                victory =true }
    })
    --发送获取服务器列表请求
    ws:send("RESULTBATTLE", pb, function(resultCode, des, data)
        printInfo("resultCode"..resultCode)
        printInfo("des"..des)
        dump(data)

        local rep = pbBuilder:decode({ proto = "data/pb/interface/resultBattle.pb",
                    desc  = "interface.resultBattle.Response",
                    input = data})

        local v = rep.hero_exp

        self.items = rep.items

        printInfo(rep.hero_exp.class_id,rep.hero_exp.curLevel,rep.hero_exp.curExp)

        self.heroExpTable = {}
        table.insert(self.heroExpTable,{id = v.class_id, curLv =v.curLevel, curExp = v.curExp,
        lastLevel = v.lastLevel, lastExp = v.lastExp, getExp = v.getExp , getGold = self.map.gateInfo.gold})
        dump(self.heroExpTable)

        local soulExpTable = {}
        for k,v in pairs(rep.soul_exp) do
            printInfo("++++++++++++++++++++++++++++++")
            dump(v)
            printInfo("class_id",v.class_id,"curLevel:",v.curLevel,"curExp:",v.curExp,"getExp:",v.getExp,"lastLevel:",v.lastLevel,"lastExp:",v.lastExp)

            table.insert(soulExpTable,{id = v.class_id, curLv =v.curLevel, curExp = v.curExp,
            lastLevel = v.lastLevel, lastExp = v.lastExp, getExp = v.getExp})
        end
        dump(soulExpTable)

        local function onPanelClosed(reason)
            panelFactory:createPanel(panelFactory.Panels.ResultPanel, nil, {items = self.items,heroExpTable = self.heroExpTable,soulExpTable =  soulExpTable,id = self.gateId ,result = true,lastPanel = self })
            :addTo(self:getParent(),222)
        end
        
        panelFactory:createPanel(panelFactory.Panels.ResultWinPanel, onPanelClosed)
        :addTo(self:getParent(),222)

        -- panelFactory:createPanel(panelFactory.Panels.ResultPanel, onPanelClosed, {items = self.items,heroExpTable = self.heroExpTable,soulExpTable =  soulExpTable,id = self.gateId ,result = true,lastPanel = self })
        -- :addTo(self:getParent(),222)
        -- --战斗暂停
        -- self:pauseAll()
    end)

end


function BattlePanel:soulAtkInOrderUpdate(dt)

    local soulsNum = #self.souls
    if soulsNum == 0 then
        return
    end
    for i=1,soulsNum do
        local soul = self.souls[i]
        soul:checkAi()
    end
end

function BattlePanel:onEnter()
    BattlePanel.super.onEnter(self)
    --local soulsId = {}


    self.ui = panelFactory:createPanel(panelFactory.Panels.UIBattlePanel, onPanelClosed,
              {cb = handler(self, self.onUIEvents)})
              :addTo(self)

    self.ui:setSoulsNumber(#self.souls)
    self.ui:setSoulsIcon(self.souls)
  
    battleManager.battleUi = self.ui

         --test
    -- for i=1,1 do
    --     local monster = Monster.createWithId(301)
    --       :setPosition(cc.p(600+600*i,208))
    --     monster.aiId  = 101
    --     monster.curHp = 15000
    --     monster.objType = 4
    --     table.insert(battleManager.monsterPool,monster)
    --     self.map.nearLayer:addChild(monster,1)

    --     -- local tarp = Trap.createWithId(2)
    --     -- :setPosition(cc.p(600+600*i,208-32 ))
    --     -- tarp.otherHalfObj = monster
    --     -- self.map.nearLayer:addChild(tarp,1000)
    --     -- table.insert(battleManager.trapPool,tarp)
    -- end

    --触摸事件
    local lastTouchTime = 0
    local recTouchPos = cc.p(0,0)

    girl.addTouchEventListener(self,{
        swallow = true,
        onBegan = function(touch, event)
            local touchedLoc = touch:getLocation()
            recTouchPos = touchedLoc
            local curTouchTime = os.time()
            if curTouchTime -lastTouchTime<0.25 then
                  --if(self.hero.status == Hero.statusType.STATUS_MOVE) then
                    self.hero:toFastMove()
                  --end
            end
            lastTouchTime = curTouchTime
            -- ----------------test---------------------
            local rt = cc.rect(display.width-80,
                     0,
                     80,
                     80)
            if cc.rectContainsPoint(rt, touchedLoc) then
                musicManager:play(6000004)
                -- if battleManager.isPushMonster == true then
                --     battleManager.isPushMonster=false
                -- else
                --     battleManager.isPushMonster=true
                -- end

                -- if self.isPause == false then
                --     self:pauseAll()
                --     self.isPause = true
                --     printInfo("--------isPause = true--------")
                -- end

            end
            -- --------------test end---------------------------

            return true
        end,
        onMoved = function( touch, event )
            local touchedLoc = touch:getLocation()
            if(recTouchPos.y -16 > touchedLoc.y) then
                --if(self.hero.status == Hero.statusType.STATUS_MOVE) then
                  self.hero:toSkite()
                --end
            --上划 跳
            elseif(recTouchPos.y + 16 < touchedLoc.y) then
                --if (self.hero.status == Hero.statusType.STATUS_MOVE) then
                  self.hero:toJump()
                --end
            end
            --printInfo("onMoved ....")
        end
    })
    self:addBattleScript()


    
end

function BattlePanel:onExit()

    --self:unscheduleEx()
    BattlePanel.super.onExit(self,"BattlePanel")
    for _,v in ipairs(battleManager.recMonster) do
        v:release()
    end
    MessageManager.removeMessageByLayer(girl.MessageLayer.BATTLE)

end
function BattlePanel:reload()

end


function BattlePanel:onUIEvents(params)

    if params.event == self.ui.Events.ON_BUTTON_BACK then
        self.ui:close()
        self:getParent():reloadGates()
        MessageManager.sendMessage(girl.MessageLayer.UI,girl.UiMessage.TOP_IN)
        self:close()
    elseif params.event == self.ui.Events.ON_SKILL_SOUL then
        local soul = self.souls[params.tag]
        if params.touchType == "onMoved" then
            self:showAoYi(soul)
        elseif params.touchType == "onTap" then
            soul:toSkill()
        end
    end

end

---加血跳数字&HeroUI add Eff
function BattlePanel:addHpNumEff(body,layer,msg,data)
    self.ui:setAddHpEff(data)
    self.hero:addHpGreenEff(3,data.addValue)
end
----------------------
--奥义相关处理过程
----------------------

function BattlePanel:showAoYi(soul)
    --check aoyi can release
    if soul.exSkillPoint < soul.exSkillPointMax then
        return
    end
    soul.exSkillPoint = 0
    battleManager.isAoyiAction = true
    self.exSkill = panelFactory:createPanel(panelFactory.Panels.EXskillPanel, handler(self,self.onPanelClosed),{soul = soul})
                         :addTo(self,200)
    self:pauseAll()
    self.exSkill:resumeAll()
end

function BattlePanel:closeExSkill()

    self.exSkill:pauseAll()
    if self.exSkill then
      self.exSkill:close("aoyi")
    end
end

function BattlePanel:showMonster(body,layer,msg,data)

    local soul = data.soul   --奥义动画元神（克隆体）
    local targets ={}

    if (soul.exSkillInfo.monomer == 1) then
        table.insert(targets,self.hero.curTarget)
    else
        targets = self.hero.curTargetPool
    end
    --dump(targets)
    if #targets>=1 then

        local minX = targets[1]:getPositionX()
        local maxX = targets[1]:getPositionX()
        local minY = targets[1]:getPositionY()
        local maxY = targets[1]:getPositionY()

        for i=2,#targets do

            local monster = targets[i]
            local x = monster:getPositionX()
            local y = monster:getPositionY()
            --取出最小和最大posx
            if minX >  x then
                minX = x
            elseif maxX<= x then
                maxX = x
            end
            --取出最小和最大posy
            if minY >  y then
                minY = y
            elseif maxY<=y then
                maxY = y
            end

        end
        ---计算出中心点
        local center = cc.p((maxX + minX)/2,(maxY + minY)/2)
        --dump(center)
        for _,v in ipairs(targets) do

            local monster  = Monster.clone(v)
            monster:setCloneRoot(v)
            monster.curHp = v.curHp
            --dump(monster)
            --计算出相对中心的位置
            -- local x = soul:getPositionX() +  (v:getPositionX() - center.x)
            -- local y = soul:getPositionY() +  (v:getPositionY() - center.y)
            local x = (v:getPositionX() - center.x)
            local y = (v:getPositionY() - center.y)
            monster:setPosition(x,y)
            --printInfo("x:"..x.."y:"..y)
            self.exSkill.objNode:addChild(monster,200)
            table.insert(self.exSkill.targets,monster)

        end

    end

end

function BattlePanel:dmgMonster(body,layer,msg,data)

    for _,v in ipairs(self.exSkill.targets) do

        if v then
           v:damageWithExSkill({dmgValue = data.dmgValue,emanate = data.emanate})
        end

    end

end

function BattlePanel:addComboAction(body,layer,msg,data)
    -- printInfo("<<<<<<<<<<<<<<<<BattlePanel:addComboAction")
    self.ui.comboNode:show()
    if self.comboNum == 0 then
        self.ui.comboNode:runAnimation("in",false)
    else
        self.ui.comboNode:runAnimation("on",false)
    end
    self.comboCodeTime = 0
    self.comboNum = self.comboNum + 1
    self.recComboNum = self.recComboNum + 1
    self.ui.comboNumText:setString(""..self.comboNum)

    --每加一个combo都会处理是否加奥义点
    for _,v in ipairs(self.souls) do
        --每Ｘ个combo增加一个奥义点
        if self.recComboNum >= v.spInfo.riseNeedComboNum then
            self.recComboNum = 0
            v:addExSkillPoint(1)
        end
    end
end


-----add monster------
function BattlePanel:addMonster(body,layer,msg,data)

    local monster = Monster.createOnUiWithId(data.id)
      :setPosition(data.pos)
      --printInfo("BattlePanel:addMonster ....")
    table.insert(battleManager.scriptMonsterPool,monster)
    self.map.nearLayer:addChild(monster, 1)

end

function BattlePanel:removeMonster(body,layer,msg,data)

    local i = 1
    while battleManager.scriptMonsterPool[i] do
        local monster = battleManager.scriptMonsterPool[i]
        if monster.pb.id == data.id then
            local moveTo = cc.MoveTo:create(0.5, cc.p( display.width - battleManager.cameraPos.x, monster:getPositionY()))
            monster:runAction(cc.Sequence:create(moveTo,cc.CallFunc:create(function() 
                    monster:removeFromParent(true)
                    table.remove(battleManager.scriptMonsterPool,i)
                end)))
            break
        else
            i= i+1
        end
    end

end
---add drop ---

function BattlePanel:addDropAction(body,layer,msg,data)
        --add drop goods
    local effTarget = nil
    local targetPos = cc.p(0,0)
    if data.type == DropNode.dropType.DROP_BOX then
        targetPos = cc.p(display.width - 80,40)
    elseif data.type == DropNode.dropType.DROP_EX_SKILL_EXP then
        if #self.souls == 0 then
            return
        end
        local idx = math.random(#self.souls)
        targetPos = cc.p(150+ (idx-1)*250,63)
        effTarget = self.souls[idx]
    elseif data.type == DropNode.dropType.DROP_SP then
        targetPos = cc.p(157,display.height - 50)
        effTarget = self.hero
    elseif data.type == DropNode.dropType.DROP_HP then
        targetPos = cc.p(157,display.height - 20)
        effTarget = self.hero
    else
        printInfo("err: random wrong drop type ...")
    end
    musicManager:play(girl.UiMusicId.PICK_UP)
    local drop = DropNode.create({type = data.type,value = data.value,targetPos = cc.p(targetPos),effTarget = effTarget})
    drop:addTo(self.map.nearLayer,100)
    drop:setPosition(cc.p(data.pos))

    local jump = cc.JumpTo:create(0.2,cc.p(data.pos),80,1)
    local move = cc.MoveBy:create(0.2,cc.p(128,0))
    local action= cc.Spawn:create(jump,move)
    drop:runAction(action)

end


--- boss bar info actions 
function BattlePanel:updateBossBarAction(body,layer,msg,data)
    if self.ui then
       self.ui:setBossHpBar(data)
    end
    
end
return BattlePanel



--[[
为Node添加触摸回调
params
swallow    : == ture of false, default is false
onBegan    : == function
onMoved    : == function
onCancelled: == function
onEnded    : == function
]]--
function girl.addTouchEventListener(node,params)

    local l = cc.EventListenerTouchOneByOne:create()
    l:setSwallowTouches(params.swallow or false)

    if true == params.swallow and nil == params.onBegan then
        -- 注册默认的handler
        l:registerScriptHandler(function(touch,event) return true end,cc.Handler.EVENT_TOUCH_BEGAN)
    else
        l:registerScriptHandler(params.onBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    end

    if nil ~= params.onMoved then
        l:registerScriptHandler(params.onMoved, cc.Handler.EVENT_TOUCH_MOVED)
    end
    if nil ~= params.onCancelled then
       l:registerScriptHandler(params.onCancelled, cc.Handler.EVENT_TOUCH_CANCELLED)
    end
    if nil ~= params.onEnded then
       l:registerScriptHandler(params.onEnded, cc.Handler.EVENT_TOUCH_ENDED)
    end

    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(l, node)
    return l
end

--[[
    清除所有监听
]]
-- function girl.removeAllEventListeners(node)
--     local eventDispatcher = node:getEventDispatcher()
--     eventDispatcher:removeAllEventListeners(node)
-- end

--[[
为Node添加事件回调
params:
onEnter = function
onExit = function
]]--
function girl.registerScriptHandler(node,params)
    local function onNodeEvent(event)
        if nil ~= params.onEnter and "enter" == event then
            params.onEnter()
        elseif nil ~= params.onExit and "exit" == event then
            params.onExit()
        elseif nil ~= params.onEnterTransitionFinish and "enterTransitionFinish" == event then
            params.onEnterTransitionFinish()
        elseif nil ~= params.onExitTransitionStart and "exitTransitionStart" == event then
            params.onExitTransitionStart()
        elseif nil ~= params.onCleanup and "cleanup" == event then
            params.onCleanup()
        end
    end
    node:registerScriptHandler(onNodeEvent)
end

--[[
返回一个测试矩形的节点
]]
function girl.createTestRect( rect )
  local drawNode = cc.DrawNode:create()
  local polygon = {cc.p(rect.x, rect.y),
                    cc.p( rect.x + rect.width, rect.y ),
                    cc.p( rect.x + rect.width , rect.y + rect.height),
                    cc.p( rect.x , rect.y + rect.height)}
  drawNode:drawPolygon(polygon, 4, cc.c4f(1,0,0,0.5), 1,  cc.c4f(0,1,0,1))
  return drawNode
end

function girl.createTestArc(center,radius)

    local drawNode = cc.DrawNode:create()

    drawNode:drawCircle(center, radius, math.rad(360), 30, false, cc.c4f(1,0,0,0.5))
     return drawNode
end


--[[
这个函数被deprecated了
]]
function performWithDelay(node, callback, delay)
    delay = delay or 0.00001
    if delay > 0 then
        node:runAction(cc.Sequence:create(
            cc.DelayTime:create(delay),
            cc.CallFunc:create(callback)
        ))
    else
        callback()
    end
end


function table.enumTable(tb, index)
    local enumTB = {}
    local enumIndex = index or 0
    for i, v in ipairs(tb) do
        enumTB[v] = enumIndex + i
    end
    return enumTB
end

function girl.pairsByKeys(t)
    local a = {}
    for n in pairs(t) do
        a[#a+1] = n
    end
    table.sort(a)
    local i = 0
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end

-- temp top fix
function girl.fixNodePosition(x,y)
    local config = CC_DESIGN_RESOLUTION
    local size = display.size
    -- local posX = node:getPositionX()
    -- local posY = node:getPositionY()

    return cc.p(x, size.height - (config.height - y))
end

local panelFactory = import(".view.controls.PanelFactory"):getInstance()

function girl.MsgBox(str, who)
    local who = who or 1
    local man = ""
    if who == 1 then
        man = "请联系堡主->"
    else
        man = "请联系大表哥->"
    end
    panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message =man..str})
               :addTo(display.getRunningScene(),999999999)
end

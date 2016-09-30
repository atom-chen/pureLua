
cc.exports.MessageManager = MessageManager or {}

function MessageManager.addMessage(target,layer,msg,backFunc)

    if not backFunc then
        return
    end
    local msgObj = {body = target,func = backFunc}


    if MessageManager[layer] == nil then
        MessageManager[layer] = {}
    end

    local msgLayer = MessageManager[layer]

    if msgLayer[msg] == nil then
        msgLayer[msg] = {}
    end
    if MessageManager.hasMessage(layer, msg,backFunc) then
        return
    end
    table.insert(msgLayer[msg], msgObj)
end

function MessageManager.sendMessage( layer, msg ,data )
    local msgLayer = MessageManager[layer]
    if msgLayer then
        local msgs = msgLayer[msg]
    --    print("[!MSG!]msg send message :")
         --dump(data)
        if msgs == nil then
            return
        end
        for _,l in pairs(msgs) do
            local func = l["func"]
            local body = l["body"]
            -- edit by leo
            if func and body then
                func(body,layer,msg,data)
            end
            -- edit end
        end
    end
end

function MessageManager.hasMessage(layer,msg,func)
    local msgLayer = MessageManager[layer]
    if msgLayer then
        local msgs = msgLayer[msg]
        for k,v in pairs(msgs) do
            if v["func"] == func then
                return true;
            end
        end
    end
    return false
end

--[[
* [removeMessageByName 删除某层的所有事件]
]]
function MessageManager.removeMessageByLayer(layer)
    MessageManager[layer] = nil
end

--[[
* [removeMessageByName 删除某个消息的所有事件]
]]
function MessageManager.removeMessageByLayerName(layer, msgNa)
    local msgLayer = MessageManager[layer]
    msgLayer[msgNa] = nil
end

--[[
* [removeMessageByTarget 删除某个对象的所有事件]
]]
function MessageManager.removeMessageByLayerTarget(layer, target)
    local msgLayer = MessageManager[layer]
    for i,j in pairs(msgLayer) do
        for k,l in pairs(j) do
            local tempTarget = l["body"]
            if tempTarget == target then
                table.remove(j, k)
            end
        end
    end
end

--[[
* [removeMessageFromTargetByName 删除某个对象的某个事件]
]]
function MessageManager.removeMessageFromLayerTargetByName(layer, target, msg)
    local msgLayer = MessageManager[layer]
    local msgs = msgLayer[msg]
    for k,v in pairs(msgs) do
        if v["body"] == target then
            table.remove(msgs, k)
        end
    end
end

function MessageManager.removeAllMessage( ... )
    MessageManager = {}
end

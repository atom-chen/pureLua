function NetWebSocket:getInstance(socket)
    local s = socket or "LOGIC"
    if cc.exports.g_inst[s] == nil then
        cc.exports.g_inst[s] = NetWebSocket.new(NetWebSocket.Socket[s])
    end
    return cc.exports.g_inst[s]
end
--
local CURRENT_MODULE_NAME = ...
cc.exports.g_inst = {}
cc.exports.g_token = 0
-- tools
local crypto = import(".crypto", CURRENT_MODULE_NAME)
-- singleton
local pbBuilder = import(".ProtobufBuilder",CURRENT_MODULE_NAME):getInstance()
local eventMgr = import("..data.EventManager",CURRENT_MODULE_NAME):getInstance()
local panelFactory = import("..view.controls.PanelFactory",CURRENT_MODULE_NAME):getInstance()
local NetWebSocket = class("NetWebSocket")
--
if DEBUG < 2 then
    NetWebSocket.host               = "123.59.70.52" --"192.168.0.12" --"123.59.70.52"
    NetWebSocket.port               = "8098" --"内网8092" --"外网8098"
else
    NetWebSocket.host               = "192.168.0.108" --"192.168.0.12" --"123.59.70.52"
    NetWebSocket.port               = "8092" --"内网8092" --"外网8098"
end
--
NetWebSocket.KEEPALIVE          = 120
NetWebSocket.INTERVAL           = 3.0
NetWebSocket.MAX_ERROR_TIMES    = 5
NetWebSocket.TIMEOUT_LIMIT      = 600
--
NetWebSocket.State = table.enumTable{
    "OPEN",
    "OPENING",
    "MANUAL_CLOSE",
    "CLOSE",
}
--
NetWebSocket.Socket = {
    LOGIC={host=NetWebSocket.host, port=NetWebSocket.port},
    CHAT={host=NetWebSocket.host, port=8094},
}

-- 后面改成多链接了。。。

--local ws                  = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance("CHAT")
function NetWebSocket:ctor(socket)
    self.state = NetWebSocket.State.CLOSE;
    -- re链接次数
    self.errorCount = 0

    -- 心跳计时器
    self.keepTime = 0
    -- 发送消息队列
    self.sendMessages = {}

    self:connect(socket.host, socket.port)
end

function NetWebSocket:connect(host, port, func)

    printInfo("[WebSocket] connect() host:%s, port:%s",self.host, self.port)

    if self.host ~= host or
        self.port ~= port then
        self:close()
    end

    self.host = host
    self.port = port
    self.func = func

    if not self:isReady() then
        -- websocket handle
        self.ws = nil

        -- 生成id为了以后发送相同message分辨
        self.tagCount = 1
        -- 计算timeout的句柄
        self.scheduler = nil

        -- 监听队列
        self.listeners = {}

        -- host写死不动态更新
        printInfo("[WebSocket] connect() create:%s","ws://"..self.host..":"..self.port )
        self.ws = cc.WebSocket:create("ws://" .. self.host .. ":" .. self.port)

        self.ws:registerScriptHandler(handler(self, self.onOpen),cc.WEBSOCKET_OPEN)
        self.ws:registerScriptHandler(handler(self, self.onMessage),cc.WEBSOCKET_MESSAGE)
        self.ws:registerScriptHandler(handler(self, self.onClose),cc.WEBSOCKET_CLOSE)
        self.ws:registerScriptHandler(handler(self, self.onError),cc.WEBSOCKET_ERROR)
        self.state = NetWebSocket.State.OPENING;
    else
        printInfo("[WebSocket] connect() same connected!")
        -- 如果相同的ip和prot直接通知成功，不断链接
        if self.func then
            self.func()
            self.func = nil
        end
    end
end

function NetWebSocket:close()
    self.state = NetWebSocket.State.MANUAL_CLOSE;
    if self.ws then
        self.ws:close()
        self.ws = nil
    end
    self:unschedule()
end

function NetWebSocket:makeTag()
    self.tagCount = self.tagCount + 1
    return self.tagCount
end

function NetWebSocket:send(cmd, data, func)
    -- 生成大包小的pb结构
    local pb = {proto = "data/pb/interface/interfaces.pb",
                desc  = "interface.ClientMessageRequest",
                input = { cmd   = cmd,
                          id    = self:makeTag(),
                          token = tostring(cc.exports.g_token),
                          data  = crypto.encodeBase64(data) or ""}}

    -- dump(pb)
    local data = pbBuilder:build(pb)

    -- 转base64
    local encodeData = crypto.encodeBase64(data)
    -- dump(data)
    -- print("base:",encodeData)
    local send = {cmd = cmd, id = pb.input.id, data = encodeData, func = func, timeout = NetWebSocket.TIMEOUT_LIMIT}

    -- 加入队列
    printInfo("[WebSocket] send() add sendMessages list cmd:%s token:%s",cmd,cc.exports.g_token)
    table.insert(self.sendMessages, send)

    -- ok发送
    self:sendRequest()
end

function NetWebSocket:onOpen()
    printInfo("[WebSocket] onOpne() open succeed addr:%s","ws://"..self.host..":"..self.port )
    self.state = NetWebSocket.State.OPEN;
    self:schedule()
    if self.func then
        self.func()
        self.func = nil
    end
end

function NetWebSocket:onMessage(data)

    local pb = pbBuilder:decode({proto = "data/pb/interface/interfaces.pb",
                                desc   = "interface.ClientMessageResponse",
                                input  = crypto.decodeBase64(data)})
    if not pb then
        printInfo("[WebSocket] onMessage() server get error message!")
        return
    end

    -- 更新服务器给的token
    if string.len(pb.token) > 0 and pb.token ~= "0" then
        cc.exports.g_token = pb.token
    end
    print("g_token:", cc.exports.g_token)
    print("pb.token:", pb.token)
    -- temp code 服务器返回消息成功失败
    if pb.resultCode ~= 0 and pb.resultCode < 10000 then
        printInfo("[WebSocket] [Error] server get resultCode:%s", pb.resultCode)
        local strCode = Strings.RESULTCODE[tostring(pb.resultCode)]
        local showCode = nil
        if strCode == nil then
            showCode = string.format("未知服务器的错误码：%d",pb.resultCode)
        else
            showCode = string.format("服务器的错误：%s",strCode)
        end
        girl.MsgBox(showCode)
    end

    printInfo("[WebSocket] onMessage cmd:%s", pb.cmd)
    printInfo("[WebSocket] onMessage server give me token:%s my token: %s", pb.token, cc.exports.g_token)
    -- dump(pb)

    -- base64转pbData
    local decodeData = crypto.decodeBase64(pb.data)

    -- 处理全局 event
    eventMgr:push(pb.events)

    -- sendmessage 监听
    for i,v in ipairs(self.sendMessages) do
        print(v.id,pb.id)
        if v.id == pb.id then
            if v.func then v.func(pb.resultCode, pb.des, decodeData) end
            printInfo("[WebSocket] send() Callfunc remove sendMessages list cmd:%s",v.cmd)
            table.remove(self.sendMessages, i)
            break
        end
    end

    -- addListener 监听
    if self.listeners[pb.cmd] then
        for _,v in pairs(self.listeners[pb.cmd]) do
            if v.func then
                v.func(pb.resultCode, pb.des, decodeData)
            else
                printInfo("[WebSocket] onMessage() linstener func is nil remove form xxx")
                self:removeListener(pb.cmd, v.tag)
            end
        end
    end


end

function NetWebSocket:onClose()
    self.ws = nil
    self:unschedule()
    if self.state == NetWebSocket.State.MANUAL_CLOSE then
        -- girl.MsgBox("网络内部中断")
        printInfo("[WebSocket] onClose() inside close ")
    else
        printInfo("[WebSocket] onClose() outside close ")
        self:reconnect()
    end
end

function NetWebSocket:onError(data)
    printInfo("[WebSocket] onError() data:%s.",tostring(data))
end

function NetWebSocket:reconnect()

    if self.errorCount > NetWebSocket.MAX_ERROR_TIMES then
        girl.MsgBox("网络外部中断")
        printInfo("[WebSocket] reconnect() real don't connect succeed")
        return
    end

    self.errorCount = self.errorCount + 1
    self:connect(self.host, self.port, function()
        girl.MsgBox("重新链接服务器")
        printInfo("[WebSocket] reconnect() succeed!")
        self:send("RECONNECT")
    end)

    printInfo("[WebSocket] reconnect() connect count: %d", self.errorCount)
end

function NetWebSocket:isReady()
    if  self.ws ~= nil and
        self.ws:getReadyState() == cc.WEBSOCKET_STATE_OPEN then
        return true
    else
        if self.ws then
            printInfo("[WebSocket] isReady() ws state: %d", self.ws:getReadyState())
        end
        printInfo("[WebSocket] isReady() self.ws state: %d", self.state)
        return false
    end
end

function NetWebSocket:sendRequest()
    for i,v in ipairs(self.sendMessages) do
        -- websocket自己计算timeout
        v.timeout = v.timeout - NetWebSocket.INTERVAL
        if v.timeout <= 0 then
            printInfo("[WebSocket] send() Timeout remove sendMessages list cmd:%s",v.cmd)
            table.remove(self.sendMessages, i)
            printInfo("[WebSocket] sendRequest() timeout cmd:%s id:%d",v.cmd, v.id )
            girl.MsgBox("网络超时了")
            if v.func then v.func(nil) end
        else
            -- 发送
            if self:isReady() then
                -- 网络ok发送,剩余消息发送
                if v.data ~= nil then
                    printInfo("[WebSocket] sendRequest() send message list now:%s",v.cmd)
                    self.ws:sendString(v.data)
                end
                -- 发送数据清空，等onMessage或者Timeout
                v.data = nil
            else
                printInfo("[WebSocket] sendRequest() not Ready sendRequest" )
            end
        end
    end
end

function NetWebSocket:addListener(cmd, func)
    if not self.listeners[cmd] then
        self.listeners[cmd] = {}
    end
    local lstr = { tag = self:makeTag(), func = func }
    table.insert(self.listeners[cmd], lstr)

    printInfo("[WebSocket] addListener() cmd: %s,get tag: %d", cmd,lstr.tag)
    return tag
end

function NetWebSocket:removeListener(cmd, tag)
   -- printInfo("[WebSocket] removeListener() cmd: %s, tag: %d", cmd)
    if not tag then
        self.listeners[cmd] = nil
    else
        for i,v in ipairs(self.listeners[cmd]) do
            -- print(i,v)
            if v.tag == tag then
                self.listeners[cmd][tag] = nil
                table.remove(self.listeners[cmd], i)
            end
        end

    end
end

function NetWebSocket:keepAlive(dt)
    self.keepTime = self.keepTime + dt
    if self.keepTime >= NetWebSocket.KEEPALIVE then
        printInfo("[WebSocket] keepAlive() ")
        self.ws:sendString("_")
        self.keepTime = 0
    end
end

function NetWebSocket:schedule()
	local function onSchedule(dt)
        self:keepAlive(dt)
		self:sendRequest()
	end

	if not self.scheduler then
        local scheduler = cc.Director:getInstance():getScheduler()
		self.scheduler = scheduler:scheduleScriptFunc(onSchedule, NetWebSocket.INTERVAL, false)
	end
end

function NetWebSocket:unschedule()
	if self.scheduler then
        local scheduler = cc.Director:getInstance():getScheduler()
		scheduler:unscheduleScriptEntry(self.scheduler)
		self.scheduler = nil
	end
end



return NetWebSocket

local CURRENT_MODULE_NAME = ...

-- classes
local AnimationNode = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local PanelBase     = import("..controls.PanelBase", CURRENT_MODULE_NAME)
local GridView      = import("..controls.GridView", CURRENT_MODULE_NAME)
local ServerItem    = import("..fragment.LoginPanelFragment.ServerItem", CURRENT_MODULE_NAME)
local EditBoxNode   = import("..fragment.EditBoxNode", CURRENT_MODULE_NAME)
local BgImageNode   = import("..fragment.BgImageNode",CURRENT_MODULE_NAME)

local crypto = import("...extra.crypto", CURRENT_MODULE_NAME)

-- singleton
local panelFactory  = import("..controls.PanelFactory", CURRENT_MODULE_NAME):getInstance()
local musicManager  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()



local LoginPanel    = class("LoginPanel", PanelBase)


function LoginPanel.create()
  return LoginPanel.new({ csbName = "layers/Login.csb"})
end

function LoginPanel:ctor(params)

    LoginPanel.super.ctor(self, params)
    self:enableNodeEvents()
    self:mapUiElements({"logoNode","loginNode","signinNode","login_account","login_password",
                      "touchNode","serverNode","listNode","signinName","Button_1",
                      "signinPassword","phone","confirm","signinButton","cancelButton",
                      "okButton","loginButton","text","showServer","lineupNode","verText"})

    self.account  = 1 -- 标注是否为登陆或注册界面，若跳出选择服务器界面则为0
    self.openList = 1 -- 服务器列表弹出时为0

    self.gridView = nil

    self.selectServerName  =  AnimationNode.seek(self.showServer, "serverName")  --登陆成功后跳转显示的上次登陆服务器的名字和状态
    self.selectServerState =  AnimationNode.seek(self.showServer, "stateNode")

    self.NewServers = {}

    self.countText = AnimationNode.seek(self.lineupNode,"countText")
    self.minuteText = AnimationNode.seek(self.lineupNode,"minuteText")
    self.secondText = AnimationNode.seek(self.lineupNode,"secondText")
    self.queueCancelButton = AnimationNode.seek(self.lineupNode,"cancelButton")

end

function LoginPanel:onEnter()

    LoginPanel.super.onEnter(self)
    self.logoNode:runAnimation("in", false,function()
    	  self.logoNode:runAnimation("loop", true)
    end)

    self.bgImage = BgImageNode.seek(self,"bgImage",108)

    self.verText:setVisible(false)

    -- self.bgImagePanel1:setTextureByPlist("sundry/textures/background/loginbg01.png")
    -- self.bgImagePanel2:setTextureByPlist("sundry/textures/background/loginbg02.png")

    self.touchNode:hide()   ---touch to start  进入游戏按钮，开始设置为隐藏

    self.loginNode:runAnimation("in", false,function()
    end)

    self.signinNode:hide()   -- 注册Node   整体先设置隐藏
    self.serverNode:hide()   -- 服务器Node  整体先设置隐藏

    self.lineupNode:hide()   -- 排队Node


    self:editBoxInit()       -- editBox整体初始化
    print("开始创建")


-----------------------------界面左下角账号按钮，用于登陆以后出现服务器列表后切换账号用--------------------------

    self:onButtonClicked("accountButton", function()
       --若为登陆或服务器界面时候直接return
       if self.account == 1 then
         return
       end
       musicManager:play(girl.UiMusicId.CLICK_BTN)
       self.account = 1
           self.serverNode:runAnimation("out", false,function()
                self.serverNode:hide()
           end)
           self.touchNode:hide()
           self.loginNode:show()
           self.EditName:setPositionY(self.EditName:getPositionY()+1000)
           self.EditPassword:setPositionY(self.EditPassword:getPositionY()+1000)
           self.loginNode:runAnimation("in")
    end)

 ---------------------------登陆按钮--------------------------

    self:onButtonClicked("loginButton", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.loginButton:setTouchEnabled(false)
        print(self.EditName:getText())
        --每次发送登陆请求前先将上次登陆服务器Id 设置为nil，因为玩家切换账号了不同的号上次选择的服务器不同
        self.lastTimeServerId = nil

        --验证用户名和密码是否为空，非法字符部分在注册模块那里处理过了
        if self.EditName:getText() == "" or self.EditPassword:getText() =="" or self.EditPassword:getText() =="" and self.EditName:getText()=="" then
            panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "请输入账号或密码"}):addTo(self,500)
            self.loginButton:setTouchEnabled(true)
            return
        end

        self:sendLoginRequest()
    end)

--------------------------注册按钮-------------------------------
    self:onButtonClicked("signinButton", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)

        self.signinButton:setTouchEnabled(false)
        self.EditName:setPositionY(self.EditName:getPositionY()-1000)
        self.EditPassword:setPositionY(self.EditPassword:getPositionY()-1000)

        self.loginNode:runAnimation("out", false, function()
           self.loginNode:hide()
           self.signinNode:show()
           self.cancelButton:setTouchEnabled(true)
           self.s_EditName:setPositionY(self.s_EditName:getPositionY()+1500)
           self.s_EditPassword:setPositionY(self.s_EditPassword:getPositionY()+1500)
           self.confirmPassword:setPositionY(self.confirmPassword:getPositionY()+1500)
           self.phoneText:setPositionY(self.phoneText:getPositionY()+1500)
           self.signinNode:runAnimation("in", false)
        end)
    end)

--------------------------注册(取消)-------------------------------
    self:onButtonClicked("cancelButton", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.cancelButton:setTouchEnabled(false)
        self.s_EditName:setPositionY(self.s_EditName:getPositionY()-1500)
        self.s_EditPassword:setPositionY(self.s_EditPassword:getPositionY()-1500)
        self.confirmPassword:setPositionY(self.confirmPassword:getPositionY()-1500)
        self.phoneText:setPositionY(self.phoneText:getPositionY()-1500)

        self.signinNode:runAnimation("out", false, function()
            self.signinNode:hide()
            self.loginNode:show()
            self.signinButton:setTouchEnabled(true)
            self.EditName:setPositionY(self.EditName:getPositionY()+1000)
            self.EditPassword:setPositionY(self.EditPassword:getPositionY()+1000)
            self.loginNode:runAnimation("in", false)
        end)
    end)

--------------------------注册(完成)-------------------------------
    self:onButtonClicked("okButton", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        self.okButton:setTouchEnabled(false)
        print("完成按钮")

        -----检验输入用户名和密码是否为空
        if self.s_EditName:getText() == "" or self.s_EditPassword:getText() =="" or self.s_EditPassword:getText() =="" and self.s_EditName:getText()=="" then
            print("请输入账号或密码")
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "请输入账号或密码"})
            :addTo(self,500)
            self.okButton:setTouchEnabled(true)
            return
        end

        local strName           = self.s_EditName:getText()
        local strPassword       = self.s_EditPassword:getText()
        local lenInByteName     = #strName
        local lenInBytePassword = #strPassword

        if lenInByteName < 4  then
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "账号长度必须为4-12位"})
            :addTo(self,500)
            self.okButton:setTouchEnabled(true)
            return
        end

        if lenInBytePassword < 4  then
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "密码长度必须为4-12位"})
            :addTo(self,500)
            self.okButton:setTouchEnabled(true)
            return
        end

        for i=1,lenInByteName do
            local curByte = string.byte(strName, i)
            local byteCount = 1;
            if curByte>=48 and curByte<=57 or curByte>=65 and curByte<=90 or curByte==95 or curByte>=97 and curByte<=122  then
                print("英文数字、符号、下划线")
            else
                print("用户名中不能使用英文字母、数字和下划线以外的符号")
                local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "用户名中不能使用英文字母、数字和下划线以外的符号"}):addTo(self,500)
                self.okButton:setTouchEnabled(true)
                return
            end
        end

        for i=1,lenInBytePassword do
            local curByte = string.byte(strPassword, i)
            local byteCount = 1;
            if curByte>=27 and curByte<=126 then
                print("ok")
            else
                print("密码中不能使用中文和表情以及其他字符")
                local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "密码中不能使用中文和表情以及其他字符"}):addTo(self,500)
                self.okButton:setTouchEnabled(true)
                return
            end
        end

        if self.confirmPassword:getText() ~= self.s_EditPassword:getText()then
            print("密码不一致")
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "密码不一致"}):addTo(self,500)
            self.okButton:setTouchEnabled(true)
            return
        end

        if self.phoneText:getText() == "" or #self.phoneText:getText() < 1 then
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "请输入激活码"}):addTo(self,500)
            self.okButton:setTouchEnabled(true)
            return
        end




        self:sendRegisterRequest()
    end)

--------------------------进入服务器列表按钮-------------------------------
    self:onButtonClicked("serverButton", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)

        self.serverNode:runAnimation("list_in",false)
        self.openList = 0
        --获取服务器列表
        local size =  self.listNode:getCascadeBoundingBox()
        -- dump(size)
        if nil == self.gridView then
            self.gridView = GridView:create({
            rect             = cc.rect(0,0,size.width,size.height),
            numItems         = 2,
            Item             = ServerItem,
            space            = 20,
            autoLayoutCell   = true,
            cb_onCellTouched = function(item,idx) self:onCellTouched(item,idx) end,
            cb_onNumCells    = function(cell) return #playerMgr.servers end,
            cb_onAddItem     = function(item,idx) self:onAddItem(item,idx) end
            -- cellData         = playerMgr.servers
            }):addTo(self.listNode,200)
        end
    end)


----------------------背景图事件按钮-----------------------------
    self.Button_1:onClicked(function()
           print("Button_1Button_1")
        if self.openList == 1 then
            return
        end
        self.openList = 1
        self.serverNode:runAnimation("list_out",false)
    end)


    -- girl.addTouchEventListener(self,{
    --     onBegan = function(touch,event)
    --         if self.openList == 1 then
    --         return
    --         end
    --         self.openList = 1
    --         self.serverNode:runAnimation("list_out",false)
    --         return true
    --     end
    -- })

-----------------------TOUCH TO START----------------------------------------

    self:onButtonClicked("button", function()
        musicManager:play(girl.UiMusicId.CLICK_BTN)
        --test pb start-----------------------
        self:sendEnterGameRequest()
    end)

    self.queueCancelButton:onClicked(function()
        self.queueCancelButton:setTouchEnabled(false)
        ws:removeListener("ENTER_QUEUE")
        ws:close()
        self.lineupNode :runAnimation("out",false,function ()
            self.account = 0
            self.lineupNode:hide()
            self.queueCancelButton:setTouchEnabled(true)
            self.serverNode:show()
            self.touchNode:show()
        end)
    end)

end

function LoginPanel:editBoxInit()

    local name = cc.UserDefault:getInstance():getStringForKey("userName")
    local passw = cc.UserDefault:getInstance():getStringForKey("passWord")

    print(name)
    print(passw)

    ------------------------login--------------------------------------------------------
    ----------登陆框 输入用户名---------------------------------
    self.EditName = EditBoxNode:create()
    if name == "" then
        self.EditName:setPlaceHolder("请输入用户名")
    else
        self.EditName:setText(name)
    end
    self.login_account:addChild(self.EditName)

    ----------登陆框 输入密码--------------------------------
    self.EditPassword = EditBoxNode:create()
    if passw == "" then
        self.EditPassword:setPlaceHolder("请输入密码")
    else
        self.EditPassword:setText(passw)
    end
    self.EditPassword:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    self.login_password:addChild(self.EditPassword)

    ---------------------------------------signin---------------------------------------
    ----------用户名----------------------------------
    self.s_EditName = EditBoxNode:create()
    self.s_EditName:setPlaceHolder("英文数字下划线最多12个字符")
    self.signinName:addChild(self.s_EditName)
    self.s_EditName:setPositionY(self.s_EditName:getPositionY()-1500)

    ----------密码------------------------------------
    self.s_EditPassword = EditBoxNode:create()
    self.s_EditPassword:setPlaceHolder("请输入密码")
    self.s_EditPassword:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    self.signinPassword:addChild(self.s_EditPassword)
    self.s_EditPassword:setPositionY(self.s_EditPassword:getPositionY()-1500)

    ----------确认密码----------------------------------
    self.confirmPassword = EditBoxNode:create()
    self.confirmPassword:setPlaceHolder("再次输入密码")
    self.confirmPassword:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    self.confirm:addChild(self.confirmPassword)
    self.confirmPassword:setPositionY(self.confirmPassword:getPositionY()-1500)

    ----------手机号码----------------------------------
    self.phoneText = EditBoxNode:create()
    self.phoneText:setPlaceHolder("请输入激活码")
    self.phone:addChild(self.phoneText)
    self.phoneText:setPositionY(self.phoneText:getPositionY()-1500)

end


function LoginPanel:sendLoginRequest()

    --发送登陆请求，resultCode=0 则成功并给玩家上次登陆服务器ID（第一次玩则给NIL），成功后紧接着发送服务器列表请求
    local decodePwd = crypto.md5(self.EditPassword:getText())
    printf("decodePwd:%s", decodePwd)
    local pb    = pbBuilder:build({
    proto = "data/pb/interface/login.pb",
    desc  = "interface.login.Request",
    input = {udid      = self.EditName:getText(),
            password  = decodePwd,
            originId  = 0,
            machineID = "222222",
            device    = "11111",
            os        = "macos" }})

    self.load = panelFactory:createPanel(panelFactory.Panels.LoadingPanel):addTo(self,600)

    ws:send( "LOGIN", pb, function(resultCode, des, data)

        print("LOGIN:",resultCode)
        print("LOGIN:",des)
        print(data)
        if data then
            -- 非第一次登陆
            local rep = pbBuilder:decode({ proto = "data/pb/interface/login.pb",
                                            desc  = "interface.login.Response",
                                            input = data})
            dump(rep)
            --获取上次登录的服务器ID
            self.lastTimeServerId = rep.id
        end

        -- 返回0代表成功登陆，发送服务器列表请求
        if resultCode == 0 then
            self:sendServerListRequest()
            -- 登陆成功后，本地保存玩家的用户名和密码 下次登陆的时候直接显示
            cc.UserDefault:getInstance():setStringForKey("userName", self.EditName:getText())
            cc.UserDefault:getInstance():setStringForKey("passWord", self.EditPassword:getText())

            self.loginButton:setTouchEnabled(true)
            self.account = 0
            self.EditName:setPositionY(self.EditName:getPositionY()-1000)
            self.EditPassword:setPositionY(self.EditPassword:getPositionY()-1000)

            self.loginNode:runAnimation("out", false, function()
                self.loginNode:hide()
                self.touchNode:show()
                self.serverNode:show()

                self.touchNode:runAnimation("in",false,function()
                    self.touchNode:runAnimation("loop",true)
                end)
                self.serverNode:runAnimation("in")
            end)
        else
            --如果登陆不成功  消息框显示错误信息（未注册，密码错误等等）
            self.load:close()
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = des,code = 999}):addTo(self,500)
            self.loginButton:setTouchEnabled(true)
        end
    end)
end


function LoginPanel:sendServerListRequest()

    local pb = pbBuilder:build({proto = "data/pb/interface/serverlist.pb",
                                desc  = "interface.serverlist.Request",
                                input = {}})

    --发送获取服务器列表请求
    ws:send( "SERVERLIST", pb, function(resultCode, des, data)
        self.load:close()
        if resultCode == 0 then
            local rep = pbBuilder:decode({ proto = "data/pb/interface/serverlist.pb",
                                            desc  = "interface.serverlist.Response",
                                            input = data})
            playerMgr:setServer(rep)
            for i,v in ipairs(playerMgr.servers) do
                -- self.lastTimeServerId == nil 为玩家第一次玩游戏，那么就去查找列表里推荐的服务器ID
                if self.lastTimeServerId == nil then
                    if v.class_id == playerMgr.commend then
                        self.text:setString("推荐服务器")
                        self.selectServerName:setString(v.name)
                        self.selectServerState:runAnimation(v.state)
                        self.selectServer = v
                    end
                else
                    if self.lastTimeServerId == v.class_id then
                        self.text:setString("上次登录")
                        self.selectServerName:setString(v.name)
                        self.selectServerState:runAnimation(v.state)
                        self.selectServer = v
                    end
                end
            end
        else
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = des,code = 999}):addTo(self,500)
            self.loginButton:setTouchEnabled(true)
        end
    end)
end


function LoginPanel:sendRegisterRequest()

    local pb = pbBuilder:build({proto = "data/pb/interface/register.pb",
                                desc  = "interface.register.Request",
                                input = {   udid        = self.s_EditName:getText(),
                                            password    = self.s_EditPassword:getText(),
                                            originId    = 0,
                                            machineID   = "222222",
                                            device      = "11111",
                                            os          = "macos",
                                            phone       = "",
                                            code        = self.phoneText:getText()}
    })

    ws:send( "REGISTER", pb, function(resultCode, des)
        print("REGISTER:", resultCode,des)

        local function onPanelClosed(reason)
            if reason =="success" then
                self.cancelButton:setTouchEnabled(false)

                self.s_EditName:setPositionY(self.s_EditName:getPositionY()-1500)
                self.s_EditPassword:setPositionY(self.s_EditPassword:getPositionY()-1500)
                self.confirmPassword:setPositionY(self.confirmPassword:getPositionY()-1500)
                self.phoneText:setPositionY(self.phoneText:getPositionY()-1500)

                self.signinNode:runAnimation("out", false, function()
                    self.signinNode:hide()
                    self.loginNode:show()
                    self.signinButton:setTouchEnabled(true)
                    self.okButton:setTouchEnabled(true)
                    self.EditName:setPositionY(self.EditName:getPositionY()+1000)
                    self.EditPassword:setPositionY(self.EditPassword:getPositionY()+1000)

                    --注册成功后直接把玩家用户名密码输入在登陆界面的输入框中
                    self.EditName:setText(self.s_EditName:getText())
                    self.EditPassword:setText(self.s_EditPassword:getText())
                    self.loginNode:runAnimation("in", false)
                end)
            end
        end

        if resultCode == 0 then
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,onPanelClosed,{message = des,code = resultCode}):addTo(self,500)
            self.okButton:setTouchEnabled(true)
        else
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,onPanelClosed,{message = des,code = resultCode}):addTo(self,500)
            self.okButton:setTouchEnabled(true)
        end

    end)
end


function LoginPanel:sendEnterGameRequest()

    local pb = pbBuilder:build({proto = "data/pb/interface/enterGame.pb",
                            desc  = "interface.enterGame.Request",
                            input = { id = self.selectServer.class_id, udid = self.EditName:getText()} })

    self.load = panelFactory:createPanel(panelFactory.Panels.LoadingPanel):addTo(self,600)

    ws:send( "ENTERGAME", pb, function(resultCode, des, data)
        if resultCode == 0 then
            print(self.selectServer.ip)
            print(self.selectServer.port)
            ws:connect(self.selectServer.ip, self.selectServer.port, function()
                self:sendEnterQueueRequest()
            end)

        else
            self.load:close()
            local message = panelFactory:createPanel(panelFactory.Panels.MessageBoxPanel,nil,{message = "连接超时",code = 999}):addTo(self,500)
            -- dump(data)
        end
    end)

end


function LoginPanel:sendEnterQueueRequest()
    local pb = pbBuilder:build({proto = "data/pb/interface/enterQueue.pb",
                                desc  = "interface.enterQueue.Request",
                                input = {} })

    ws:send( "ENTER_QUEUE", pb, function(resultCode, des, data)
        print("~~~~~~~~~~~~~ENTER_QUEUE Listenner!!!")
        local rep = pbBuilder:decode({ proto = "data/pb/interface/enterQueue.pb",
                                        desc  = "interface.enterQueue.Response",
                                        input = data})
        dump(rep)

        self.load:close()

        if rep.bQueue ==true then
            print("rep.bQueue =true")
            self.account = 1
            self.serverNode:hide()
            self.touchNode:hide()
            self.lineupNode:show()
            self.lineupNode:runAnimation("in",false)

            self:queueRefresh(rep.queueLength,rep.queueTime)
        end
    end)

    ws:addListener("ENTER_QUEUE", function ( resultCode, des, data )
        print("ENTER_QUEUE Listenner!!!")
        dump(data)
        local rep = pbBuilder:decode({ proto = "data/pb/interface/enterQueue.pb",
                                        desc  = "interface.enterQueue.Response",
                                        input = data})
        dump(rep)
        if rep.bQueue ==true then
            local randNum = math.random(100)
            local count = rep.queueLength-randNum
            if count <= 0 then
                count = 0
            end
            self:queueRefresh(count,rep.queueTime)
        else
            ws:removeListener("ENTER_QUEUE")

            self.lineupNode:runAnimation("out",false,function()
                local load = panelFactory:createPanel(panelFactory.Panels.LoadingPanel):addTo(self,500)
                ws:send( "GETPLAYERDATA",nil, function(resultCode, des, data)
                    local rep = pbBuilder:decode({ proto = "data/pb/interface/getPlayerData.pb",
                                                    desc  = "interface.getPlayerData.Response",
                                                    input = data})
                    dump(rep.player)
                    playerMgr:setData(rep.player)

                    load:close()
                    self:close("login")
                end)
            end)
        end
    end)

end


function LoginPanel:queueRefresh(count,time)

    self.tm,self.ts  = math.modf(time/60)
    self.ts = 60 * self.ts
    self.ts = math.floor(self.ts)

    self.countText:setString(string.format(count))
    self.minuteText:setString(string.format(self.tm))
    self.secondText:setString(string.format(self.ts))
end


function LoginPanel:closeSelf()
    self:close("login")
end


function LoginPanel:onCellTouched(item,idx)
    print(idx)
    self.text:setString("本次选择")
    self.selectServerName:setString(playerMgr.servers[idx].name)
    self.selectServerState:runAnimation(playerMgr.servers[idx].state)
    self.selectServer = playerMgr.servers[idx]
end

function LoginPanel:onAddItem(item,idx)

    local pb = playerMgr.servers[idx]
    item.serverName:setString(pb.name)
    item.stateNode:runAnimation(pb.state)
    print("pb.state",pb.state)
end

return LoginPanel

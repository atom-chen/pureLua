local CURRENT_MODULE_NAME = ...

-- classes
local crypto              = import("...extra.crypto", CURRENT_MODULE_NAME)
local AnimationNode       = import("..controls.CocostudioNode", CURRENT_MODULE_NAME)
local BgImageNode         = import("..fragment.BgImageNode",CURRENT_MODULE_NAME)
-- singleton
local panelFactory        = import("..controls.PanelFactory"):getInstance()
local pbBuilder           = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
local musicMgr  = import("..controls.MusicManager", CURRENT_MODULE_NAME):getInstance()
local utils               = cc.FileUtils:getInstance()
local user                = cc.UserDefault:getInstance()


local NewUpdateScene = class("NewUpdateScene", import(".SceneBase", CURRENT_MODULE_NAME))

NewUpdateScene.RESOURCE_FILENAME = "layers/Login.csb"

-- config.lua DEBUG 0,1,2
NewUpdateScene.VersionPath = {"online", "show", "dev"}

NewUpdateScene.UserLocalVersion = "localVer"

function NewUpdateScene:onCreate()
    AnimationNode.load("layers/loading.csb"):addTo(self)

    self:mapUiElements({
                        "logoNode","serverNode","touchNode","loginNode","signinNode","lineupNode","accountButton","verText",

                        --  loading
                        "loading","loadingPanel", "loadingBar", "progressLabel", "contentLabel","bg"})

    self.verText:setVisible(false)

    self.downloadPath = ContentManager:getInstance():writableContentPath() .. "zh/"
    printInfo("downloadPath:"..self.downloadPath)

    self.debug = self.VersionPath[DEBUG+1]
    printInfo("debug:"..self.debug)

    self.localVer = user:getStringForKey(self.UserLocalVersion)
    printInfo("localVer:"..self.localVer)

    self.download = {}
end

function NewUpdateScene:onEnter()
    self.serverNode:hide()
    self.touchNode:hide()
    self.loginNode:hide()
    self.signinNode:hide()
    self.lineupNode:hide()
    self.accountButton:hide()
    self.bg:hide()

    self.bgImage = BgImageNode.seek(self,"bgImage",108)
    self.logoNode:runAnimation("in", false, function()
        self.logoNode:runAnimation("loop", true)
    end)

    self.loadingPanel:show()
    self:setPercent(0, 0)
    self:updateCheck()
end

function NewUpdateScene:enterGame()

    local function onPanelClosed(reason)
        if reason == "login" then
            self:getApp():enterScene("GameMainScene")
        end
    end

    local view
    if DEBUG > 1 then
        view = self:getApp():enterScene("LogScene")
    else
        view = panelFactory:createPanel(panelFactory.Panels.LoginPanel, onPanelClosed):addTo(self)
        musicMgr:play(5000015)
    end

    if DEBUG > 0 then
        -- local label = cc.Label:createWithTTF(string.format("版本：%s，这不是正式渠道请勿发布！" , self.debug), "fonts/STHeiti-Medium_1.ttf", 38):addTo(view, 800)
        -- label:setAnchorPoint(cc.p(0.5, 0.5))
        -- label:setPosition(cc.p( display.size.width/2, display.size.height/2))
        -- label:setTextColor(display.COLOR_RED)
    end
end

function NewUpdateScene:updateCheck()
    self.contentLabel:setString(Strings.UPDATE_CHECK)
    HttpHelper.get("http://123.59.70.52:8088/resource/" .. self.debug .. "/config.json", function(params)
        if params.code == 200 then
            local config = json.decode(params.data)
            dump(config)
            local md5Path = utils:fullPathForFilename("md5.bin")
            printInfo("MD5 BIN:"..md5Path)
            local md5 = crypto.md5file(md5Path)
            printInfo("MD5's md5:"..md5.."|"..config.MD5)

            --if config.MD5 == md5 then
                self:enterGame()
            --else
            --     self:md5Check()
            --end
        else
            self.contentLabel:setString("Download Error!")
        end
    end)
end

function NewUpdateScene:md5Check()
    self.contentLabel:setString(Strings.UPDATE_CONFIG)

    -- 准备材料
    local url = "http://123.59.70.52:8088/resource/"..self.debug.."/md5.bin"

    if not utils:isDirectoryExist(self.downloadPath) then
        utils:createDirectory(self.downloadPath)
        print("mkdir:md5")
    end

    local path = self.downloadPath .. "tempmd5.bin"

    -- 下载
    HttpHelper.download(url, path,
    function(params)
        if params.code == 200 then
            self:filesMd5Check()
        else
            self.contentLabel:setString("Download Error!")
        end
    end,
    function(total, current)
    end)
end

function NewUpdateScene:filesMd5Check()
    self.contentLabel:setString(Strings.UPDATE_CONFIG)
    local function check()
        local serverPb = pbBuilder:loadFromFile("data/pb/game/md5.pb","tg.pb.Md5.All","tempmd5.bin")
        local localPb = pbBuilder:loadFromFile("data/pb/game/md5.pb","tg.pb.Md5.All","md5.bin")

        local function findMd5(data, path)
            for _,v in pairs(data) do
                if v.path == path then
                    -- print(path.."|"..v.path)
                    return v.md5
                end
            end
            return ""
        end

        local tagIndex = 1
        for _,v in pairs(serverPb.md5s) do
            -- local md5 = crypto.md5file(utils:fullPathForFilename(v.path))
            local md5 = findMd5( localPb.md5s, v.path )
            -- print(md5.."|"..v.md5)

            if v.md5 ~= md5 then
                local params = { path = v.path, type = v.type, tag = tagIndex }
                tagIndex = tagIndex + 1
                table.insert( self.download, params )
            end
        end

        return (#self.download == 0)
    end

    if check() == false then
        self.downloadTotal = #self.download
        dump(self.download)
        self:downloadFiles()
    else
        printError("md5的md5不一样，但是文件md5都一样")
        self:updateCheck()
    end
end

function NewUpdateScene:downloadFiles()
    self.contentLabel:setString(Strings.UPDATE_DOWNLOAD)
    local function go()
        if #self.download > 0 then
            self:downloadFile(self.download[1], go)
        else
            print("over!!!!")
            if (utils:renameFile(self.downloadPath,"tempmd5.bin","md5.bin") == true) then
                self:enterGame()
            else
                self.contentLabel:setString("md5 rename Error")
            end
            return
        end
    end

    go()
end

function NewUpdateScene:downloadFile(downloadFileParam,func)

    local param = downloadFileParam
    local pathInfo = io.pathinfo(downloadFileParam.path)
    -- 准备材料
    local url = "http://123.59.70.52:8088/resource/"..self.debug.."/content/zh/"..downloadFileParam.type.."/"..downloadFileParam.path

    local dir = self.downloadPath..param.type.."/"..pathInfo.dirname
    print("url:"..url)
    print("dir:"..dir)

    if not utils:isDirectoryExist(dir) then
        utils:createDirectory(dir)
        print("mkdir")
    end

    local path = self.downloadPath..param.type.."/"..param.path
    print("dl:"..path)
    --
    -- -- 下载
    HttpHelper.download(url, path,
    function(params)
        if params.code == 200 then
            for i,v in ipairs(self.download) do
                if params.tag == v.tag then
                    table.remove(self.download,i)
                end
            end
            print(self.downloadTotal.."|"..self.downloadTotal - #self.download)
            self:setPercent(self.downloadTotal, self.downloadTotal - #self.download)

            if func then func() end
        else
            self.contentLabel:setString("Download Error!")
        end

    end,
    function(total, current)
    end, 0, param.tag)

end

function NewUpdateScene:setPercent(total, current)
    local percent
    if total <= 0 or current <= 0 then
        percent = 0
    else
        percent = current/total*100
    end
    print("logging:"..percent)
    self.progressLabel:setString( math.ceil( percent ) .. "%")
    self.loadingBar:setPercent(percent)
end

return NewUpdateScene

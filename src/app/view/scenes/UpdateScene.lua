local CURRENT_MODULE_NAME = ...

-- classes
local crypto            = import("...extra.crypto", CURRENT_MODULE_NAME)
-- singleton
local panelFactory = import("..controls.PanelFactory"):getInstance()
-- local ws            = import("...extra.NetWebSocket", CURRENT_MODULE_NAME):getInstance()
local pbBuilder     = import("...extra.ProtobufBuilder", CURRENT_MODULE_NAME):getInstance()
-- local playerMgr     = import("...data.PlayerDataManager", CURRENT_MODULE_NAME):getInstance()
local utils         = cc.FileUtils:getInstance()

local UpdateScene = class("UpdateScene", import(".SceneBase", CURRENT_MODULE_NAME))

UpdateScene.RESOURCE_FILENAME = "scenes/GameMain.csb"

function UpdateScene:onCreate()
  local layer = cc.Layer:create():addTo(self)
  -- ui
  local MARGIN = 40
  local SPACE  = 35

  local item = {
    "当前版本:",
    "服务器版本:",
    "需要更新的文件数:",
    "更新当前文件:",
    "更新文件总进度:",
    "更新当前文件进度:",
    "使用流量:",
  }
  local itemMenber = {
    "curVer",
    "serVer",
    "updateNum",
    "curFile",
    "filesProgress",
    "curProgress",
    "using",
  }

  for i,v in ipairs(item) do
    local label = cc.Label:createWithTTF(v, "fonts/STHeiti-Medium_1.ttf", 28)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(cc.p( display.size.width / 2, display.size.height - MARGIN - (SPACE * (i * 2 - 1))))
    layer:addChild(label, 0)

    label = cc.Label:createWithTTF("none", "fonts/STHeiti-Medium_1.ttf", 28)
    self[itemMenber[i]] = label
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(cc.p( display.size.width / 2, display.size.height - MARGIN - (SPACE * i * 2)))
    layer:addChild(label, 0)
  end
  self.buttonPath1 = "studio/textures/ui/talk/bd_talkB.png"
  self.buttonPath2 = "studio/textures/ui/talk/bd_talkBG.png"
  local textButton = ccui.Button:create():addTo(self)
  textButton:setTouchEnabled(false)
  textButton:setBright(false)
  textButton:setAnchorPoint(display.RIGHT_BOTTOM)
  textButton:setTitleText("［热更新］检查版本")
  textButton:setTitleFontSize(28)
  textButton:setPosition(cc.p(display.size.width, 0))
  textButton:addTouchEventListener(handler(self,self.onButton))
  textButton:loadTextures(self.buttonPath1,self.buttonPath1,self.buttonPath2)
  textButton:setTitleFontName("fonts/STHeiti-Medium_1.ttf")
  self.button = textButton

  -- 0 默认值
  -- 1 检查版本
  -- 2 进入游戏
  -- 3 下载版本内容
  self.type = 0

  -- data
  -- content/
  self.downloadPath = ContentManager:getInstance():writableContentPath() .. "zh/"
  printInfo(self.downloadPath)

  self.download = {}
  self.curfilesProgress = 0
end

function UpdateScene:onEnter()
  cc.UserDefault:getInstance():setStringForKey("version","100.10.10")
  -- 获取本地存储版本
  self.curVer:setString(cc.UserDefault:getInstance():getStringForKey("version"))

  -- 没有？第一次
  if self.curVer:getString() == "none" then
    self.curVer:setString("first play")
  end

  -- 可以检查版本了
  self.button:setTouchEnabled(true)
  self.button:setBright(true)

  self.type = 1

end

function UpdateScene:onExit()

end

--获取路径
local function stripfilename(filename)
	return string.match(filename, "(.+)/[^/]*%.%w+$") --*nix system
end

--获取文件名
local function strippath(filename)
	return string.match(filename, ".+/([^/]*%.%w+)$") -- *nix system
end

--去除扩展名
local function stripextension(filename)
	local idx = filename:match(".+()%.%w+$")
	if(idx) then
		return filename:sub(1, idx-1)
	else
		return filename
	end
end

--获取扩展名
local function getextension(filename)
	return filename:match(".+%.(%w+)$")
end

function UpdateScene:onButton(event)
  -- 相应检查版本
  if self.type == 1 then
    self:checkVersion(function(verRet)
      if verRet then
        self:checkMd5(function(mdRet)
          if mdRet then
            self.button:setTitleText("［热更新］进入游戏")
            self.button:setTouchEnabled(true)
            self.button:setBright(true)
            self.type = 2
          else
            self.button:setTitleText("［热更新］下载更新")
            self.button:setTouchEnabled(true)
            self.button:setBright(true)
            self.filesProgress:setString(self.curfilesProgress .."/".. #self.download)
            self.updateNum:setString(#self.download)
            self.type = 3
          end
        end)
      end
    end)
  elseif self.type == 2 then
    -- 响应玩游戏了
    self:getApp():enterScene("LogScene")
  elseif self.type == 3 then
    self:downloadFiles()
  end

  -- 响应一次，等再次激活，后台xxoo
  self.button:setTitleText("［热更新］更新中")
  self.button:setTouchEnabled(false)
  self.button:setBright(false)
end

function UpdateScene:checkVersion(func)

  HttpHelper.get("http://123.59.70.52:8088/resource/version", function(params)
    if params.code == 200 then
      self.serVer:setString(params.data)
      if func then func(true) end
    else
      self.serVer:setString("Server Error!")
      if func then func(false) end
    end
  end)

end

function UpdateScene:checkMd5(func)

  local function check()
    local pb = pbBuilder:loadFromFile("data/pb/game/md5.pb","tg.pb.Md5.All","md5.bin")
    local i = 1
    for _,v in pairs(pb.md5s) do
      local md5 = crypto.md5file(cc.FileUtils:getInstance():fullPathForFilename(v.path))
      -- if v.type == "src" then
      --   local params = { path = v.path, type = v.type, tag = i }
      --   i = i + 1
      --   table.insert( self.download, params )
      -- else
        if v.md5 ~= md5 then
          printInfo(cc.FileUtils:getInstance():fullPathForFilename(v.path))
          printInfo(v.type .."|" ..v.path..":"..v.md5.."~="..md5)
          local params = { path = v.path, type = v.type, tag = i }
          i = i + 1
          table.insert( self.download, params )
        else
          printInfo(cc.FileUtils:getInstance():fullPathForFilename(v.path))
          printInfo(v.type .."|" ..v.path..":"..v.md5.."======"..md5)
        end
      -- end
    end

    return (#self.download == 0)
  end

  -- split?
  -- 版本不一样，或者没有md5，下载md5，否则直接检测
  if self.curVer:getString() ~= self.serVer:getString() or
    (not utils:isFileExist("md5.bin"))
   then

    -- 准备材料
    local url = "http://123.59.70.52:8088/resource/"..self.serVer:getString().."/md5.bin"
    if not utils:isDirectoryExist(self.downloadPath.."res/") then
      utils:createDirectory(self.downloadPath.."res/")
      printInfo("mkdir")
    end

    local path = self.downloadPath .. "res/md5.bin"
    self.curFile:setString("res/md5.bin")
    self.filesProgress:setString("1/1")

    -- 下载
    local curTotal = 0
    HttpHelper.download(url, path,function(params)
      local using = tonumber( self.using:getString()) or 0
      printInfo("curTotal:"..curTotal)
      self.using:setString(string.format("%d", using + (curTotal / 1024)))
      if func then func(check()) end
    end,
    function(total, current)
      -- total, current
      self.curProgress:setString( string.format("%d", current/total*100 ).. "%")
      curTotal = total
    end)
  else
    if func then func(check()) end
  end
end

function UpdateScene:downloadFiles()
  local function go()
    if #self.download > 0 then
      local param = self.download[1]
      self.curFile:setString(self.download[1].path)
      self:downloadFile(param,go)
    else
      -- if func then func(check()) end
      printInfo("over!!!!")
      ContentManager:getInstance():addPathToFileUtils()
      self:checkMd5(function(ret)
        printInfo(ret)
        self.button:setTitleText("［热更新］开始游戏")
        self.button:setTouchEnabled(true)
        self.button:setBright(true)
        self.type = 2
      end)
      return
    end
  end

  go()
end

function UpdateScene:downloadFile(param,func)

  -- for i,v in ipairs(self.download) do
  local v = param
  -- 准备材料
  local url = "http://123.59.70.52:8088/resource/"..self.serVer:getString().."/content/zh/"..v.type.."/"..v.path

  local dir = self.downloadPath.."/"..v.type.."/"..( stripfilename(v.path) or "")
  printInfo(url)
  if not utils:isDirectoryExist(dir) then
    utils:createDirectory(dir)
    printInfo("mkdir")
  end

  local path = self.downloadPath.."/"..v.type.."/"..v.path
  printInfo(path)
  -- self.curFile:setString(v.path)
  self.filesProgress:setString(self.curfilesProgress .. "/" .. self.updateNum:getString())
  --
  -- -- 下载
  local curTotal = 0
  HttpHelper.download(url, path,function(params)
    local using = tonumber( self.using:getString()) or 0
    -- printInfo("curTotal:",curTotal/1024)
    -- printInfo("using:",using)
    printInfo(params.tag)
    self.using:setString(string.format("%d", using + (curTotal / 1024)))
    curTotal = 0
    self.curfilesProgress = self.curfilesProgress + 1
    self.filesProgress:setString(self.curfilesProgress .. "/" .. self.updateNum:getString())

    for i,v in ipairs(self.download) do
      if params.tag == v.tag then
        table.remove(self.download,i)
      end
    end

    if func then func() end
  end,
  function(total, current)
    -- total, current
    self.curProgress:setString( string.format("%d", current / total * 100 ).. "%")
    curTotal = total
  end, 0, v.tag)
-- end
end

return UpdateScene

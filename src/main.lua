
cc.FileUtils:getInstance():setPopupNotify(true)

require "config"
require "cocos.init"

require "app.Constants"
require "app.Extends"
require "app.Functions"
require "app.Strings"
require "app.extra.MessageManager"

local function main()
	local configs = {
        viewsRoot  = "app.view.scenes",
        modelsRoot = "app.models",
        defaultSceneName = "MainScene",
    }

    require("app.MyApp"):create(configs):run()
	-- audio.setMusicVolume(0)
	-- audio.setSoundsVolume(0)
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end

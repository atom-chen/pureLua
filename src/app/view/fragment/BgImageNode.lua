local CURRENT_MODULE_NAME = ...

-- classs
local AnimationNode  = import("..controls.CocostudioNode")
local infoMgr        = import("...data.information.InfoManager",CURRENT_MODULE_NAME):getInstance()
local resMgr         = import("...data.information.ResManager" ,CURRENT_MODULE_NAME):getInstance()
local ws             = import("...extra.NetWebSocket",          CURRENT_MODULE_NAME):getInstance()
local pbBuilder      = import("...extra.ProtobufBuilder",       CURRENT_MODULE_NAME):getInstance()
local playerMgr      = import("...data.PlayerDataManager",      CURRENT_MODULE_NAME):getInstance()


local BgImageNode  = class("BgImageNode", AnimationNode)


BgImageNode.csb = "nodes/bgNode.csb"

function BgImageNode.create(id)
  return BgImageNode.new({csbName = BgImageNode.csb, id = id})
end

function BgImageNode.seek(parentNode, nodeName, id)
    return BgImageNode.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        csbName    = BgImageNode.csb,
        id         = id
    })
end

function BgImageNode:ctor(params)
    BgImageNode.super.ctor(self,params)
    self:enableNodeEvents()

    for i=1,2 do
        self:mapUiElement("bgImagePanel" .. i)
    end

    self.id = params.id
    
    if self.id then
        self:refresh()
    end
end


function BgImageNode:refresh(id)

    self.id = id or self.id

    local path,plist = resMgr:getResPath(self.id)

    cc.SpriteFrameCache:getInstance():addSpriteFrames(plist)

    for i=1,2 do
        self["bgImagePanel"..i]:setTextureByPlist(string.format("%s%d.png", path, i))
    end
end


return BgImageNode

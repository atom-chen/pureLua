local CURRENT_MODULE_NAME = ...

local AnimationNode       = import("..controls.CocostudioNode")

local EffectManager = class("EffectManager",AnimationNode)

--singleton
local resManager = import("...data.information.ResManager",CURRENT_MODULE_NAME):getInstance()


function EffectManager.createWithId( id )
	return EffectManager.new({csbName = resManager:getResPath(id),id = id})
end

-- --need add 
function EffectManager:ctor(params)
	EffectManager.super.ctor(self, params)
	self:enableNodeEvents()

	self.id = params.id

	-- local info = resManager:findInfo(params.id)
	-- dump(info)
end



function EffectManager:destroy()
	self:removeFromParent()
end


function EffectManager:onEnter()
	-- body
end


return EffectManager

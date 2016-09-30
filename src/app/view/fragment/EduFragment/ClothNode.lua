local CURRENT_MODULE_NAME = ...
local AnimationNode    = import("...controls.CocostudioNode")
--
local infoMgr 	= import("....data.information.InfoManager"):getInstance()
local resMgr 	= import("....data.information.ResManager"):getInstance()

local ClothNode = class("ClothNode",AnimationNode)

ClothNode.csb 	= "nodes/edu/cloth.csb"

function ClothNode.create()
	local params = {}
	params.csbName = ClothNode.csb
	return ClothNode.new(params)

end

function ClothNode.seek(parentNode,nodeName)
    return ClothNode.new({
        parentNode = parentNode,
        nodeName   = nodeName,
        csbName    = ClothNode.csb
    })
end

function ClothNode:ctor(params)

	ClothNode.super.ctor(self,params)
    self:enableNodeEvents()
    self:mapUiElements({"clothAvatar","clothName","clothStatus","price","buyState"})

    dump(params)

end


function ClothNode:refresh(params)

	print("ClothNode:refresh")
	dump(params)
	self.params = params
	self.pb  = infoMgr:findInfo("fashions","class_id",params.class_id)
    dump(self.pb)
    self.mode = params.mode
    self.state = params.state
	if self.pb.resId~=0 then
		self.clothAvatar:setTexture(resMgr:getResPath(self.pb.resId))
	else
		self.clothAvatar:setTexture(resMgr:getIconPath(resMgr.IconType.SOUL_CLOTH,self.pb.soulId,self.pb.class_id))
	end
    self.clothName:setString(self.pb.name)
    self.price:setString(""..self.pb.price)
	-- 1 正常
	-- 2 穿着的
	-- 3 new
	-- 4 已购买
	--[[[
	mode:1 试衣ＵＩ：
	1. 正常(没穿)
	2. 穿着的

	mode:2 商店ＵＩ：
	1. 正常(在卖) -- sell
	4. 已购买 -- yigou
	--]]
	print("cloth state:"..self.state)
	if self.mode == 1 then
		if self.state == 1 or self.state == 3 then
			self:runAnimation("normal")
			if self.state == 3 then
				self.clothStatus:show()
			else
				self.clothStatus:hide()
			end
		elseif self.state == 2 then
			self:runAnimation("yigou")  --穿着的（用已购代替）
			self.buyState:setVisible(false) --已购隐藏
		end

	elseif self.mode == 2 then
		if self.state == 1 then
			self:runAnimation("sell") --正常（在卖）
			if self.state == 3 then
				self.clothStatus:show()
			else
				self.clothStatus:hide()
			end
		elseif self.state == 4 then
			self:runAnimation("yigou")
		end
	end

end

function ClothNode:onEnter()



end


return ClothNode